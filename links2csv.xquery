xquery version "3.0";

(:create a manifest mapping 001 and 035 to 856$u :)
(: superseded by shell script to get manifest from figgy:)

declare variable $collection as document-node()* := doc("file:/Users/heberleinr/Documents/Digital%20Scriptorium/submissions/2023-07/BIBLIOGRAPHIC_28080329690006421_1.xml");

for $record in $collection//record[datafield[@tag='856']]
let $mmsid := $record/controlfield[@tag='001']/text()
let $id1 := $record/(datafield[@tag='035']/subfield[@code='a'])[1]/text()
let $id2 := $record/(datafield[@tag='035']/subfield[@code='a'])[2]/text()
let $resourceurl := $record/datafield[@tag='856']/subfield[@code='u']/text()
let $resourcetype := $record/datafield[@tag='856']/subfield[@code='z']/text()


return 
normalize-space(
$mmsid || '^' || $id1 || '^' || $id2 || '^' || $resourceurl || '^' || $resourcetype) || codepoints-to-string(10)
