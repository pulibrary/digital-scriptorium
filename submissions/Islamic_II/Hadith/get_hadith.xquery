xquery version "3.0";
declare option saxon:output "omit-xml-declaration=yes";

declare variable $marc as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/BIBLIOGRAPHIC_38955194630006421_1_bkp.xml");
declare variable $turkish as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/turkish.xml");
let $records := $marc//record[datafield[matches(@tag, '^65')]/subfield[@code='a'][matches(., "Hadith", 'i')]]
for $record in $records
return 
(:(
	insert node $record as last into $turkish//collection,
	delete node $record
):)