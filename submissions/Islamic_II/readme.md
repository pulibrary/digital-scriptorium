This submission represents all remaining Islamic mss with physical holdings that were not included in the previous Islamic submission.

Workflow:
1. prerequisite: this workflow relies on a report of physical holdings of Islamic mss in Alma and a file of MARC-xml records exported from Alma based on that report
2. identify and extract a cohesive batch via XQuery from the BIBLIOGRAPHIC xml file (the XQuery deletes the records from the source file at the same time)
3. get mmsid's from resulting xml file and add them to the local IslamicMSS Excel file on a new tab
4. on that tab, get holdings via formula from islamic_no_constitutents tab
5. save as csv and run get_manifest_from_mmsid.sh over it
6. zip xml data file
7. submit zipped xml as well as CSV to DS
8. add submitted mmsid's to the "submitted" tab (needed for the formula for future Islamic submissions) and the "running_mmsids" Excel (needed to keep track of all records we've submitted to date)
