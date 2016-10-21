/*
PURPOSE: dissection of NHS inndicators metadata HTML extract

USAGE:
change database on line 9
change filename on line 103

*/
USE [test2016]                              --CHANGE to your database
GO
--cleanup previous attmepts
DROP VIEW [VwTNhsInd_b]
DROP TABLE [tNhsInd_b]
DROP FUNCTION [dbo].[tNhsIndReplaceAll_b]
DROP TABLE tNhsIndLineType_b
DROP TABLE tNhsIndReplaces_b
drop table #tNhsInd_b_c1
drop table #tNhsInd_b_c2
drop table #tNhsInd_c
drop table #tNhsInd_d
drop table #tNhsInd_e
drop table #tNhsInd_results
drop table #tNhsInd_keywords
drop table #tNhsInd_downloads

CREATE TABLE tNhsIndLineType_b(
	[data] [nvarchar](max) NULL,
	[datatype] [varchar](max) NULL
)
GO

CREATE TABLE tNhsIndReplaces_b(
	[ReplaceThis] [varchar](max) NULL,
	[ReplaceWith] [varchar](max) NULL
)
GO

INSERT tNhsIndLineType_b ([data], [datatype]) VALUES 
 (N'<H3 class=ddititle>Compendium Identifier </H3>', N'"compendium_identifier":')
,(N'<H3 class=ddititle>Unique Identifier </H3>', N'"unique_identifier":')
,(N'<H3 class=ddititle>Current version uploaded </H3>', N'"current_version_uploaded":')
,(N'<H3 class=ddititle>Title </H3>', N'"title":')
,(N'<H3 class=ddititle>Definition </H3>', N'"definition":')
,(N'<H3 class=ddititle>Keyword(s)</H3>', N'"keywords":')
,(N'<H2 class=ddititle>Download(s) </H2>', N'"downloads":')
,(N'<H3 class=ddititle>Purpose</H3>', N'"purpose":')
,(N'<H3 class=ddititle>Next version due </H3>', N'"next_version_due":')
GO

INSERT tNhsIndReplaces_b ([ReplaceThis], [ReplaceWith]) VALUES 
 (N' </P>', N'"')
,(N'<DIV class=ddicontent>', N'"')
,(N' </LI></UL>', N'')
,(N'<H2><SPAN id=topspan>Dataset: ', N'"')
,(N' </SPAN>"</DIV>', N'"')
,(N'<H3 class=ddititle>', N'"')
,(N' </DIV>', N'"')
,(N'<P class=ddicontent>', N'"')
,(N'<H2 class=ddititle>', N'"')
,(N'</H3>', N'"')
,(N'</H2>', N'"')
,(N'<LI>', N'"')
GO

CREATE FUNCTION [dbo].[tNHSindReplaceAll_b]
(
    @text varchar(max)
)
RETURNS VARCHAR(max)
AS
BEGIN
    SELECT @text = 
       REPLACE(@text, r.[ReplaceThis], r.[ReplaceWith])
    FROM    tNhsIndReplaces_b r;
    RETURN @text
END
GO


--DROP TABLE [tNhsInd_b]
GO
CREATE TABLE [dbo].[tNhsInd_b](
	[LineNo] [int] IDENTITY(1,1) NOT NULL,
	[SetNo] [int] NULL,
	[datatype] [varchar](max) NULL,
	[DataOriginal] [varchar](max) NULL,
	[DataCleansed]  AS (ltrim(rtrim([dbo].[tNHSindReplaceAll_b]([DataOriginal])))),
	[Relevant?] [varchar](5) NULL,
	[LenDataOriginal]  AS (datalength([DataOriginal])) PERSISTED,
	[LenDataCleansed]  AS (datalength(ltrim(rtrim([dbo].[tNHSindReplaceAll_b]([DataOriginal]))))),
	[LenDataDifference]  AS (datalength([DataOriginal])-datalength(ltrim(rtrim([dbo].[tNHSindReplaceAll_b]([DataOriginal])))))
) 
GO

--DROP VIEW [VwTNhsInd_b]
GO
CREATE VIEW [VwTNhsInd_b] AS
SELECT [DataOriginal] FROM [tNhsInd_b]
GO
--
print 'BULK INSERT'
BULK INSERT [VwTNhsInd_b]
FROM 'S:\_ue\phec_NHS_indicators_20161010.html'
WITH (
CODEPAGE  = 'RAW'
,DATAFILETYPE = 'widechar'
,ROWTERMINATOR = '\n'
) --(474580 row(s) affected)
GO


--DROP TABLE #tNhsInd_b_c1
GO
--add Rownumbers to start rows and final row
print 'add Rownumbers to start rows and final row'
SELECT [LineNo]
		 , ROW_NUMBER() OVER (ORDER BY [LineNo]) as 'RowNo' 
		 INTO #tNhsInd_b_c1
