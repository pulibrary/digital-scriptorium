xquery version "3.0";
declare option saxon:output "omit-xml-declaration=yes";

declare variable $marc as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/BIBLIOGRAPHIC_38955194630006421_1.xml");
declare variable $persian as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/persian.xml");
let $records := $marc//record[controlfield[@tag="008"][contains(., "per")] | datafield[matches(@tag, '^65')][.="Manuscripts, Persian"]]

for $record in $records
return
(
	insert node $record as last into $persian//collection,
	delete node $record
)