-- Quick look at population figures


SELECT NHGIS_2015.STATE, 
		NHGIS_2015.COUNTY, 
		NHGIS_2015.ADKWE001, 
		NHGIS_2016.AF2AE001, 
		NHGIS_2017.AHY1E001,
		NHGIS_2018.AJWME001, 
		NHGIS_2019.ALUBE001
FROM NHGIS_2015
	LEFT JOIN NHGIS_2016 ON NHGIS_2016.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN NHGIS_2017 ON NHGIS_2017.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN NHGIS_2018 ON NHGIS_2018.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN NHGIS_2019 ON NHGIS_2019.GISJOIN = NHGIS_2015.GISJOIN
ORDER BY NHGIS_2015.STATE;




-- CLEANING THE DATA



--2015

-- Split all in multiple rows
CREATE TABLE #breakout (col nvarchar(100), part nchar(1), pos int)

;WITH cte AS(
    SELECT GISJOIN, 
		LEFT(GISJOIN, 1) AS part, 
		1 AS pos
    FROM NHGIS_2015
    UNION ALL
    SELECT GISJOIN, 
		SUBSTRING(GISJOIN, pos+1,1) AS part, 
		pos+1 AS part
    FROM cte
    WHERE LEN(GISJOIN) > pos
)
INSERT INTO #breakout(col, part, pos)
    SELECT GISJOIN, part, pos
    FROM cte

DECLARE @sql nvarchar(max), 
		@columnlist nvarchar(max)

-- Generate Columlist for dynamic pivot
SELECT @columnlist = COALESCE(@columnlist + N',[' + CONVERT(nvarchar(max),pos) + ']', N'[' + CONVERT(nvarchar(max),pos) + ']')
FROM #breakout br
WHERE br.col = (SELECT TOP (1) col 
				FROM #breakout 
				ORDER BY LEN(col) DESC)

-- Pivoting for readability
SET @sql = N'
	SELECT pvt.* 
	FROM #breakout br
	PIVOT (
		MAX(br.part)
		FOR pos IN('+@columnlist+')
	) AS pvt'
EXEC (@sql)

-- CTRL+SHIFT+C EACH result into Excel, delete comlumns 4 & 8, CONCATENATE for corrected Census Tract Code
-- Remember to import CCYEAR tables for ALTER process

-- Add new column for corrections
ALTER TABLE NHGIS_2015
ADD TRACT2 nvarchar(100)
;

-- Input corrections
UPDATE NHGIS_2015
SET TRACT2 = b.CONCATENATE
FROM NHGIS_2015 a
JOIN CC_2015 b
	ON a.GISJOIN = b.col
WHERE a.TRACT2 IS NULL
;

--Review for correctness
SELECT GISJOIN, 
		STATE, 
		COUNTY, 
		TRACT2 
FROM NHGIS_2015 
ORDER BY STATE, 
		COUNTY
;

--Drop temp table and cycle through
DROP TABLE #breakout




--CREATE QOZ BINARY
--Match OZ List with NHGIS Data and creat binary indicating designated OZ tracts

-- 2015
-- Add new column for binary indicator
ALTER TABLE NHGIS_2015
ADD QOZ nvarchar(10)
;

-- Input zeros
UPDATE NHGIS_2015
SET QOZ = 0
FROM NHGIS_2015 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NULL
;

-- Input ones
UPDATE NHGIS_2015
SET QOZ = 1
FROM NHGIS_2015 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NOT NULL
;

--Review for correctness
SELECT STATE, 
		COUNTY, 
		QOZ 
FROM NHGIS_2015 
ORDER BY STATE, 
		COUNTY
;



-- Now we can look at population figures for QOZs only


SELECT NHGIS_2015.QOZ, 
		NHGIS_2015.STATE, 
		NHGIS_2015.COUNTY, 
		NHGIS_2015.POP, 
		NHGIS_2016.AF2AE001, 
		NHGIS_2017.AHY1E001,
		NHGIS_2018.AJWME001, 
		NHGIS_2019.ALUBE001
FROM [CENSUS-DATA]..NHGIS_2015
	LEFT JOIN [CENSUS-DATA]..NHGIS_2016 ON NHGIS_2016.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2017 ON NHGIS_2017.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2018 ON NHGIS_2018.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2019 ON NHGIS_2019.GISJOIN = NHGIS_2015.GISJOIN
ORDER BY NHGIS_2015.STATE, 
		NHGIS_2015.QOZ;




-- Use NTILES to group similar counties into quartiles by population
-- This can be an indication that we've identified tracts that have seen changes in their population due to policy

WITH tiles AS (
	SELECT 	NHGIS_2015.STATE,
			NHGIS_2015.TRACT2,
			NHGIS_2015.QOZ,
			NTILE(4) OVER ( ORDER BY NHGIS_2015.POP) AS Quartile2015,
			NTILE(4) OVER ( ORDER BY NHGIS_2019.ALUBE001) AS Quartile2019	
FROM [CENSUS-DATA]..NHGIS_2015
	LEFT JOIN [CENSUS-DATA]..NHGIS_2019 ON NHGIS_2019.GISJOIN = NHGIS_2015.GISJOIN
	)
SELECT  STATE,
		TRACT2,
		QOZ,
		Quartile2015, 
		Quartile2019,
CASE 
	WHEN Quartile2015 = Quartile2019 THEN 'Same'
	ELSE 'Change'
END AS ChangeIndicator
FROM tiles
WHERE QOZ = 1
ORDER BY STATE, TRACT2
;

