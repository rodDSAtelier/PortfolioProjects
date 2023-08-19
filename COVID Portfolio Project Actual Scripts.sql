SELECT * 
FROM covid_schema.Coviddeaths
where continent IS NOT NULL;
/**
Looking at total cases vs total deaths
shows likelihood of dying if you contact covid in your country
**/
select Location, date, total_cases, total_deaths,
(total_deaths::float/total_cases::float)*100 as death_percent
from Portfolioproject.covid_schema.CovidDeaths 
where total_deaths IS NOT NULL 
--and location = 'United States'
and location = 'Nigeria'
order by 1,2;

/**
Looking at total cases vs population
shows what % of population got covid
**/
select Location, date, total_cases, population,(total_deaths::float/population::float)*100 as death_percent
from Portfolioproject.covid_schema.CovidDeaths 
where total_deaths IS NOT NULL 
--and location = 'United States'
and location = 'Nigeria'
order by 1,2;


/**
 Looking at Total Cases vs Population
 Shows what % of population got Covid
**/
SELECT location, population, 
MAX(total_cases) as highest_infection_count, 
MAX((total_cases::float/population::float))*100 as percent_population_infected
FROM Portfolioproject.covid_schema.CovidDeaths 
WHERE total_deaths IS NOT NULL and population IS NOT NULL
--and location = 'United States'
--AND location = 'Nigeria'
GROUP BY Location, Population
order by Location, percent_population_infected desc;

/**
looking at countries with highest death count per population
**/
SELECT location, MAX(total_deaths) as total_death_count
FROM Portfolioproject.covid_schema.CovidDeaths
WHERE continent IS NOT NULL

GROUP BY Location
order by total_death_count  desc;

--break down by continent

/**
looking at continents with highest death count per population
**/
SELECT continent, MAX(total_deaths) as total_death_count
FROM Portfolioproject.covid_schema.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
order by total_death_count desc;

--GLOBAL NUMBERS
SELECT location, date, total_cases, total_deaths, 
((total_deaths::float/total_cases::float))*100 as death_percentage
FROM covid_schema.coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;
 
SELECT date, SUM(new_cases)--, total_deaths, ((total_deaths::float/total_cases::float))*100 as death_percentage
FROM covid_schema.coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;


SELECT date, SUM(new_cases), SUM(new_deaths)--, total_deaths, ((total_deaths::float/total_cases::float))*100 as death_percentage
FROM covid_schema.coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths)::float)/(SUM(new_cases)::float)*100 as death_percent
FROM covid_schema.coviddeaths
WHERE continent IS NOT NULL and new_cases != 0
GROUP BY date
ORDER BY 1, 2;


SELECT 
	--date, 
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths)::float)/(SUM(new_cases)::float)*100 as death_percent
FROM covid_schema.coviddeaths
--WHERE continent IS NOT NULL and new_cases != 0
--GROUP BY date
ORDER BY 1, 2;

--Looking at Total Population vs vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as rolling_pple_vac
FROM covid_schema.coviddeaths cd 
JOIN covid_schema.covidvaccinations cv
	ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
ORDER BY 2,3 ;


SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as rolling_pple_vac
--,rolling_pple_vac/cd.population
FROM covid_schema.coviddeaths cd 
JOIN covid_schema.covidvaccinations cv
	ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
ORDER BY 2,3 ;

/**Use CTE statement;
A common table expression is a temporary result set which you can reference within another SQL statement 
including SELECT, INSERT, UPDATE or DELETE.
Common Table Expressions are temporary in the sense that they only exist during the execution of the query.

The following shows the syntax of creating a CTE:
WITH cte_name (column_list) AS (
    CTE_query_definition 
)**/
WITH pop_vs_vacc_CTE (continent, location, date, population, new_vaccinations, rolling_pple_vac) AS (
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_pple_vac
	FROM covid_schema.coviddeaths cd 
	JOIN covid_schema.covidvaccinations cv
		ON cd.location = cv.location AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL 
	ORDER BY 2,3 
)
SELECT *, 100*(rolling_pple_vac::float/population::float) as percent
FROM pop_vs_vacc_CTE;

/**TEMP TABLE

**/
DROP TABLE if exists percent_population_vaccinated_temp;
CREATE TEMPORARY TABLE percent_population_vaccinated_temp
(
 continent                           VARCHAR(50),
 location                            VARCHAR(50),
 date		                         date,
 population                          BIGINT,
 new_vaccinations                    INT,
 rolling_pple_vac					 numeric
 );
 
INSERT INTO percent_population_vaccinated_temp
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_pple_vac
	FROM covid_schema.coviddeaths cd 
	JOIN covid_schema.covidvaccinations cv
		ON cd.location = cv.location AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL 
	ORDER BY 2,3 ; 

SELECT *,
		100*(rolling_pple_vac::float/population::float) as percent
FROM percent_population_vaccinated_temp;


-- creating view to store data for later visualizations
DROP VIEW if exists covid_schema.percent_population_vaccinated_view;

CREATE VIEW covid_schema.percent_population_vaccinated_view AS
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS rolling_pple_vac
	FROM covid_schema.coviddeaths cd 
	JOIN covid_schema.covidvaccinations cv
		ON cd.location = cv.location AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL 
	ORDER BY 2,3 ;

SELECT * FROM covid_schema.percent_population_vaccinated_view;

--GLOBAL NUMBERS
/**
SELECT 
SUM(new_cases) AS total_cases
, SUM(new_deaths) AS total_deaths,
--100*((total_deaths::float)/(total_cases::float)) as death_percent
(total_deaths/total_cases) as death_percent

FROM Portfolioproject.covid_schema.CovidDeaths 
WHERE continent IS NOT NULL
order by 1,2;
**/










