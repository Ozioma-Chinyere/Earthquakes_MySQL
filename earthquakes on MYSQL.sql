-- THE BEGINING OF SCRIPT --
-- Create the Earthquake Database
DROP DATABASE IF EXISTS earthquakes;
CREATE DATABASE IF NOT EXISTS earthquakes;

USE earthquakes;

-- Create the earthquake_tb table
DROP TABLE IF EXISTS earthquake_tb;
CREATE TABLE IF NOT EXISTS earthquake_tb (
    earthquake_id INTEGER NOT NULL,
    occurred_on DATETIME,
    latitude DOUBLE,
    longitude DOUBLE,
    depth DOUBLE,
    magnitude DOUBLE,
    calculation_method VARCHAR(10),
    network_id VARCHAR(50),
    place VARCHAR(100),
    cause VARCHAR(50),
    CONSTRAINT earthquake_pkey PRIMARY KEY (earthquake_id)
);


SET GLOBAL local_infile = 'ON';

-- 1.2 Use the SHOW command to see that it is effected
SHOW GLOBAL VARIABLES LIKE 'local_infile';

SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/input_files/dbin_earthquake.csv' 
INTO TABLE earthquake_tb
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(earthquake_id,occurred_on,latitude,longitude,depth,magnitude,
calculation_method,network_id,place,cause);

-- Show the tables in the database of interest
SHOW TABLES;

--  Display the Table Structure 
DESCRIBE earthquake_tb;

-- Total number of records in a table
SELECT COUNT(*) -- Using COUNT function is faster
FROM earthquake_tb;

--  Preview the data in the earthquake table
SELECT *   
FROM earthquake_tb
limit 5;

--- EXPLORATORY DATA ANALYSIS

-- Causes and magnitudes of earthquakes:
-- Magnitude ranges across the different causes.
SELECT cause, COUNT(*) AS total_earthquakes, MIN(magnitude) AS minimum_magnitude, MAX(magnitude) AS maximum_magnitude
FROM earthquake_tb
GROUP BY cause;
-- returns the three causes of earthquakes, how many earthquakes per cause and the magnitude range for each cause

-- Places where nuclear explosions have caused earthquakes:
SELECT place, cause, COUNT(*) as earthquakes_per_place
FROM earthquake_tb
WHERE cause LIKE "nuclear%"
GROUP BY place, cause
ORDER BY earthquakes_per_place DESC;
-- nuclear explosion have caused earthquakes in 18 places


-- Places where explosions have have caused earthquakes:
SELECT place, cause, COUNT(*) as earthquakes_per_place
FROM earthquake_tb
WHERE cause LIKE "explosion%"
GROUP BY place, cause
ORDER BY earthquakes_per_place DESC;
-- explosions have caused earthquakes in three places


-- Places where earthquakes have occured naturally (most natural earthquake prone places):
SELECT place, cause, COUNT(*) as earthquakes_per_place
FROM earthquake_tb
WHERE cause LIKE "earthquake%"
GROUP BY place, cause
ORDER BY earthquakes_per_place DESC;
-- natural earthquakes have occured in 2934 places


/*Create a view from the earthquake table 
add year and month column from the occurred on column.
add magnitude categories from the category column with the categories as:
Great - >= 8.0
Major - between 7.0 and 7.9
Strong - between 6.0 and 6.9
Moderate - between 5.0 and 5.9
Light - between 4.0 and 4.9
Minor - between 3.0 and 3.9
Micro - < 3.0

add depth categories from the depth column with categories as:
Deep - > 300
Intermediate  - > 70 and <= 300
Shallow <= 70
*/

DROP VIEW IF EXISTS earthquake_vw;
CREATE VIEW earthquake_vw AS
SELECT 
    earthquake_id, 
    occurred_on, 
    YEAR(occurred_on) AS year, 
    MONTH(occurred_on) AS month, 
    latitude, 
    longitude, 
    depth, 
    magnitude, 
    calculation_method, 
    network_id, 
    place, 
    cause,
    CASE 
        WHEN magnitude >= 8.0 THEN 'Great'
        WHEN magnitude >= 7.0 THEN 'Major'
        WHEN magnitude >= 6.0 THEN 'Strong'
        WHEN magnitude >= 5.0 THEN 'Moderate'
        WHEN magnitude >= 4.0 THEN 'Light'
        WHEN magnitude >= 3.0 THEN 'Minor'
        ELSE 'Micro'
    END AS magnitude_category,
    CASE
		WHEN depth > 300 THEN 'Deep'
        WHEN depth > 70 THEN 'Intermediate'
        ELSE 'Shallow'
	END AS depth_category
