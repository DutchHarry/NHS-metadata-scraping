# NHS-metadata-scraping
Powershell scripts to get metadata of NHS datasets

Towards OpenAnalytics

Here will gradually appear a (near fully automated) production line for handling NHS (public) data.
Using tools from freely accessible MS stack (as that’s what most NHS organisations still use for analytics), thus 
Powershell: https://github.com/powershell
SQL Developer: https://www.microsoft.com/en-us/sql-server/sql-server-editions-developers
No silly stuff like SSIS though, all command line (bcp) or T-SQL (so free SSMS might be useful too: https://msdn.microsoft.com/en-us/library/mt238290.aspx )

What you'll get:
1.	getting metadata
a.	extraction of metadata
b.	processing of metadata 
c.	loading metadata on database
2.	getting data
a.	downloading, recording download link, local path, and filehash
(unfortunately sites don't hash themselves (apart from TRUD), so difficult to ascertain if files changed
3.	pre-processing (selected sets)
a.	converting to formats for loading on databases
mainly reliably converting excel files to delimited (CSV) textfiles for BULK INSERT without data type or conversion issues.
b.	Selected sets will include TRUD data (incl. ODS), prescribing, QOF, indicators, practice data, reference costs, population data, prevalence data, and all other potentially relevant reference data.
4.	loading
a.	or just linking to view
b.	transforming so that both ‘AtTime’ and ‘Today’ views are possible (e.g. aggregating to successor organisations)

You can think of it as all the tools for a 'virtual' data warehouse that could drive an OpenAnalytics Platform.

Later the tools for processing non-public data, e.g. SUS data or record level HES datasets will also be added. So with an appropriate dataset you’d be able do to the best possible analytics. None of the DSCROs/DSFCs or CSUs currently seems capable of reliable data processing, not even duplicate removal, cleansing and proper pseudonymisation seems possible. So once you’ve discovered that their fancy Tableau charts pretending to give you the ‘one and only authoritative version of the truth’ are basically aggregating rubbish data, you can choose to start doing it yourself again. The graphs won’t be as fancy (yet), but the underlying data will be provable correct (you don’t have to rely on words for that, you just can follow the built in audit trail)

Note that apart from the occasional sample set, data will not be hosted here, not in original formats, and not in processed formats (say loaded databases). There’s no space for that on github.
