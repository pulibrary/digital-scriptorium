xquery version "3.0";
declare option saxon:output "omit-xml-declaration=yes";

declare variable $marc as document-node()+ := doc("file:/Users/heberleinr/Documents/Digital_Scriptorium/submissions/2024_08/Islamic_II/BIBLIOGRAPHIC_38955194630006421_1_bkp.xml");


let $subjects := $marc//record/datafield[matches(@tag, '^65')]/subfield[@code='a']

for $distinct in distinct-values($subjects)
order by count($subjects[string(.)=$distinct]) descending
return

count($subjects[string(.)=$distinct]) || " " || $distinct || codepoints-to-string(10)