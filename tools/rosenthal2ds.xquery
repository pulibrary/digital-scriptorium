xquery version "3.1";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace saxon="http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare boundary-space strip;
import module namespace functx = "http://www.functx.com" at "https://www.datypic.com/xq/functx-1.0.1-doc.xq";
declare option saxon:output "omit-xml-declaration=yes";
declare option output:method "text";
declare option output:item-separator "";


(:
README
This is a custom transformation for ICU.SPCL.ROSENTHALMSS.xml

The DTD for this EAD is not reachable, and the document is not valid against ead.xsd.

Field-specific notes: 
- dated: since these are notarial documents, this can be determined
- Phillips # is in note
- link to inst. record = link to db
- language strings delimited with ";"
- there is at least one invalid date, possibly more: 15160-04
- unittitle is the same as shelfmark; propose a concatenation of data elements
- mind the typos
- genre is hardcoded
- former owner -- note says the first 2,452 mss were owned by Phillipps, should I go by that? 216 have a ph.no. total is 2,454:)

declare function local:format-for-csv($input) {
  for $i in $input
  return normalize-space('"' || replace($i, '"', '""') || '"')
};

declare variable $ead as document-node()+ := doc("path/to/input-file.xml");
let $manuscripts := $ead//c01
let $csv := 
<csv>{
	('"Row Index","DS ID","Date Updated by Contributor","Source Type","Cataloging Convention","Holding Institution","Holding Institution Identifier","Shelfmark","Fragment Number or Disambiguator","Link to Institutional Record","IIIF Manifest","Production Place(s)","Date Description","Production Date START","Production Date END","Dated","Title(s)","*Uniform Title(s)","Genre/Form","Subject(s)","Author Name(s)","Artist Name(s)","Scribe Name(s)","Named Subject(s)","Former Owner Name(s)","Language(s)","Materials Description","Extent","Dimensions","Layout","Script","Decoration","Binding","Physical Description Miscellaneous","Provenance Notes","Note 1","Note 2","Acknowledgements"') || codepoints-to-string(10),
	for $mss at $index in $manuscripts
	let $row := string($index + 1)
(:helpers:)
(:with brute-force removal of zero-length leading spaces:)
	let $about := substring(tokenize($mss/did/note/list/item[matches(., '^subject:\s?', 'i')], ":")[2], 2)
	let $party1 := substring(tokenize($mss/did/note/list/item[matches(., '^first party:\s?', 'i')], ":")[2], 2)
	let $party2 := substring(tokenize($mss/did/note/list/item[matches(., '^second party:\s?', 'i')], ":")[2], 2)
	let $place-about := substring(tokenize($mss/did/note/list/item[matches(., '^place about:\s?', 'i')], ":")[2], 2)
	let $place-where := substring(tokenize($mss/did/note/list/item[matches(., '^place where:\s?', 'i')], ":")[2], 2)
	let $type := substring(tokenize($mss/did/note/list/item[matches(., '^type:\s?', 'i')], ":")[2], 2)
	let $appendix := normalize-space($mss/did/note/list/item[matches(., '^appendix:\s?', 'i')])
	let $phillips := normalize-space($mss/did/note/list/item[matches(., '^phillips no\.:\s?', 'i')])
(:end helpers :)
	let $ds_id := ""
	let $date_last_updated := ""
	let $source_type := "ead-xml"
	let $cataloging-convention := ""
	let $holding_institution_as_recorded := "University of Chicago Library"
	let $holding_institution_id_number := ""
	let $holding_institution_shelfmark := $mss/did/unittitle/text()
	let $link_to_holding_institution_record := $mss/ancestor::archdesc/descgrp[1]/scopecontent[1]/p[17]/extref[1]/data(@href)
	let $iiif_manifest := ""
	let $geogname := 
		if ($mss/ancestor::archdesc/descgrp/controlaccess/geogname)
		then $mss/ancestor::archdesc/descgrp/controlaccess/geogname[1]/text()
		else ""
	let $genre_as_recorded := 
		if ($mss/ancestor::archdesc/descgrp/controlaccess/genreform)
		then $mss/ancestor::archdesc/descgrp/controlaccess/genreform[1]/text()
		else ""
	let $production_place_as_recorded := 
		if ($place-where[not(.='')])
		then $place-where
		else " "
	let $production_date_as_recorded := substring(tokenize($mss/did/note/list/item[matches(., '^date:\s?', 'i')], ":")[2], 2)
	let $production_date_start := replace($production_date_as_recorded, '^(([\w\s-]+)?(\d{4})(-\d{1,2}-\d{1,2})?)(-)(\d{4}(-\d{1,2}-\d{1,2})?)?$', '$1')
	let $production_date_end := replace($production_date_as_recorded, '^(([\w\s-]+)?(\d{4})(-\d{1,2}-\d{1,2})?)(-)(\d{4}(-\d{1,2}-\d{1,2})?)?$', '$6')
	let $dated :=
		if ($production_date_as_recorded[not(.='')])
		then
			"TRUE"
		else
			"FALSE"
	let $title_as_recorded := 
		$type || ': ' || 
		(if (matches($about, '\s?--?\s?cf\.')) then replace($about, '\s?--?\s?cf\..+', '') else $about) || 
		(
			if ($party1[not(.="")] or $party2[not(.="")]) 
			then ' (' || (
				if ($party1[not(.="")]) 
				then 
					if ($party2[not(.="")])
					then $party1 || '/' || $party2 || ')'
					else $party1 || ')'
				else if ($party2[not(.="")]) 
				then $party2 || ')'
				else "" )
			else "")
(:	$mss/did/unittitle/text():)
	let $uniform_title_as_recorded := ""
	let $subject_as_recorded :=
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/*[not(self::genreform[1]) and not(self::head)]/text(), '|')
		else string-join($mss/ancestor::archdesc/descgrp/controlaccess/*[not(self::genreform[1]) and not(self::head)]/text(), '|')
	let $author_as_recorded := ""
	let $artist_as_recorded := ""
	let $scribe_as_recorded := ""
	let $associated_agent_as_recorded := 
		if ($party2[not(.="")])
		then 
			if ($party1[not(.="")])
			then $party1 || "|" || $party2
			else $party2
		else $party1
	let $former_owner_as_recorded := 
		if ($phillips[not(.='')])
		then "Sir Thomas Phillipps (1792-1872)"
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
			if ($mss/ancestor::archdesc/did/langmaterial/language[@langcode])
			then string-join(
				for $language in $mss/ancestor::archdesc/did/langmaterial/language
				return string-join($language/text() || "|" || $language/@langcode),
				";")
			else string-join($mss/ancestor::archdesc/did/langmaterial/language, ";")
	let $material_as_recorded := ""
	let $physical_description_misc := ""
	let $note_1 := 
		if ($type[not(.='')] or $appendix[not(.='')] or $phillips[not(.='')])
		then 
			let $seq := ($type[not(.='')], $appendix[not(.='')], $phillips[not(.='')])
			return
				string-join($seq, "|")
		else ""
	let $acknowledgments := 
		if ($mss/acqinfo)
		then (string-join($mss/acqinfo/p, "|"))
		else 
			if ($mss//ancestor::ead/eadheader//sponsor)
			then $mss//ancestor::ead/eadheader//sponsor/text()
			else ""
	let $data_source_modified := ""
	let $layout := ""
	let $script := ""
	let $decoration := ""
	let $binding := ""
	let $provenance := ""
	let $disambiguator := ""
	let $note_2 := 
		if ($mss/scopecontent)
		then normalize-space($mss/scopecontent)
		else
		substring(normalize-space(string-join($mss/ancestor::archdesc/descgrp/scopecontent/*[not(self::head)]/text(), '|')), 1, 380) || (if ($mss/ancestor::archdesc/descgrp/scopecontent/*[not(self::head)]/string-length(.)>380) then "...[text truncated]" else ())
	let $dimensions := ""
	let $extent := ""
	
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
return put($csv, "rosenthal2ds.csv")