FROM earthquake_tb;

-- Preview the new view
SELECT *
FROM earthquake_vw
LIMIT 5;


-- Analyzing calculation Method
SELECT calculation_method, COUNT(*) AS earthquakes_per_method
FROM earthquake_tb
GROUP BY calculation_method
ORDER BY earthquakes_per_method DESC;
-- 10 distinct calculation methods were used in this dataset with 'mw' being the most popular

-- how are the calculation methods applied across different depth categories and magnitude categories?
SELECT calculation_method, depth_category, COUNT(*) AS methods_per_depth_category, ROUND(COUNT(*) * 100.0 / 23119, 2) AS percentage
FROM earthquake_vw
GROUP BY calculation_method, depth_category
ORDER BY calculation_method, FIELD(depth_category, 'Shallow', 'Intermediate', 'Deep');
-- there is no special skew of calculation method across depth categories.

SELECT calculation_method, magnitude_category, COUNT(*) AS methods_per_magnitude_category, ROUND(COUNT(*) * 100.0 / 23119, 2) AS percentage
FROM earthquake_vw
GROUP BY calculation_method, magnitude_category
ORDER BY calculation_method, FIELD(magnitude_category, 'Moderate', 'Strong', 'Major', 'Great');
-- there is no special skew of calculation method across magnitude categories.


-- Focus on earthquake depths and magnitude
-- Analyzing earthquake depths with categories: shallow <=70, intermediate: >70-300, and deep >300, and the % of each depth category
SELECT 
    depth_category,
    COUNT(*) AS earthquakes_per_depth_category,
    ROUND(COUNT(*) * 100.0 / 23119, 2) AS percentage
FROM earthquake_vw
GROUP BY depth_category;

-- Find these percentages for naturally occuring earthquakes considering total natural earthquakes = 22942
SELECT 
    depth_category,
    COUNT(*) AS earthquakes_per_depth_category,
    ROUND(COUNT(*) * 100.0 / 22942, 2) AS percentage
FROM earthquake_vw
WHERE cause like "earthquake%"
GROUP BY depth_category;
-- 79.69% shallow, 14.45% moderate, 5.87% deep

-- Find these percentages for explosion earthquakes with total earthquakes by explosion as 4
SELECT 
    depth_category,
    COUNT(*) AS earthquakes_per_depth_category,
    ROUND(COUNT(*) * 100.0 / 4, 2) AS percentage
FROM earthquake_vw
WHERE cause like "explosion%"
GROUP BY depth_category;
-- 100% shallow

-- Find these percentages for nuclear explosion earthquakes with total by nuclear explosions as 173
SELECT 
    depth_category,
    COUNT(*) AS earthquakes_per_depth_category,
    ROUND(COUNT(*) * 100.0 / 173, 2) AS percentage
FROM earthquake_vw
WHERE cause like "nuclear%"
GROUP BY depth_category;
-- 100% shallow.

-- distribution of the depth categories across the earthquake causes as percentage of total
SELECT cause, depth_category, COUNT(*) AS earthquakes_per_depth_category, ROUND(COUNT(*) * 100.0 / 23119, 2) AS percentage
FROM earthquake_vw
GROUP BY cause, depth_category;

-- distribution of the depth categories across the magnitude categories.
-- Note that moderate: 5.0-5.9, strong: 6.0-6.9, major: 7.0-7.9, great: >8.0
SELECT magnitude_category, depth_category, COUNT(*) AS depth_category_count, ROUND(COUNT(*) * 100.0 / 23119, 2) AS percentage
FROM earthquake_vw
GROUP BY magnitude_category, depth_category
ORDER BY FIELD(magnitude_category, 'Moderate', 'Strong', 'Major', 'Great'), FIELD(depth_category, 'Shallow', 'Intermediate', 'Deep');


-- Find average depth for each magnitude value.
SELECT magnitude, ROUND(AVG(depth), 2) AS average_depth
FROM earthquake_tb
GROUP BY magnitude
ORDER BY magnitude DESC;
-- the average depth of earthquakes recorded in the dataset is less than 200

