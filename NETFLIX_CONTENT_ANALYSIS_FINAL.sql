/*
===============================================================================
Project: Netflix Content Analysis
Author: Jessica Nwobodo
Database: MySQL
Dataset: Netflix Titles (Kaggle)

Description:
This project analyzes the Netflix catalog using SQL. It covers data-quality
checks, descriptive analysis, business questions, CTEs, and window functions.

Important dataset limitation:
Some columns, including country, director, cast, and listed_in, may contain
multiple comma-separated values. Therefore, simple GROUP BY results treat each
full combination as one value.
===============================================================================
*/

USE netflix_project;

-- 1. DATA QUALITY CHECKS
-- Count records with missing director information.
SELECT
    COUNT(*) AS missing_directors
FROM netflix_titles
WHERE director IS NULL
   OR TRIM(director) = '';

-- Count records with missing country information.
SELECT
    COUNT(*) AS missing_countries
FROM netflix_titles
WHERE country IS NULL
   OR TRIM(country) = '';

-- Count records with missing rating information.
SELECT
    COUNT(*) AS missing_ratings
FROM netflix_titles
WHERE rating IS NULL
   OR TRIM(rating) = '';

-- Review the available content types.
SELECT DISTINCT
    type
FROM netflix_titles
ORDER BY type;


-- 2. CATALOG OVERVIEW
-- Business Question 1:
-- How many titles are included in the dataset?
SELECT
    COUNT(*) AS total_titles
FROM netflix_titles;

-- Finding: The dataset contains 8,807 titles.


-- Business Question 2:
-- How many Movies and TV Shows are available?
SELECT
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY type
ORDER BY total_titles DESC;

-- Finding:
-- Movie: 6,131
-- TV Show: 2,676
-- Verify these values against your imported table before publishing.


-- Business Question 3:
-- What are the most common content ratings?
SELECT
    rating,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE rating IS NOT NULL
  AND TRIM(rating) <> ''
GROUP BY rating
ORDER BY total_titles DESC;

-- Finding:
-- TV-MA and TV-14 are the two most common ratings in the dataset.


-- 3. COUNTRY ANALYSIS
-- Business Question 4:
-- Which country values appear most frequently?
SELECT
    country,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
  AND TRIM(country) <> ''
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10;

-- Note:
-- Rows containing multiple countries are treated as one country combination.


-- Business Question 5:
-- How many titles are associated with Nigeria?
SELECT
    COUNT(*) AS nigerian_titles
FROM netflix_titles
WHERE country LIKE '%Nigeria%';

-- Display the Nigerian titles.
SELECT
    show_id,
    title,
    type,
    release_year,
    rating
FROM netflix_titles
WHERE country LIKE '%Nigeria%'
ORDER BY release_year DESC, title;


-- 4. RELEASE-YEAR ANALYSIS
-- Business Question 6:
-- How many titles were released in each year?
SELECT
    release_year,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year
ORDER BY total_titles DESC, release_year DESC;

-- Finding:
-- 2018 has the highest number of releases in the dataset.


-- Business Question 7:
-- How many Movies and TV Shows were released each year?
SELECT
    release_year,
    type,
    COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY release_year, type
ORDER BY release_year DESC, type;


-- 5. NETFLIX ADDITION TRENDS
-- Business Question 8:
-- In which year did Netflix add the most titles?
SELECT
    YEAR(date_added_clean) AS year_added,
    COUNT(*) AS total_added
FROM netflix_titles
WHERE date_added_clean IS NOT NULL
GROUP BY YEAR(date_added_clean)
ORDER BY total_added DESC, year_added DESC;

-- Finding:
-- 2019 has the highest number of additions in this dataset.


-- Business Question 9:
-- Which calendar month has the highest number of additions?
SELECT
    MONTH(date_added_clean) AS month_number,
    MONTHNAME(date_added_clean) AS month_name,
    COUNT(*) AS total_added
FROM netflix_titles
WHERE date_added_clean IS NOT NULL
GROUP BY
    MONTH(date_added_clean),
    MONTHNAME(date_added_clean)
ORDER BY total_added DESC;

-- Finding:
-- July has the highest number of additions.


-- 6. DIRECTOR ANALYSIS
-- Business Question 10:
-- Which director values have the most titles?
SELECT
    director,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE director IS NOT NULL
  AND TRIM(director) <> ''
GROUP BY director
ORDER BY total_titles DESC
LIMIT 10;

-- Finding:
-- Rajiv Chilaka appears among the directors with the most titles.
-- Multiple-director combinations are treated as one value.


-- 7. GENRE ANALYSIS
-- What are the most common genre combinations?
SELECT
    listed_in,
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE listed_in IS NOT NULL
  AND TRIM(listed_in) <> ''
GROUP BY listed_in
ORDER BY total_titles DESC
LIMIT 10;

-- Finding:
-- "Dramas, International Movies" is one of the most common combinations.


-- How many documentary titles are available?
SELECT
    COUNT(*) AS documentary_titles
FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%';


-- How many comedy titles are available?
SELECT
    COUNT(*) AS comedy_titles
FROM netflix_titles
WHERE listed_in LIKE '%Comedies%';


-- Which release years have the most documentaries?
SELECT
    release_year,
    COUNT(*) AS documentary_count
FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%'
GROUP BY release_year
ORDER BY documentary_count DESC, release_year DESC
LIMIT 10;


-- 8. MOVIE-DURATION ANALYSIS
-- What is the average duration of a Netflix movie?
SELECT
    ROUND(
        AVG(
            CAST(REPLACE(duration, ' min', '') AS UNSIGNED)
        ),
        2
    ) AS average_movie_duration_minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND duration LIKE '%min';

-- Finding:
-- The average movie duration is approximately 99.58 minutes.


-- What are the ten longest movies?
SELECT
    title,
    CAST(REPLACE(duration, ' min', '') AS UNSIGNED) AS duration_minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND duration LIKE '%min'
ORDER BY duration_minutes DESC
LIMIT 10;


-- 9. CTE AND WINDOW-FUNCTION ANALYSIS
-- Rank release years by the number of titles released.
WITH yearly_titles AS (
    SELECT
        release_year,
        COUNT(*) AS total_titles
    FROM netflix_titles
    GROUP BY release_year
)
SELECT
    release_year,
    total_titles,
    RANK() OVER (
        ORDER BY total_titles DESC
    ) AS release_year_rank
FROM yearly_titles
ORDER BY release_year_rank, release_year DESC;

-- Finding:
-- 2018 ranks first based on the number of titles released.


-- Rank ratings separately within Movies and TV Shows.
WITH rating_counts AS (
    SELECT
        type,
        rating,
        COUNT(*) AS total_titles
    FROM netflix_titles
    WHERE rating IS NOT NULL
      AND TRIM(rating) <> ''
    GROUP BY type, rating
)
SELECT
    type,
    rating,
    total_titles,
    DENSE_RANK() OVER (
        PARTITION BY type
        ORDER BY total_titles DESC
    ) AS rating_rank
FROM rating_counts
ORDER BY type, rating_rank, rating;


-- 10. SUMMARY
/*
Key findings:

1. The Netflix dataset contains 8,807 titles.
2. Movies make up the majority of the catalog.
3. TV-MA and TV-14 are the most common ratings.
4. The United States is the most frequently listed country value.
5. Nigeria is represented in a smaller portion of the catalog.
6. The highest number of releases occurred in 2018.
7. Netflix added the most titles in 2019.
8. July has the highest number of additions by calendar month.
9. Rajiv Chilaka appears among the directors with the most titles.
10. The average movie duration is approximately 99.58 minutes.

*/
