-- ============================================================
-- PROJECT: US Household Income
-- Analysis of household income across the United States
-- 
-- This script performs two main stages:
--   1) DATA CLEANING  — Data cleansing and standardization
--   2) EDA            — Exploratory Data Analysis
--
-- Tables used:
--   • us_household_income            → geographic data (state, county, city, area)
--   • us_household_income_statistics → income statistics (mean, median, standard deviation)
-- ============================================================

USE us_project;

-- ============================================================
-- ▐▐  PART 1 — DATA CLEANING
-- ============================================================

-- Initial overview of raw data from both tables
-- to understand the structure and identify potential issues
SELECT * FROM us_project.us_household_income;

SELECT * FROM us_project.us_household_income_statistics;

-- --------------------------------------------------------------
-- 1.1 COLUMN NAME FIX (UTF-8 BOM)
-- When importing the CSV, the 'id' column got invisible characters
-- from the BOM (Byte Order Mark) prepended: ï»¿id
-- Renaming it to a clean 'id' so the JOIN works correctly later
-- --------------------------------------------------------------
ALTER TABLE us_household_income_statistics RENAME COLUMN `ï»¿id` TO `id`;

-- --------------------------------------------------------------
-- 1.2 IDENTIFYING AND REMOVING DUPLICATES
-- The 'id' field should be unique per record.
-- First we identify which IDs appear more than once.
-- --------------------------------------------------------------

-- Step 1: Count how many times each ID appears
-- IDs with total > 1 are duplicates
SELECT 
    id, COUNT(id) AS total
FROM
    us_project.us_household_income
GROUP BY id
HAVING COUNT(id) > 1;

-- Step 2: Use ROW_NUMBER() to number each occurrence of an ID
-- The first occurrence gets row_num = 1, the rest get > 1
-- This allows us to pinpoint exactly which rows are the "extras"
SELECT *
FROM (
    SELECT row_id,
           id,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS row_num
    FROM us_project.us_household_income
) duplicates
WHERE row_num > 1;

-- Step 3: Delete the duplicates, keeping only the first occurrence
-- We use row_id (unique row identifier) to ensure
-- only the extra rows are removed
DELETE FROM us_household_income
WHERE row_id IN (
SELECT row_id
FROM (
    SELECT row_id,
           id,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS row_num
    FROM us_project.us_household_income
) duplicates
WHERE row_num > 1);

-- --------------------------------------------------------------
-- 1.3 STANDARDIZING STATE NAMES
-- By listing distinct states, we found typos
-- and capitalization inconsistencies that need to be fixed
-- --------------------------------------------------------------

-- List all states to visually inspect for errors
SELECT DISTINCT
    State_Name
FROM
    us_project.us_household_income
ORDER BY State_Name;

-- Fix: 'georia' is misspelled → should be 'Georgia'
UPDATE us_project.us_household_income 
SET 
    State_Name = 'Georgia'
WHERE
    State_Name = 'georia';
    
-- Fix: 'alabama' in lowercase → standardize to 'Alabama'
UPDATE us_household_income 
SET 
    State_Name = 'Alabama'
WHERE
    State_Name = 'alabama';

-- --------------------------------------------------------------
-- 1.4 FIXING INCORRECT VALUES IN THE 'Place' COLUMN
-- We checked Autauga County records and identified
-- that the city 'Vinemont' has the wrong Place value
-- --------------------------------------------------------------
    
-- Inspect Autauga County records
SELECT 
    *
FROM
    us_household_income
WHERE
    County = 'Autauga County'
ORDER BY 1;

-- Fix the Place to 'Autaugaville' where the city was listed as 'Vinemont'
UPDATE us_household_income 
SET 
    Place = 'Autaugaville'
WHERE
    County = 'Autauga County'
        AND City = 'Vinemont';

-- --------------------------------------------------------------
-- 1.5 STANDARDIZING THE 'Type' COLUMN (Area Type)
-- We check the count per type to find inconsistencies
-- --------------------------------------------------------------
        
-- Count records per area type to identify duplicate categories
SELECT 
    Type, COUNT(Type) AS total
FROM
    us_project.us_household_income
GROUP BY Type;

-- Fix: 'Boroughs' (plural) should be 'Borough' (singular)
-- to maintain consistency with the other records
UPDATE us_household_income 
SET 
    Type = 'Borough'
WHERE
    Type = 'Boroughs';

-- --------------------------------------------------------------
-- 1.6 CHECKING FOR NULL/ZERO VALUES IN ALand AND AWater
-- ALand (land area) and AWater (water area) should not both
-- be zero — that would mean a record with no valid location
-- --------------------------------------------------------------
    
-- Check records where AWater is zero, empty, or null
SELECT 
    ALand, AWater
FROM
    us_project.us_household_income
