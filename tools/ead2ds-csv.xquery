xquery version "3.1";
declare default element namespace "urn:isbn:1-931666-22-9";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace saxon="http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare boundary-space strip;
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";
declare option saxon:output "omit-xml-declaration=yes";
declare option output:method "text";
declare option output:item-separator "";


declare function local:format-for-csv($input) {
  for $i in $input
  return normalize-space('"' || replace($i, '"', '""') || '"')
};

declare variable $ead as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/ead2csv/C0776_20241216_214730_UTC__ead.xml");
let $manuscripts := $ead//c[@level = "item"]
let $csv := 
<csv>{
	('"Row Index","DS ID","Date Updated by Contributor","Source Type","Cataloging Convention","Holding Institution","Holding Institution Identifier","Shelfmark","Fragment Number or Disambiguator","Link to Institutional Record","IIIF Manifest","Production Place(s)","Date Description","Production Date START","Production Date END","Dated","Title(s)","*Uniform Title(s)","Genre/Form","Subject(s)","Author Name(s)","Artist Name(s)","Scribe Name(s)","Named Subject(s)","Former Owner Name(s)","Language(s)","Materials Description","Extent","Dimensions","Layout","Script","Decoration","Binding","Physical Description Miscellaneous","Provenance Notes","Note 1","Note 2","Acknowledgements"') || codepoints-to-string(10),
	for $mss at $index in $manuscripts
	let $row := string($index + 1)
	let $ds_id := ""
	let $date_added := string(current-date())
	let $date_last_updated := ""
	let $source_type := "ead-xml"
	(:hardcoding this because descrules is discursive, so this may not always be true? :)
	let $cataloging-convention := "dacs"
	let $holding_institution_as_recorded := "Princeton University"
	let $holding_institution_id_number := $mss/data(@id)
	let $holding_institution_shelfmark := tokenize($mss/did/unittitle/text(), ":")[1]
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
	let $geogname := 
		if ($mss/ancestor::archdesc/controlaccess/geogname)
		then $mss/ancestor::archdesc/controlaccess/geogname[1]/text()
		else ""
	let $genre_as_recorded := 
		if ($mss/ancestor::archdesc/controlaccess/genreform)
		then $mss/ancestor::archdesc/controlaccess/genreform[1]/text()
		else ""
	let $production_place_as_recorded := 
		if ($geogname)
		then tokenize($geogname, '--')[1]
		else 
			if ($genre_as_recorded)
			then tokenize($genre_as_recorded, '--')[2]
			else ""
	let $production_date_as_recorded := $mss/did/unitdate/text()
	let $production_date := 
		tokenize($mss/did/unitdate/@normal, "/")
	let $production_date_start :=
		if ($production_date[1])
		then $production_date[1]
		else ""
	let $production_date_end :=
		if ($production_date[2])
		then $production_date[2]
		else ""
	let $dated :=
		if ($production_date_as_recorded = "")
		then
			"FALSE"
		else
			""
	let $title_as_recorded := 
(:for the condition, check only the direct child of current:)
		if ($mss/c[@level="otherlevel"])
		then
			$mss/did/unittitle/text() || "|" ||
(:for the execution, check all descendants:)
			string-join($mss//c[@level="otherlevel"]/did/unittitle/text(), "|")		
		else $mss/did/unittitle/text()
	let $uniform_title_as_recorded := ""
	let $subject_as_recorded :=
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/*[not(self::genreform[1])]/text(), '|')
		else string-join($mss/ancestor::archdesc/controlaccess/*[not(self::genreform[1])]/text(), '|')
	let $author_as_recorded :=
		if ($mss/did/origination/persname[matches(@role, "cre")])
		then string-join($mss/did/origination/persname[matches(@role, "cre")], "|")
		else
			if ($mss/ancestor::archdesc/did/origination/persname[matches(@role, "cre")])
			then string-join($mss/ancestor::archdesc/did/origination/persname[matches(@role, "cre")], "|")
			else ""
	let $artist_as_recorded :=
		if ($mss/did/origination/*[matches(@role, "art|ill|ilu")])
		then string-join($mss/did/origination/*[matches(@role, "art|ill|ilu")], "|")
		else
			if ($mss/ancestor::archdesc/did/origination/*[matches(@role, "art|ill|ilu")])
			then string-join($mss/ancestor::archdesc/did/origination/*[matches(@role, "art|ill|ilu")], "|")
			else ""
	let $scribe_as_recorded :=
		if ($mss/did/origination/*[matches(@role, "scr")])
		then string-join($mss/did/origination/*[matches(@role, "scr")], "|")
		else
			if ($mss/ancestor::archdesc/did/origination/*[matches(@role, "scr")])
			then string-join($mss/ancestor::archdesc/did/origination/*[matches(@role, "scr")], "|")
			else ""
	let $associated_agent_as_recorded :=
		if ($mss/did/origination/*[matches(@role, "asn")] | $mss/controlaccess/(persname|famname|corpname))
		then string-join(($mss/did/origination/*[matches(@role, "asn")] | $mss/controlaccess/(persname|famname|corpname)), "|")
		else
			if ($mss/ancestor::archdesc/did/origination/*[matches(@role, "asn")]  | $mss/controlaccess/(persname|famname|corpname))
			then string-join(($mss/ancestor::archdesc/did/origination/*[matches(@role, "asn")] | $mss/controlaccess/(persname|famname|corpname)), "|")
			else ""
	let $former_owner_as_recorded :=
		if ($mss/did/origination/*[matches(@role, "fmo")])
		then string-join($mss/did/origination/*[matches(@role, "fmo")], "|")
		else
			if ($mss/ancestor::archdesc/did/origination/*[matches(@role, "fmo")])
			then string-join($mss/ancestor::archdesc/did/origination/*[matches(@role, "fmo")], "|")
			else ""
	let $language_as_recorded := 
		if ($mss/did/langmaterial/language)
		then 
			if ($mss/did/langmaterial/language[@langcode])
			then string-join(
				for $language in $mss/did/langmaterial/language
				return string-join($language/text() || "|" || $language/@langcode),
				";")
			else string-join($mss/did/langmaterial/language/text(), ";")
		else
			if ($mss/ancestor::archdesc/did/langmaterial/language)
			then 
				if ($mss/ancestor::archdesc/did/langmaterial/language[@langcode])
				then string-join(
					for $language in $mss/ancestor::archdesc/did/langmaterial/language
					return string-join($language/text() || "|" || $language/@langcode),
					";")
				else string-join($mss/ancestor::archdesc/did/langmaterial/text(), ";")
			else ""
	let $material_as_recorded := ""
	let $physical_description_misc := 
		if (not($mss/did/physdesc/*))
		then
			(substring($mss/did/physdesc/text(), 1, 380) || (if (string-length($mss/did/physdesc/text())>380) then "...[text truncated]" else ()))
		else 
			if ($mss/did/physdesc/*[not(name()="dimensions") and not(name()="extent")])
			then 
				(substring($mss/did/physdesc/*[not(name()="dimensions") and not(name()="extent")], 1, 380) || (if (string-length($mss/did/physdesc/*[not(name()="dimensions") and not(name()="extent")]/text())>380) then "...[text truncated]" else ()))
			else ""
	let $dimensions := 
		if ($mss/did/physdesc/dimensions)
		then $mss/did/physdesc/dimensions
		else ""
	let $extent := 
		if ($mss/did/physdesc/extent)
		then $mss/did/physdesc/extent
		else ""
	let $note_1 := 
		if ($mss/scopecontent)
		then substring(normalize-space(string-join($mss/scopecontent/*[not(self::head)]/text(), '|')), 1, 380) || (if ($mss/scopecontent/*[not(self::head)]/string-length(.)>380) then "...[text truncated]" else ())
		else ""
	let $acknowledgments := 
		if ($mss/acqinfo)
		then (string-join($mss/acqinfo/p, "|"))
		else 
			if ($mss//ancestor::ead/eadheader//sponsor)
			then $mss//ancestor::ead/eadheader//sponsor/text()
			else ""
	let $layout := ""
	let $script := ""
	let $decoration := ""
	let $binding := ""
	let $provenance := ""
	let $disambiguator := ""
	let $note_2 := ""
	
	return
(:use the text constructor here because otherwise saxon separates concatenated atomic values with a space:)
	(text{
	string-join(
		local:format-for-csv(
			(
			$row,
			$ds_id,
			$date_last_updated,
			$source_type,
			$cataloging-convention,
			$holding_institution_as_recorded,
			$holding_institution_id_number,
			$holding_institution_shelfmark,
			$disambiguator,
			$link_to_holding_institution_record,
			$iiif_manifest,
			$production_place_as_recorded,
			$production_date_as_recorded,
			$production_date_start,
			$production_date_end,
			$dated,
			$title_as_recorded,
			$uniform_title_as_recorded,
			$genre_as_recorded,
			$subject_as_recorded,
			$author_as_recorded,
			$artist_as_recorded,
			$scribe_as_recorded,
			$associated_agent_as_recorded,
			$former_owner_as_recorded,
			$language_as_recorded,
			$material_as_recorded,
			$extent,
			$dimensions,
			$layout,
			$script,
			$decoration,
			$binding,
			$physical_description_misc,
			$provenance,
			$note_1,
			$note_2,
			$acknowledgments)), ",")}, text{codepoints-to-string(10)})
}</csv>

let $csv := document{$csv/text()}
return put($csv, "ead2ds.csv")