FROM [tNhsInd_b] 
WHERE [DataOriginal] like N'<!--¬%'
GO --OK (2002 row(s) affected)

--DROP TABLE #tNhsInd_b_c2
GO
--get SetNo, Start and End
print 'get SetNo, Start and End'
SELECT t1.[RowNo] as 'SetNo'
 		 , t1.[LineNo] as 'StartNo'
		 , t2.[LineNo] as 'EndNo'
		 INTO #tNhsInd_b_c2
FROM #tNhsInd_b_c1 t1
INNER JOIN #tNhsInd_b_c1 t2
ON t2.[RowNo]=t1.[RowNo]+1
GO --OK (2001 row(s) affected)


--as UPDATE
PRINT 'as UPDATE'
UPDATE [tNhsInd_b]
SET [SetNo] = t5.[SetNo]
FROM [tNhsInd_b] t4
CROSS APPLY (
SELECT TOP 1 *
FROM #tNhsInd_b_c2 t3
WHERE t4.[LineNo] >= t3.[StartNo] AND t4.[LineNo]  < t3.[EndNo]
ORDER BY t3.[StartNo] DESC) as t5
GO --OK (474578 row(s) affected)

--DROP table #tNhsInd_c
GO
--using temp tables
PRINT 'using temp tables'
PRINT '#tNhsInd_c'
;WITH cte_cleanse AS (
SELECT * FROM [tNhsInd_b]
	WHERE 1=1
	AND 
	 (
			(
					[DataOriginal] IS NOT NULL
			AND [DataOriginal] not like '%<!--¬%'  
			AND [DataOriginal] not like 'translation.%'
			AND [DataOriginal] not like '<!-- put analytics code here --></DIV>'

			AND [DataOriginal] not like '%<!--¬%'  
			AND [DataOriginal] not like '[['  --escaped [
			AND [DataOriginal] not like ']'
			AND [DataOriginal] not like '  }%'
			AND [DataOriginal] not like '  {%'
			AND [DataOriginal] not like '//%'
			AND [DataOriginal] not like 'YAHOO%'
			AND [DataOriginal] not like 'hasRun=%'
			AND [DataOriginal] not like 'baseUrl =%'
			AND [DataOriginal] not like 'newUrl =%'
			AND [DataOriginal] not like 'spinnerUrl =%'
			AND [DataOriginal] not like 'object%'
			AND [DataOriginal] not like 'function%'
			AND [DataOriginal] not like 'var %'
			AND [DataOriginal] not like 'if %'
			AND [DataOriginal] not like '</S%'
			AND [DataOriginal] not like '<SC%'
			AND [DataOriginal] not like 'class%'
			AND [DataOriginal] not like 'collapsor%'
			AND [DataOriginal] not like '_gaq%'  --?
			AND [DataOriginal] not like 'ga.src%'  --?
			AND [DataOriginal] not like '(func%'  --?
			AND [DataOriginal] not like '}%'
			AND [DataOriginal] not like '<T%'
			AND [DataOriginal] not like '<F%'
			AND [DataOriginal] not like 'bookmarkurl%'
			AND [DataOriginal] not like '%onclick%'
			AND [DataOriginal] not like '<DIV i%'
			AND [DataOriginal] not like '<UL %'
			AND [DataOriginal] not like '<DIV c%'
			AND [DataOriginal] not like '<DIV>%'
			AND [DataOriginal] not like '</DIV>'  --?
			AND [DataOriginal] not like 'mode =%'
			AND [DataOriginal] not like 'recode%'  --?
			AND [DataOriginal] not like '<H3>Frame%'
			AND [DataOriginal] not like '<H3>Object%'
			)
		OR 
			(  --include the ones accidentally excluded above
					[DataOriginal] like '%ddicontent%'
				OR [DataOriginal] like '%ddititle%'
			)
		)
)
,cte_res1 AS (
SELECT 
    t1.SetNo
	, ROW_NUMBER() OVER (ORDER BY t1.[LineNo]) as 'RowNo'
	, t1.[LineNo]
	, t1.[datatype]
  , t1.[DataOriginal]
  , t1.[DataCleansed]
FROM cte_cleanse t1
)
,cte_res2 AS (
SELECT t1.SetNo
      ,t1.[RowNo]
      ,t1.[LineNo]
      ,t3.[datatype]
      ,t1.[DataCleansed]
FROM cte_res1 t1
INNER JOIN cte_res1 t2 
ON t1.[RowNo] = t2.[RowNo]+1
LEFT JOIN tNhsIndLineType_b t3
ON t2.[DataOriginal] = t3.data
)
--SELECT * FROM cte_res2 order by [LineNo] --57268
SELECT * 
INTO #tNhsInd_c
FROM cte_res1
order by [LineNo]
GO

--DROP table #tNhsInd_d
GO
PRINT '#tNhsInd_d'
;WITH cte_1 AS (
--1st line
SELECT t1.SetNo
      ,t1.[RowNo]
      ,t1.[LineNo]
      ,'"dataset": ' as [datatype]
      ,[DataCleansed] as 'data'
FROM #tNhsInd_c t1 WITH (NOLOCK, READUNCOMMITTED )  --doesn't amke a difference
WHERE t1.[RowNo] = 1
UNION ALL
--other lines
SELECT t1.SetNo
      ,t1.[RowNo]
      ,t1.[LineNo]
      ,CASE WHEN Left(t1.[DataOriginal],29)='<H2><SPAN id=topspan>Dataset:' THEN '"dataset": ' ELSE t3.[datatype] END
      ,t1.[DataCleansed] as 'data'
FROM #tNhsInd_c t1 WITH (NOLOCK, READUNCOMMITTED )
INNER JOIN #tNhsInd_c t2  WITH (NOLOCK, READUNCOMMITTED )
ON t1.[RowNo] = t2.[RowNo]+1
LEFT JOIN tNhsIndLineType_b t3
ON t2.[DataOriginal] = t3.data
--WHERE [dbo].[tNHSindReplaceAll_b](t1.[data]) like '"<A href="%'
--order by t1.[RowNo]
),
cte_2 AS (
SELECT t1.[SetNo]
      ,ROW_NUMBER() OVER (PARTITION BY t1. [SetNo] ORDER BY t1.[RowNo]) as [RowNum]
      ,t1.[RowNo]
      ,t1.[LineNo]
			,t1.[datatype]
			,t1.[data]
FROM cte_1 t1
WHERE 1=1
AND t1.[data] NOT IN ('"Purpose"','"Title "','"Compendium Identifier "','"Unique Identifier "','"Current version uploaded "','"Definition "','"Keyword(s)"','"Download(s) "','"Next version due "')
),
cte_3 AS (
--1st line
SELECT cur.[SetNo]
      ,cur.[RowNum]
      ,cur.[RowNo]
      ,cur.[LineNo]
			,cur.[datatype]
			,cur.[data]
FROM cte_2 cur
WHERE cur.[RowNum] = 1
--lines to fill
UNION ALL
SELECT curr.[SetNo]
      ,curr.[RowNum]
      ,curr.[RowNo]
      ,curr.[LineNo]
			,ISNULL(curr.[datatype],prev.[datatype]) as [datatype]
			,curr.[data]
FROM cte_2 curr
INNER JOIN cte_3 prev
ON curr.[SetNo] = prev.[SetNo]
AND curr.[RowNum] = prev.[RowNum] + 1
--WHERE 1=1
--AND curr.[data] NOT IN ('"Purpose"','"Title "','"Compendium Identifier "','"Unique Identifier "','"Current version uploaded "','"Definition "','"Keyword(s)"','"Download(s) "','"Next version due "')
--ORDER BY [RowNo]
)
--cte_3 takes forever, so aborted and whacked cte_2 in table
SELECT * 
INTO #tNhsInd_d  --<-- cte_2 in table
FROM cte_2
ORDER BY [RowNo]
GO

--DROP table #tNhsInd_e 
GO
--
PRINT '#tNhsInd_e'
;WITH cte_3 AS (
SELECT cur.[SetNo]
      ,cur.[RowNum]
      ,cur.[RowNo]
      ,cur.[LineNo]
			,cur.[datatype]
			,cur.[data]
FROM #tNhsInd_d cur WITH (NOLOCK, READUNCOMMITTED )
WHERE cur.[RowNum] = 1
AND cur.[SetNo] IS NOT NULL
UNION ALL
SELECT curr.[SetNo]
      ,curr.[RowNum]
      ,curr.[RowNo]
      ,curr.[LineNo]
			,ISNULL(curr.[datatype],prev.[datatype]) as [datatype]
			,curr.[data]
FROM #tNhsInd_d curr WITH (NOLOCK, READUNCOMMITTED )
INNER JOIN cte_3 prev
ON curr.[SetNo] = prev.[SetNo]
AND curr.[RowNum] = prev.[RowNum] + 1
)
SELECT * 
INTO #tNhsInd_e 
FROM cte_3
ORDER BY [RowNo]
GO

--pivot of results level
PRINT 'pivot of results level'
PRINT '#tNhsInd_results'
SELECT [SetNo]
     , [dataset]
		 , [purpose]
		 , [title]
		 , [compendium_identifier]
		 , [unique_identifier]
		 , [next_version_due]
		 , [current_version_uploaded]
		 , [definition]
		 INTO #tNhsInd_results
FROM 
(
SELECT [SetNo]
--      ,[RowNum]
--      ,[RowNo]
--      ,[LineNo]
--      ,[Lendata]
      ,REPLACE(REPLACE([datatype],'"',''),':','') as [datatype]
      ,[data]
  FROM #tNhsInd_e WITH (NOLOCK, READUNCOMMITTED )
WHERE 1=1
AND [datatype] NOT IN ('"keywords":','"downloads":')
--	order by [RowNo]
) AS s
PIVOT
(
  MAX([data])
	FOR [datatype] IN (
	  [dataset]
	, [purpose]
	, [title]
	, [compendium_identifier]
	, [unique_identifier]
	, [next_version_due]
	, [current_version_uploaded]
	, [definition]
	)
) as p
	order by [SetNo]
GO
--keywords
PRINT '#tNhsInd_keywords'
SELECT [SetNo]
      , ROW_NUMBER() OVER (PARTITION BY [SetNo] ORDER BY [RowNo]) AS [keyword_number_within_set]
      ,REPLACE([data],'"','') as 'keyword'
			INTO #tNhsInd_keywords
  FROM #tNhsInd_e
WHERE 1=1
AND [datatype] = '"keywords":'
	order by [SetNo], [RowNo]
GO

--downloads
--DROP table #tNhsInd_downloads
GO
PRINT '#tNhsInd_downloads'
SELECT [SetNo]
      , ROW_NUMBER() OVER (PARTITION BY [SetNo] ORDER BY [RowNo]) AS [download_number_within_set]
--			, REPLACE(REPLACE([data],'"<A href="',''),'</A> "','')
--			, PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''))
--			, SUBSTRING(REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''),1,PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''))-1) as [file_hyperlink]
			,CASE WHEN SUBSTRING(REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''),1,1) = '/' 
			      THEN 'https://indicators.hscic.gov.uk'  --indicators.ic.nhs.uk
						ELSE ''
						END 
			   + 
			   CASE WHEN PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "','')) = 0
			        THEN NULL
					  	ELSE SUBSTRING(REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''),1,PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''))-1)
					  	END as [file_hyperlink]
			,CASE WHEN PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "','')) = 0
			      THEN REPLACE(REPLACE([data],'"',''),'&nbsp;','')
						ELSE SUBSTRING(REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''),PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''))+14,500)
						END as [file_desciption]
			 ,CASE WHEN SUBSTRING(REPLACE(REPLACE([data],'"<A href="',''),'</A> "',''),1,1) = '/' 
			      THEN 'Y' -- NHSindicators links 'https://indicators.hscic.gov.uk' (was: 'https://indicators.ic.nhs.uk')
						ELSE 
						  CASE WHEN PATINDEX('%" target=_new>%',REPLACE(REPLACE([data],'"<A href="',''),'</A> "','')) = 0
							     THEN NULL
									 ELSE 'N' -- non NHSindicators links
									 END
						END as [IsNHSIndicatorLink?]
			INTO #tNhsInd_downloads
  FROM #tNhsInd_e
