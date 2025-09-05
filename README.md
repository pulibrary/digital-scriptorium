# digital-scriptorium
Tools for contributing PUL records to DS

## Alma workflow
For things that have MMSIDs

2. Create a set via search
   - Admin > Manage Sets > Create Set
   - All Titles > Itemized > From File
   - Content > Export list
3. Run export job over set
   - Admin > Run a Job
   - Export Bibliographic Records > [select set]
   - Job Report > Link to records > download
4. Get call numbers from Analytics
   - Analytics > Access Analytics > Create > Analysis
   - Physical Items: Holding Details > Permanent Call Number, Bibliographic Details > MMSID; filter by MMSID
   - download as CSV
5. Run shell script to add Figgy manifests to CSV
   - prep the file: remove or escape commas and parentheses; add a dummy header in the 4th column to force a blank 3d colum; remove "electronic resource" and "unknown")
   - mmsid must be the first column
   - `bash get-manifest-from-MMSID.sh input_file output_file`