WHERE
    AWater = 0 OR AWater = ''
        OR AWater IS NULL;

-- Check records where ALand is zero, empty, or null
-- (more critical, since every location should have land area)
SELECT 
    ALand, AWater
FROM
    us_project.us_household_income
WHERE
    ALand = 0 OR ALand = '' OR ALand IS NULL;


-- ============================================================
-- ▐▐  PART 2 — EDA (Exploratory Data Analysis)
-- ============================================================

-- --------------------------------------------------------------
-- 2.1 GEOGRAPHIC DATA OVERVIEW
-- Basic query to view state, county, city, and area data
-- --------------------------------------------------------------
    
SELECT 
    State_Name, County, City, ALand, AWater
FROM
    us_household_income;

-- --------------------------------------------------------------
-- 2.2 TOP 10 STATES BY LAND AND WATER AREA
-- Sums up land area (ALand) and water area (AWater) per state
-- to identify the largest states by territorial extent
-- --------------------------------------------------------------

SELECT 
    State_Name,
    SUM(ALand) AS total_land,
    SUM(AWater) AS total_water
FROM
    us_project.us_household_income
GROUP BY State_Name
ORDER BY total_land DESC
LIMIT 10;

-- --------------------------------------------------------------
-- 2.3 JOINING TABLES — Combining Geography + Income
-- The join key is the 'id' field (census tract ID)
-- --------------------------------------------------------------

-- INNER JOIN: returns only records that exist in BOTH tables
SELECT 
    *
FROM
    us_project.us_household_income u
        JOIN
    us_project.us_household_income_statistics us ON u.id = us.id;
    
-- RIGHT JOIN: identifies records in the statistics table
-- that have NO match in the geographic table
-- (useful for detecting orphaned data)
SELECT 
    *
FROM
    us_project.us_household_income u
        RIGHT JOIN
    us_project.us_household_income_statistics us ON u.id = us.id
WHERE u.id IS NULL;

-- --------------------------------------------------------------
-- 2.4 FILTERING RECORDS WITH VALID INCOME
-- Records with Mean = 0 are discarded as they indicate
-- missing or uncollected census data
-- --------------------------------------------------------------

-- View all records with valid income (Mean ≠ 0)
SELECT 
    *
FROM
    us_project.us_household_income u
        JOIN
    us_project.us_household_income_statistics us ON u.id = us.id
WHERE Mean <> 0;

-- Select specific columns for analysis:
-- State, County, Area Type, Primary classification, Mean and Median Income
SELECT u.State_Name, 
       u.County, 
       u.Type, 
       u.`Primary`, 
       us.Mean, 
       us.Median
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE us.Mean <> 0;

-- --------------------------------------------------------------
-- 2.5 TOP 10 STATES BY HIGHEST AVERAGE INCOME
-- Calculates the average income (Mean and Median) per state
-- to identify which states have the wealthiest population
-- --------------------------------------------------------------

SELECT 
    u.State_Name,
    ROUND(AVG(us.Mean), 1),
    ROUND(AVG(us.Median), 1)
FROM
    us_household_income u
        INNER JOIN
    us_household_income_statistics us ON u.id = us.id
WHERE
    us.Mean <> 0
GROUP BY u.State_Name
ORDER BY 2 DESC
LIMIT 10;

-- --------------------------------------------------------------
-- 2.6 AVERAGE AND MEDIAN INCOME BY AREA TYPE
-- Compares income across different location types
-- (City, Town, Borough, CDP, Track, etc.)
-- HAVING > 100 filter: only considers types with a relevant
-- sample size to avoid statistical distortions
-- --------------------------------------------------------------

SELECT 
    u.Type,
    COUNT(u.Type),
    ROUND(AVG(us.Mean), 1),
    ROUND(AVG(us.Median), 1)
FROM
    us_household_income u
        INNER JOIN
    us_household_income_statistics us ON u.id = us.id
WHERE
    us.Mean <> 0
GROUP BY 1
HAVING COUNT(u.Type) > 100
ORDER BY 4 DESC;

-- Spot check: what are the 'Community' type locations?
-- (possible outlier identified in the previous query)
SELECT 
    *
FROM
    us_household_income
WHERE
    Type = 'Community';

-- --------------------------------------------------------------
-- 2.7 INCOME RANKING BY CITY
-- Calculates the average mean and median income per State + City
-- Ordered by highest mean income to identify
-- the wealthiest cities in the United States
-- --------------------------------------------------------------
    
SELECT 
    u.State_Name,
    u.City,
    ROUND(AVG(us.Mean), 1) AS avg_mean_income,
    ROUND(AVG(us.Median), 1) AS avg_median_income
FROM
    us_household_income u
        JOIN
    us_household_income_statistics us ON u.id = us.id
GROUP BY u.State_Name , u.City
ORDER BY 3 DESC;
