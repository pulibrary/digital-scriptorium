# digital-scriptorium
Tools for contributing PUL records to DS

## Alma workflow
For things that have MMSIDs
1. Create a set via search
   - Resources > Manage Sets > Create Set
   - All Titles > Itemized > From File
   - Content > Export list
3. Run export job over set
   - Admin > Run a Job
   - Export Bibliographic Records > [select set]
   - Job Report > Link to records > download
4. Get call numbers from Analytics
   - Analytics > Access Analytics > Create > Analysis
   - Physical Items: Bibliographic Details > MMSID, Holding Details > Permanent Call Number
   - download as CSV
5. Run shell script to add Figgy manifests to CSV
