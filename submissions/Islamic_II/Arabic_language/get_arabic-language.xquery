xquery version "3.0";
declare option saxon:output "omit-xml-declaration=yes";

declare variable $marc as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/to-do_Islamic-law/islamic-law-other.xml");
declare variable $language as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/to-do_Arabic-language/get_arabic-language.xml");
let $records := $marc//record[datafield[matches(@tag, '^65')]/subfield[@code='a'][matches(., "Arabic language", 'i')] and contains(controlfield[@tag='008'], 'ara')]
for $record in $records
return 
(
	insert node $record as last into $language//collection,
	delete node $record
)