-- Look for outliers in the depth column
WITH RankedData AS (
    SELECT depth, ROW_NUMBER() OVER (ORDER BY depth) AS rn, COUNT(*) OVER () AS total_count
    FROM earthquake_tb),
Quartiles AS (
    SELECT
        MIN(CASE WHEN rn = FLOOR(total_count * 0.25) THEN depth END) AS Q1,
        MIN(CASE WHEN rn = CEIL(total_count * 0.75) THEN depth END) AS Q3
    FROM RankedData)
SELECT DISTINCT rd.depth
FROM RankedData rd, Quartiles q
WHERE rd.depth < q.Q1 - 1.5 * (q.Q3 - q.Q1) OR rd.depth > q.Q3 + 1.5 * (q.Q3 - q.Q1);
-- depth values >= 115.5 are outliers.


-- Distribution of earthquakes across the magnitude categories
SELECT magnitude_category, COUNT(*) AS earthquake_per_category
FROM earthquake_vw
GROUP BY magnitude_category;

-- Finding outliers in the magnitude column.
WITH RankedData AS (
    SELECT magnitude, ROW_NUMBER() OVER (ORDER BY magnitude) AS rn, COUNT(*) OVER () AS total_count
    FROM earthquake_tb),
Quartiles AS (
    SELECT
        MIN(CASE WHEN rn = FLOOR(total_count * 0.25) THEN magnitude END) AS Q1,
        MIN(CASE WHEN rn = CEIL(total_count * 0.75) THEN magnitude END) AS Q3
    FROM RankedData)
SELECT DISTINCT rd.magnitude
FROM RankedData rd, Quartiles q
WHERE rd.magnitude < q.Q1 - 1.5 * (q.Q3 - q.Q1) OR rd.magnitude > q.Q3 + 1.5 * (q.Q3 - q.Q1);
-- earthquakes of magnitude 6.7 and above are outliers (the exception and not the rule)


-- Time related analysis with focus on year and month
-- find the number of years covered in our data
SELECT COUNT(DISTINCT year)
FROM earthquake_vw;
-- 50 years are captured in our dataset.

-- Distribution of earthquakes over the years order by year
SELECT year, COUNT(*) AS total_earthquake
FROM earthquake_vw
GROUP BY year
ORDER BY year;

-- Distribution of eathquakes over the years - find the top 5 highest earthquake years.
SELECT year, COUNT(*) AS total_earthquake
FROM earthquake_vw
GROUP BY year
ORDER BY total_earthquake DESC
LIMIT 5;
-- 2011-703, 2007-607, 1995-589, 2004-571, 2010-560

-- find the highest magnitude, depth, timestamp and place for the top 5 highest earthquake years.
SELECT t1.year,
       t1.magnitude AS highest_magnitude,
       t1.depth,
       t1.occurred_on,
       t1.place
FROM earthquake_vw t1
JOIN (
    SELECT year, MAX(magnitude) AS highest_magnitude
    FROM earthquake_vw
    WHERE year IN (
        SELECT y.year
        FROM (
            SELECT year
            FROM earthquake_vw
            GROUP BY year
            ORDER BY COUNT(*) DESC
            LIMIT 5
        ) AS y
    )
    GROUP BY year
) AS sub
ON t1.year = sub.year AND t1.magnitude = sub.highest_magnitude
ORDER BY t1.year;
-- for these 5 years, they all had earthquakes with a magnitude of >= 8 with 2 occuring in 1995
-- the depth for these great earthquakes was shallow (maximum impact with possible aftershocks)

-- did all of these places have aftershocks? check Antofagasta, Chile, Colima Mexico, northern Sumatra, southern Sumatra,offshore Bio-Bio Chile and Honshu Japan.
-- 1995, Antofagasta, Chile
SELECT place, occurred_on,  magnitude
FROM earthquake_vw
WHERE place LIKE "%Antofagasta, Chile%" AND year = 1995
ORDER BY occurred_on;

-- See the distribution of earthquakes in Antofagasta, Chile over the years:
SELECT year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%Antofagasta, Chile%"
GROUP BY year
ORDER BY earthquakes_per_year DESC;
-- Antofagasta Chile is an earthquake hotspot with 17 occuring there in 1995
-- the magnitude 8 earthquake led to 12 extra aftershocks in the region within 30 days - aftershocks