WHERE 1=1 
AND [data] not like '"</P>%'
--AND REPLACE(REPLACE([data],'"<A href="',''),'</A> "','') not like '%" target=_new>%'
AND [datatype] = '"downloads":'
order by [SetNo], [RowNo]
GO

PRINT '#tNhsInd_downloads'
SELECT DISTINCT [file_hyperlink] as [unique_file_hyperlinks]
FROM  #tNhsInd_downloads
WHERE [IsNHSIndicatorLink?] = 'Y'
GO

PRINT 'SELECTS'
SELECT * FROM #tNhsInd_results ORDER BY [SetNo] 
SELECT * FROM #tNhsInd_keywords ORDER BY [SetNo], [keyword_number_within_set]
SELECT * FROM #tNhsInd_downloads 
WHERE 1=1
AND file_hyperlink is null
ORDER BY [SetNo], [download_number_within_set]
--SELECT * FROM tNhsInd_b ORDER BY [LineNo]  --OK
--SELECT * FROM #tNhsInd_c ORDER BY [SetNo], [RowNo]  --OK
--SELECT * FROM #tNhsInd_d ORDER BY [SetNo], [RowNo]  --OK
--SELECT * FROM #tNhsInd_e ORDER BY [SetNo], [RowNo]  --OK


GO
PRINT 'CLEANUP'
--cleanup
--DROP VIEW [VwTNhsInd_b]
--DROP TABLE [tNhsInd_b]
--DROP FUNCTION [dbo].[tNhsIndReplaceAll_b]
--DROP TABLE tNhsIndLineType_b
--DROP TABLE tNhsIndReplaces_b
--drop table #tNhsInd_b_c1
--drop table #tNhsInd_b_c2
--drop table #tNhsInd_c
--drop table #tNhsInd_d
--drop table #tNhsInd_e
--drop table #tNhsInd_results
--drop table #tNhsInd_keywords
--drop table #tNhsInd_downloads

