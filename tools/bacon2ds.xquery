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
This is a custom transformation for ICU.SPCL.BACON.xml

The DTD for this EAD is not reachable, and the document is not valid against ead.xsd.

Field-specific notes: 

- This EAD uses numbered c's. There are 3 c01's, 46 c02's, 3287 c03's, 1382 c04's, no c05's
- The mss objects are described in the c03/c04's, the parents are series headers
- ID = container type=MS
- daogrp has no manifests
- All the information is in the unittitle
- beware of hard line breaks throughout

- data quality issues, e.g. Circa' 11-12 Elizabeth(Charge of the Receiver)+B1602, 1569-1573 circa (Membranes: )

Series I: Manorial Records
Series II: Manuscripts
	- Regnal Date; 
	- 1. First party 
	- 2. Second party 
	- [other parties may follow]; 
	- Places and Subject of Transaction (Field names are indicated by "X"); 
	- Consideration; Description of Instrument; 
	- Endorsements [only given occasionally in this calendar] 
	- (Language, Material, and Remarks)
	- Date [interpolated]
	- Seals: When a document in Series II bears seals or seal tags, this
					is indicated in by a notation, such as 1*3. The first number
					denotes the number of seals, the second the number of tags.
					The symbol f*1 indicates that a fragment of a seal is
					attached to the manuscript; s*1 means that it has been slit
					for a seal but no tag is attached.
:)
declare function local:format-for-csv($input) {
  for $i in $input
  return normalize-space('"' || replace($i, '"', '""') || '"')
};

declare variable $ead as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/ead2csv/20241217-chicago-ead-test/ICU.SPCL.BACON.xml");
let $manuscripts := ($ead//c03[not(c04)] | $ead//c04)
let $csv := 
<csv>{
	('"Row Index","DS ID","Date Updated by Contributor","Source Type","Cataloging Convention","Holding Institution","Holding Institution Identifier","Shelfmark","Fragment Number or Disambiguator","Link to Institutional Record","IIIF Manifest","Production Place(s)","Date Description","Production Date START","Production Date END","Dated","Title(s)","*Uniform Title(s)","Genre/Form","Subject(s)","Author Name(s)","Artist Name(s)","Scribe Name(s)","Named Subject(s)","Former Owner Name(s)","Language(s)","Materials Description","Extent","Dimensions","Layout","Script","Decoration","Binding","Physical Description Miscellaneous","Provenance Notes","Note 1","Note 2","Acknowledgements"') || codepoints-to-string(10),
	for $mss at $index in $manuscripts
	let $row := string($index + 1)
(:helpers:)
	let $unittitle := normalize-space($mss/did/unittitle)
	let $provenance-string := normalize-space(
					"With the approach of the law of Property Act of 1924, the
					Holt-Wilson family, descendants of Sir John Holt, placed the
					above described manuscripts for sale with Bernard Quaritch,
					Ltd., the London book-seller. The collection was listed in
					Quaritch catalogue No. 380 (December, 1923) as lots 213 and
					214. A list made by the antiquary Edmund Farrer formed the
					basis for the description in the catalogue. Professor C. R.
					Baskerville of the University of Chicago English Department
					persuaded the University to acquire the collection and
					Martin A. Ryerson generously provided funds for its
					purchase. Professor John M. Manly, Edith Rickert and Lillian
					Redstone were active in the purchase negotiations. Portions
					of the Holt-Wilson collection also were acquired by the
					British Museum, and by Edmund Farrer. Further information on
					the provenance of the collection may be found in C.R. Bald,
					Donne and the Drurys (1959)."
					)
(:end helpers :)
	let $ds_id := ""
	let $date_last_updated := ""
	let $source_type := "ead-xml"
	let $cataloging-convention := ""
	let $holding_institution_as_recorded := "University of Chicago Library"
	let $holding_institution_id_number := ""
	let $holding_institution_shelfmark := $mss/did/container[@type="Ms"]/data(@type) || " " || $mss/did/container
	let $link_to_holding_institution_record := $mss/ancestor::archdesc/descgrp/otherfindaid/p/extref/data(@href)
	let $iiif_manifest := ""
	let $geogname := 
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/geogname/text(), '|')
		else string-join($mss/ancestor::archdesc/descgrp/controlaccess/geogname/text(), '|')
	let $genre_as_recorded := 
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/genreform/text(), '|')
		else string-join($mss/ancestor::archdesc/descgrp/controlaccess/genreform/text(), '|')
	let $production_place_as_recorded := ""
	let $production_date_as_recorded := 
		if (matches($unittitle, "(^undated)|(undated\s?\p{P}?\s?$)", "i;j"))
		then "undated"
		else
			if (matches($unittitle, "1\d{3}"))
			then replace(
				normalize-space(
					replace($unittitle, 
						"(^|.+?)((((?<!(£|([Nn]o\.\s)))1\d{3}(?!\smarks))([\s,;]+)?){1,4}((-(1\d{3}|\d{2}))?([\s,;]+)?((1\d{3})(-(1\d{3}|\d{2}))?)?){0,4})(.*)", 
						"$2", "i;j")
				), "[;,]", "")