-- 1995, Colima, Mexico
SELECT place, occurred_on,  magnitude
FROM earthquake_vw
WHERE place LIKE "%Colima, Mexico%" AND year = 1995
ORDER BY occurred_on;

-- See the distribution of earthquakes in Colima Mexico over the years:
SELECT year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%Colima, Mexico%"
GROUP BY year
ORDER BY earthquakes_per_year DESC;
-- only 3 earthquakes in year 1995
-- Earthquakes occur here often but not as much as the other location.

-- 1995 high count wasn't entirely only because of these magnitude 8 earthquakes.

-- 2007, Southern Sumatra 
SELECT place, occurred_on,  magnitude
FROM earthquake_vw
WHERE place LIKE "%southern Sumatra%" AND year = 2007
ORDER BY occurred_on;

-- See the distribution of earthquakes in Colima Mexico over the years:
SELECT year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%southern Sumatra%"
GROUP BY year
ORDER BY earthquakes_per_year DESC;

-- great earthquake was impactful but not enough to be the sole cause of spike in yearly earthquake count.

-- 2010 Bio-Bio Chile
SELECT place, occurred_on,  magnitude
FROM earthquake_vw
WHERE place LIKE "%Bio-Bio, Chile%" AND year = 2010
ORDER BY occurred_on;

-- See the distribution of earthquakes in Colima Mexico over the years:
SELECT year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%Bio-Bio, Chile%"
GROUP BY year
ORDER BY earthquakes_per_year DESC;

-- the spike after this earthquake can be said to have contributed a lot to the spike. 

-- To find the place(s) where the most devastating earthquakes happened
SELECT place, magnitude, occurred_on
FROM earthquake_vw
WHERE magnitude = 
(SELECT MAX(magnitude) FROM earthquake_vw);
-- The two most devastating earthquakes happened in Honshu, Japan and nothern Sumatra.


-- Find out extra details about Nothern Sumatra where on of the 9.1 magnitude earthquakes happened
SELECT place, occurred_on,  magnitude
FROM earthquake_vw
WHERE place LIKE "%northern Sumatra%" AND year = 2004
ORDER BY occurred_on;
-- The 9.1 earthquake was the first one to occur in 2004 followed by  26 aftershocks.

-- See the distribution of earthquakes in nothern Sumatra over the years:
SELECT place, year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%northern Sumatra%"
GROUP BY place, year
ORDER BY year;
-- The distribution shows that though the place is an earthquake hotspot, 
-- there was an increase in number of earthquakes in 2004 and 2005,
-- implying that they were most likely aftershocks of the 9.1 magnitude earthquake.


-- Find out extra details about Honshu, Japan where on of the 9.1 magnitude earthquakes happened
SELECT place, occurred_on, magnitude
FROM earthquake_vw
WHERE place LIKE "%Honshu, Japan" AND year = 2011
ORDER BY occurred_on;
-- 10 earthquakes had happened before the magnitude 9.1 earthquake - foreshocks
-- a further 250 earthquakes occured after the 9.1 event, most of which could be considered aftershocks.
-- This suggests that Honshu, Japan is an earthquake hotspot.

--  See the distribution of earthquakes in Honshu, Japan over the years:
SELECT place, year, COUNT(*) AS earthquakes_per_year
FROM earthquake_vw
WHERE place LIKE "%Honshu, Japan%"
GROUP BY place, year
ORDER BY year;
-- Though this place is an earthquake hotspot, the massive spike in number of earthquakes
-- in 2011 suggests that there were foreshocks and afteshocks of the 9.1 magnitude earthquake.
-- This magnitude 9.1 earthquake caused the massive spike in earthquakes for 2011
-- This particular earthquake is the reason for the huge spike in earthquakes in 2011.


-- Is there an earthquake season?
-- See Distribution of earthquakes across the months:
SELECT month, COUNT(*) AS earthquake_per_month
FROM earthquake_vw
GROUP BY month
ORDER BY month;
-- the spike for March is caused by the Honshu, Japan event in March 2011 which , so there is no earthquake season.


-- Export the view as a csv file for further analysis using charts using the export function

