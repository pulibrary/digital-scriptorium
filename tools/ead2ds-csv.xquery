xquery version "3.0";
declare default element namespace "urn:isbn:1-931666-22-9";
declare namespace xlink = "http://www.w3.org/1999/xlink";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";
declare option saxon:output "omit-xml-declaration=yes";

(:
README
1. this transformation assumes ASpace data serialized as EAD2002
2. it extracts records for each component with the level set to "item"
3. it assumes use of marc relator codes
4. for ID, it looks for a unitid (that is not the aspace url) or, alternatively, the component id or, alternatively, the call# + index of the component
5. for shelfmark, it assumes a single container and concatenates the container label (which contains the container barcode), type, and indicator
7. for genre, it looks for the first subfield of the first genreform term
8. for production date, it looks for a subfield of the first genreform term containing numbers or the string "cent"
9. for production place, it looks for the second of two subfields of the first genreterm (<<this is dicey)
10. material is in a note and can't typically be extracted
11. physical description concatenates the subfields of physdesc and phystech
12. note maps to the scopecontent note
:)

declare function local:format-for-csv($input) {
  for $i in $input
  return fn:escape-html-uri('"' || replace(string($i), '"', '""') || '"')
};

declare variable $ead as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/C0776_20241216_214730_UTC__ead.xml");
let $manuscripts := $ead//c[@level = "item"]
let $csv := 
<csv>{
	for $mss in $manuscripts
	let $ds_id := ""
	let $date_added := current-date()
	let $date_last_updated := ""
	let $source_type := "ead-xml"
	(:hardcoding this because descrules is discursive, does that fly?:)
	let $cataloging-convention := "dacs"
	let $holding_institution_ds_qid := ""
	let $holding_institution_as_recorded := 
		if ($mss/ancestor::archdesc/did/origination/corpname[@role = "col"])
		then $mss/ancestor::archdesc/did/origination/corpname[@role = "col"]/text()
		else ""
	(:logic: check for a unitid that's not the aspace uri, else take the component id:)
	let $holding_institution_id_number := 
		if ($mss/did/unitid[not(@type = "aspace_uri")][count(.) = 1])
		then
			$mss/did/unitid[not(@type = "aspace_uri")]/text()
		else
			if ($mss/did/unitid[not(@type = "aspace_uri")][count(.) > 1])
			then
				error(xs:QName('local:unitid_conflict'), "more than one unitid associated with this item, please pick one")
			else
				if ($mss/@id)
				then
					$mss/data(@id)
				else
					$mss/ancestor::ead//eadid/text() || "_" || functx:index-of-node($mss/ancestor::dsc//c[@level = "item"], $mss)
	let $holding_institution_shelfmark :=
		if ($mss/did/container)
		then
			(for $container in $mss/did/container[1]
			return
				($container/@label || "_" || $container/@type || "_" || $container/text()))
		else
			""
	let $link_to_holding_institution_record := 
		if ($mss/ancestor::ead//eadid/@url)
		then $mss/ancestor::ead//eadid/data(@url)
		else ""
	let $iiif_manifest :=
		if (matches($mss/did/dao/@xlink:href, "manifest"))
		then
			$mss/did/dao/data(@xlink:href)
		else
			""
		(:production place and date may be hard to extract as they'd most likely be subdivisions on a genreform term:)
		(:trying my luck here with the first genreterm, if any:)
	let $genreterm-prod := 
		if ($mss/ancestor::archdesc/controlaccess/genreform)
		then $mss/ancestor::archdesc/controlaccess/genreform[1]/text()
		else ""
	let $production_place_as_recorded := 
		if ($genreterm-prod)
		then tokenize($genreterm-prod, '--')[2]
		else ""
	let $production_place_ds_qid := ""
	let $production_date_as_recorded :=
		if ($genreterm-prod)
		then
			for $token at $pos in tokenize($genreterm-prod, '--')
				where (matches($token, "^\d") or matches($token, "cent")) and $pos > 1
			return
				$token
		else ""
	let $production_date := ""
	let $century := ""
	let $century_aat := ""
	let $dated :=
		if ($production_date_as_recorded = "")
		then
			"FALSE"
		else
			"TRUE"
	let $title_as_recorded := $mss/did/unittitle/text()
	let $title_as_recorded_agr := ""
	let $uniform_title_as_recorded := ""
	let $uniform_title_agr := ""
	let $standard_title_ds_qid := ""
	let $genre_as_recorded := 
		if ($genreterm-prod)
		then tokenize($genreterm-prod, '--')[1]
		else ""
	let $genre_ds_qid := ""
	(:should we exclude genreform here?:)
	let $subject_as_recorded :=
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/*/text(), '|')
		else string-join($mss/ancestor::archdesc/controlaccess/*/text(), '|')
	(:would we ever expect a corpname here, e.g. a workshop?:)
	(:also: assuming marc relator codes, is that sound?:)
	let $subject_ds_qid := ""
	let $author_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "cre")])
		then
			for $name in $mss/did/origination/persname[matches(@role, "cre")]
			return
				$name/text()
		else
			""
	let $author_as_recorded_agr := ""
	let $author_ds_qid := ""
	(:assuming marc relator codes, is that sound?:)
	let $artist_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "art|ill|ilu")])
		then
			for $name in $mss/did/origination/persname[matches(@role, "art|ill|ilu")]
			return
				$name/text()
		else
			""
	let $artist_as_recorded_agr := ""
	let $artist_ds_qid := ""
	(:assuming marc relator codes, is that sound?:)
	let $scribe_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "scr")])
		then
			for $name in $mss/did/origination/persname[matches(@role, "scr")]
			return
				$name/text()
		else
			""
	let $scribe_as_recorded_agr := ""
	let $scribe_ds_qid := ""
	(:assuming marc relator codes, is that sound?:)
	let $associated_agent_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "asn")])
		then
			for $name in $mss/did/origination/persname[matches(@role, "asn")]
			return
				$name/text()
		else
			""
	let $associated_agent_as_recorded_agr := ""
	let $associated_agent_ds_qid := ""
	(:assuming marc relator codes, is that sound?:)
	let $former_owner_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "fmo")])
		then
			for $name in $mss/did/origination/persname[matches(@role, "fmo")]
			return
				$name/text()
		else
			""
	let $former_owner_as_recorded_agr := ""
	let $former_owner_ds_qid := ""
	(:we have a choice to grab the string value instead:)
	let $language_as_recorded := 
		if ($mss/did/langmaterial/language/@langcode)
		then string-join($mss/did/langmaterial/language/@langcode, ', ')
		else ""
	let $language_ds_qid := ""
	(:could use sample data other than PUL's here; not sure where this could be recorded in structured form, if anywhere (we have it in a note):)
	let $material_as_recorded := ""
	let $material_ds_qid := ""
	let $physical_description := 
		if ($mss/did/physdesc/*)
		then normalize-space($mss/did/physdesc/extent/text()) || normalize-space($mss/did/physdesc/dimensions/text()) || normalize-space($mss/did/physdesc/physfacet/text())
		else ""
	let $note := 
		if ($mss/scopecontent)
		then normalize-space(string-join($mss/scopecontent/*[not(self::head)]/text(), ' '))
		else ""
	(:this field only exists in the titlestmt of the collection-level record:)
	let $acknowledgments := 
		if ($mss//ancestor::ead/eadheader//sponsor)
		then $mss/ancestor::ead/eadheader//sponsor/text()
		else ""
	let $data_processed_at := current-dateTime()
	(:not sure what goes here:)
	let $data_source_modified := ""
	let $source_file := base-uri($ead)
	
	return
	(
	string-join(local:format-for-csv((
		$ds_id,
		$date_added,
		$date_last_updated,
		$source_type,
		$cataloging-convention,
		$holding_institution_ds_qid,
		$holding_institution_as_recorded,
		$holding_institution_id_number,
		$holding_institution_shelfmark,
		$link_to_holding_institution_record,
		$iiif_manifest,
		$production_place_as_recorded,
		$production_place_ds_qid,
		$production_date_as_recorded,
		$production_date,
		$century,
		$century_aat,
		$dated,
		$title_as_recorded,
		$title_as_recorded_agr,
		$uniform_title_as_recorded,
		$uniform_title_agr,
		$standard_title_ds_qid,
		$genre_as_recorded,
		$genre_ds_qid,
		$subject_as_recorded,
		$subject_ds_qid,
		$author_as_recorded,
		$author_as_recorded_agr,
		$author_ds_qid,
		$artist_as_recorded,
		$artist_as_recorded_agr,
		$artist_ds_qid,
		$scribe_as_recorded,
		$scribe_as_recorded_agr,
		$scribe_ds_qid,
		$associated_agent_as_recorded,
		$associated_agent_as_recorded_agr,
		$associated_agent_ds_qid,
		$former_owner_as_recorded,
		$former_owner_as_recorded_agr,
		$former_owner_ds_qid,
		$language_as_recorded,
		$language_ds_qid,
		$material_as_recorded,
		$material_ds_qid,
		$physical_description,
		$note,
		$acknowledgments,
		$data_processed_at,
		$data_source_modified,
		$source_file)), ",") || codepoints-to-string(10)
	)
}</csv>

let $csv := document{$csv/text()}
return
(
put($csv, "csv2ds.csv")
)
