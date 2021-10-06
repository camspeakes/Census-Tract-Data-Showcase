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





--2016

-- Add new column for corrections
ALTER TABLE NHGIS_2016
ADD TRACT2 nvarchar(100)
;

-- Input corrections
UPDATE NHGIS_2016
SET TRACT2 = b.CONCATENATE
FFROM NHGIS_2016 a
JOIN CC_2015 b
	ON a.GISJOIN = b.col
WHERE a.TRACT2 IS NULL
;

--Review for correctness
SELECT STATE, COUNTY, TRACT2 
FROM NHGIS_2016 
ORDER BY STATE, COUNTY
;






--2017

-- Add new column for corrections
ALTER TABLE NHGIS_2017
ADD TRACT2 nvarchar(100)
;

-- Input corrections
UPDATE NHGIS_2017
SET TRACT2 = b.CONCATENATE
FROM NHGIS_2017 a
JOIN CC_2015 b
	ON a.GISJOIN = b.col
WHERE a.TRACT2 IS NULL
;

--Review for correctness
SELECT STATE, COUNTY, TRACT2 
FROM NHGIS_2017 
ORDER BY STATE, COUNTY
;






--2018

-- Add new column for corrections
ALTER TABLE NHGIS_2018
ADD TRACT2 nvarchar(100)
;

-- Input corrections
UPDATE NHGIS_2018
SET TRACT2 = b.CONCATENATE
FROM NHGIS_2018 a
JOIN CC_2015 b
	ON a.GISJOIN = b.col
WHERE a.TRACT2 IS NULL
;

--Review for correctness
SELECT STATE, COUNTY, TRACT2 
FROM NHGIS_2018 
ORDER BY STATE, COUNTY
;







--2019

-- Add new column for corrections
ALTER TABLE NHGIS_2019
ADD TRACT2 nvarchar(100)
;

-- Input corrections
UPDATE NHGIS_2019
SET TRACT2 = b.CONCATENATE
FROM NHGIS_2019 a
JOIN CC_2015 b
	ON a.GISJOIN = b.col
WHERE a.TRACT2 IS NULL
;

--Review for correctness
SELECT STATE, COUNTY, TRACT2 
FROM NHGIS_2019 
ORDER BY STATE, COUNTY
;


--ALL YEARS NOW HAVE THE CORRECT CENSUS TRACT CODE




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


-- 2016
-- Add new column for binary indicator
ALTER TABLE NHGIS_2016
ADD QOZ nvarchar(10)
;

-- Input zeros
UPDATE NHGIS_2016
SET QOZ = 0
FROM NHGIS_2016 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NULL
;

-- Input ones
UPDATE NHGIS_2016
SET QOZ = 1
FROM NHGIS_2016 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NOT NULL
;

--Review for correctness
SELECT STATE, COUNTY, QOZ 
FROM NHGIS_2016 
ORDER BY STATE, COUNTY
;


-- 2017
-- Add new column for binary indicator
ALTER TABLE NHGIS_2017
ADD QOZ nvarchar(10)
;

-- Input zeros
UPDATE NHGIS_2017
SET QOZ = 0
FROM NHGIS_2017 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NULL
;

-- Input ones
UPDATE NHGIS_2017
SET QOZ = 1
FROM NHGIS_2017 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NOT NULL
;

--Review for correctness
SELECT STATE, COUNTY, QOZ 
FROM NHGIS_2017 
ORDER BY STATE, COUNTY
;


-- 2018
-- Add new column for binary indicator
ALTER TABLE NHGIS_2018
ADD QOZ nvarchar(10)
;

-- Input zeros
UPDATE NHGIS_2018
SET QOZ = 0
FROM NHGIS_2018 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NULL
;

-- Input ones
UPDATE NHGIS_2018
SET QOZ = 1
FROM NHGIS_2018 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NOT NULL
;

--Review for correctness
SELECT STATE, 
		COUNTY, 
		QOZ 
FROM NHGIS_2018 
ORDER BY STATE, 
		COUNTY
;


-- 2019
-- Add new column for binary indicator
ALTER TABLE NHGIS_2019
ADD QOZ nvarchar(10)
;

-- Input zeros
UPDATE NHGIS_2019
SET QOZ = 0
FROM NHGIS_2019 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NULL
;

-- Input ones
UPDATE NHGIS_2019
SET QOZ = 1
FROM NHGIS_2019 a
LEFT JOIN OZ_List b
	ON a.TRACT2 = b.TRACT
WHERE b.TRACT IS NOT NULL
;

--Review for correctness
SELECT STATE, 
		COUNTY, 
		QOZ 
FROM NHGIS_2019 
ORDER BY STATE, 
		COUNTY
;

--ALL YEARS NOW HAVE QOZ INDICATOR






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




--Combining each year's table to create a full panel
--Use NTILES to group similar counties by median income?

SELECT NHGIS_2015.STATE,
		NHGIS_2015.QOZ, 
		AVG(NHGIS_2015.POP) AS '2015', 
		AVG(NHGIS_2016.AF2AE001) AS '2016', 
		AVG(NHGIS_2017.AHY1E001) AS '2017', 
		AVG(NHGIS_2018.AJWME001) AS '2018', 
		AVG(NHGIS_2019.ALUBE001) AS '2019',
		STDEV(NHGIS_2015.POP) AS '2015', 
		STDEV(NHGIS_2016.AF2AE001) AS '2016', 
		STDEV(NHGIS_2017.AHY1E001) AS '2017', 
		STDEV(NHGIS_2018.AJWME001) AS '2018', 
		STDEV(NHGIS_2019.ALUBE001) AS '2019'
FROM [CENSUS-DATA]..NHGIS_2015
	LEFT JOIN [CENSUS-DATA]..NHGIS_2016 ON NHGIS_2016.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2017 ON NHGIS_2017.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2018 ON NHGIS_2018.GISJOIN = NHGIS_2015.GISJOIN
	LEFT JOIN [CENSUS-DATA]..NHGIS_2019 ON NHGIS_2019.GISJOIN = NHGIS_2015.GISJOIN
GROUP BY NHGIS_2015.STATE, 
		NHGIS_2015.QOZ
ORDER BY NHGIS_2015.STATE,
		NHGIS_2015.QOZ;


NTILE(buckets) OVER (
    [PARTITION BY partition_expression, ... ]
    ORDER BY sort_expression [ASC | DESC], ...
)