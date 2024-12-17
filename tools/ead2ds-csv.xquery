xquery version "3.0";
declare default element namespace "urn:isbn:1-931666-22-9";
declare namespace xlink = "http://www.w3.org/1999/xlink";
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";
declare option saxon:output "omit-xml-declaration=yes";

(:
general approach:
1. format for ASpace EAD2002 output
2. extract lowest descriptive nesting level
3. for data elements, check self node, then iterate up
4. concatenate notes where appropriate/necessary
5. map shelfmark to unitid; if no unitid, look for item number, then container concatenation
:)


declare variable $ead as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/C0776_20241216_214730_UTC__ead.xml");
let $manuscripts := $ead//c[@level = "item"]
for $mss in $manuscripts
let $ds_id := ""
let $date_added := current-date()
let $date_last_updated := ""
let $source_type := "ead-xml"
(:hardcoding this because descrules is discursive, does that fly?:)
let $cataloging-convention := "dacs"
let $holding_institution_ds_qid := ""
let $holding_institution_as_recorded := $mss/ancestor::archdesc/did/origination/corpname[@role = "col"]/text()
(:logic: check for a unitid that's not the aspace uri, else take the component id:)
let $holding_institution_id_number := if ($mss/did/unitid[not(@type = "aspace_uri")][count(.) = 1])
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
let $link_to_holding_institution_record := $mss/ancestor::ead//eadid/data(@url)
let $iiif_manifest :=
if (matches($mss/did/dao/@xlink:href, "manifest"))
then
	$mss/did/dao/data(@xlink:href)
else
	""
	(:production place and date may be hard to extract as they'd most likely be subdivisions on a genreform term:)
	(:trying my luck here with the first genreterm, if any:)
let $genreterm-prod := $mss/ancestor::archdesc/controlaccess/genreform[1]/text()
let $production_place_as_recorded := tokenize($genreterm-prod, '--')[2]
let $production_place_ds_qid := ""
let $production_date_as_recorded :=
for $token at $pos in tokenize($genreterm-prod, '--')
	where (matches($token, "^\d") or matches($token, "cent")) and $pos > 1
return
	$token
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
let $genre_as_recorded := tokenize($genreterm-prod, '--')[1]
let $genre_ds_qid := ""
(:should we exclude genreform here?:)
let $subjects :=
if ($mss/controlaccess)
then string-join($mss/controlaccess/*/text(), '|')
else string-join($mss/ancestor::archdesc/controlaccess/*/text(), '|')
		(:would we ever expect a corpname here, e.g. a workshop?:)
		(:also: assuming marc relator codes, is that sound?:)
let $author_as_recorded :=
if ($mss/did/origination)
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
if ($mss/did/origination)
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
if ($mss/did/origination)
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
if ($mss/did/origination)
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
if ($mss/did/origination)
then
	for $name in $mss/did/origination/persname[matches(@role, "fmo")]
	return
		$name/text()
else
	""
let $former_owner_as_recorded_agr := ""
let $former_owner_ds_qid := ""
(:we have a choice to grab the string value instead:)
let $language_as_recorded := string-join($mss/did/langmaterial/language/@langcode, ', ')
let $language_ds_qid := ""
(:could use sample data other than PUL's here; not sure where this could be recorded in structured form, if anywhere (we have it in a note):)
let $material_as_recorded := ""
let $material_ds_qid := ""
let $physical_description := normalize-space($mss/did/physdesc/extent/text()) || normalize-space($mss/did/physdesc/dimensions/text()) || normalize-space($mss/did/physdesc/physfacet/text())
let $note := normalize-space($mss/scopecontent)
(:this field only exists in the titlestmt of the collection-level record:)
let $acknowledgments := $mss/ancestor::ead/eadheader//sponsor/text()
let $data_processed_at := current-dateTime()
(:not sure what goes here:)
let $data_source_modified := ""
let $source_file := base-uri($ead)

return
	normalize-space(
	$ds_id || "	" ||
	$date_added || "	" ||
	$date_last_updated || "	" ||
	$source_type || "	" ||
	$cataloging-convention || "	" ||
	$holding_institution_ds_qid || "	" ||
	$holding_institution_as_recorded || "	" ||
	$holding_institution_id_number ||"	"||
$holding_institution_shelfmark ||"	"||
$link_to_holding_institution_record ||"	"||
$iiif_manifest ||"	"||
$production_place_as_recorded ||"	"||
$production_place_ds_qid ||"	"||
$production_date_as_recorded ||"	"||
$production_date ||"	"||
$century ||"	"||
$century_aat ||"	"||
$dated ||"	"||
$title_as_recorded ||"	"||
$title_as_recorded_agr ||"	"||
$uniform_title_as_recorded ||"	"||
$uniform_title_agr ||"	"||
$standard_title_ds_qid ||"	"||
$genre_as_recorded ||"	"||
$genre_ds_qid ||"	"||
$subjects ||"	"||
$author_as_recorded ||"	"||
$author_as_recorded_agr ||"	"||
$author_ds_qid ||"	"||
$artist_as_recorded ||"	"||
$artist_as_recorded_agr ||"	"||
$artist_ds_qid ||"	"||
$scribe_as_recorded ||"	"||
$scribe_as_recorded_agr ||"	"||
$scribe_ds_qid ||"	"||
$associated_agent_as_recorded ||"	"||
$associated_agent_as_recorded_agr ||"	"||
$associated_agent_ds_qid ||"	"||
$former_owner_as_recorded ||"	"||
$former_owner_as_recorded_agr ||"	"||
$former_owner_ds_qid ||"	"||
$language_as_recorded ||"	"||
$language_ds_qid ||"	"||
$material_as_recorded ||"	"||
$material_ds_qid ||"	"||
$physical_description ||"	"||
$note ||"	"||
$acknowledgments ||"	"||
$data_processed_at ||"	"||
$data_source_modified ||"	"||
$source_file) || codepoints-to-string(10)