(:
use cases
1295 - ok
1259-1265 - ok
1352; 1354-1355 - ok
1266, 1271; 1275-1276 - ok
1342, 1345; 1347-1349; 1351 - ok
1351; 1356; 1358-1359; 1361-1363; 1365-1366 - ok
1619-1620; 1623 - ok
1322-1323; 1324-1325 - ok
1377-1391; 1395; 1397-1399 - ok
1343-1344; 1346-1350; 1357 - ok
1335-1338; 1341-1342; 1345; 1347-1349 - ok
1423-25; 1457-60 - ok
:)			else ""

	let $production_date_start := 
		if ($production_date_as_recorded[not(.="")])
		then replace($production_date_as_recorded, "(^\d{4})(.*)", "$1")
		else ""
	let $production_date_end := 
		if ($production_date_as_recorded[not(.="")])
		then replace($production_date_as_recorded, "(.*?)(\d{4}$)", "$2")
		else ""
	let $dated := 
		if ($production_date_as_recorded[not(.="")])
		then "TRUE"
		else "FALSE"
	let $title_as_recorded := $unittitle
	let $uniform_title_as_recorded := ""
	let $subject_as_recorded :=
		if ($mss/controlaccess)
		then string-join($mss/controlaccess/subject/text(), '|')
		else string-join($mss/ancestor::archdesc/descgrp/controlaccess/subject/text(), '|')
	let $author_as_recorded := ""
	let $artist_as_recorded := ""
	let $scribe_as_recorded := ""
	let $associated_agent_as_recorded := if ($mss/controlaccess)
		then string-join($mss/controlaccess/(persname|corpname|famname)/text(), '|')
		else string-join($mss/ancestor::archdesc/descgrp/controlaccess/(persname|corpname|famname)/text(), '|')
	let $former_owner_as_recorded := ""
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
	let $physical_description_misc := 
		if (matches($unittitle, "seals:\s?\w", "i"))
		then
			replace($unittitle, "([\D\S]+?\s?\(\s?)(seals:\s.+?)(\))", "$2", "i")
		else ""
	let $note_1 := 
		$mss/ancestor::c01/did/unittitle || ": " || 
		$mss/ancestor::c02/did/unittitle || 
		(if ($mss/ancestor::c03) then (": " || $mss/ancestor::c03/did/unittitle) else "")
	let $acknowledgments := 
		if ($mss/acqinfo)
		then (string-join($mss/acqinfo/p, "|"))
		else 
			if ($mss//ancestor::ead/eadheader//sponsor)
			then $mss//ancestor::ead/eadheader//sponsor/text()
			else "Martin A. Ryerson"
	let $data_source_modified := ""
	let $layout := ""
	let $script := ""
	let $decoration := ""
	let $binding := ""
	let $provenance := 
		if (string-length($provenance-string	
			)>380) 
			then substring($provenance-string, 1, 380) || "...[text truncated]" 
			else $provenance-string
	let $disambiguator := ""
	let $note_2 := 
		if ($mss/scopecontent)
		then normalize-space($mss/scopecontent)
		else
		substring(normalize-space(string-join($mss/ancestor::archdesc/descgrp/scopecontent/*[not(self::head)]/text(), '|')), 1, 380) || (if ($mss/ancestor::archdesc/descgrp/scopecontent/*[not(self::head)]/string-length(.)>380) then "...[text truncated]" else ())
	let $dimensions := ""
	let $extent := 
		if (matches($unittitle, "membranes:\s?\d+", "i"))
		then
			replace($unittitle, "([\D\S]+?\s?\(\s?)(membranes:\s.+?)(\))", "$2", "i")
		else ""
	
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
return $csv/text()
(:let $csv := document{$csv/text()}
return put($csv, "bacon2ds.csv"):)
