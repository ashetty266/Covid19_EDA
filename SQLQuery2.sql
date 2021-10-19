/**COVID-19 DATA EXPLORATION PROJECT

 Skills used: Aggregate Functions, Converting Data Types, Joins, CTE's, Creating Views, Windows Functions
 **/

/**EXPLORING COVID DEATHS TABLE**/ 

SELECT continent,location, date, population, total_cases, new_cases, total_deaths
FROM Covid19..deaths
WHERE continent is NOT NULL
ORDER BY location, date;

-- Just for the next two queries I'll be looking at Canada (that's where I reside), India and Qatar (thats where my family resides).

--Likelihood of death if you contract Covid19
SELECT continent,location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Mortality_Rate
FROM Covid19..deaths
WHERE continent IS NOT NULL AND location IN ('Canada','India','Qatar')
ORDER BY location, date DESC;

-- Looking at Total Cases vs. Population (Infection Rate)
SELECT continent,location, date, population, total_cases, ROUND((total_cases/population)*100,2) AS Infection_rate
FROM Covid19..deaths
WHERE continent IS NOT NULL AND location in ('India', 'Canada','Qatar')
ORDER BY location, date DESC;

--Countries with Highest Infection Rate Compared to population
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, ROUND(MAX((total_cases/population)*100),2) AS Highest_Infection_rate
FROM Covid19..deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Highest_Infection_rate DESC;

--Countries with Highest Death Rate vs. Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS Highest_Death_Count, MAX((total_deaths/population)*100) AS Highest_Mortality_Rate
FROM Covid19..deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC;

/**DATA EXPLORATION BY CONTINENT**/

--Countries with Highest Infection Rate Compared to population
--- Filtering by continent being null because when that condition holds the location field has the appropriate continents and the numbers are coherent
--- Removing European Union because it is part of Europe
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, ROUND(MAX((total_cases/population)*100),2) AS Highest_Infection_rate
FROM Covid19..deaths
WHERE location NOT IN ('World', 'International', 'European Union') AND
continent IS NULL 
GROUP BY location, population
ORDER BY Highest_Infection_rate DESC, Highest_Infection_Count DESC;

--Continents with Highest Death Rate vs. Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count, MAX((total_deaths/population)*100) AS Highest_Mortality_Rate
FROM Covid19..deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Highest_Mortality_Rate DESC, Total_Death_Count DESC;

--GLOBAL NUMBERS BY DAY
SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Mortality_Rate
FROM Covid19..deaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1;

--GLOBAL NUMBERS AS OF OCTOBER 4,2021 (Creating view for Tableau Viz)
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Mortality_Rate
FROM Covid19..deaths
WHERE continent IS NOT NULL ;


/** EXPLORING COVID VACCINATIONS TABLE**/

-- Using CTE to find out percentage of population that has recieved at least one Covid Vaccine 

WITH Vax_vs_Population (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated) AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.Location ORDER BY d.location, d.Date) as Rolling_People_Vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
)
Select *, ROUND((Rolling_People_Vaccinated/Population)*100,3) AS Rolling_People_Vaccinated_Percent
From Vax_vs_Population;

-- Exploraing total doses administered and fully vaccinated population
SELECT d.location, d.date, d.population, 
COALESCE(SUM(CAST(v.total_vaccinations AS numeric)),0) AS total_vaccinations, 
COALESCE(SUM(CAST(v.people_fully_vaccinated AS numeric)),0) AS fully_Vaccinated_population, 
COALESCE(SUM(CAST(people_fully_vaccinated AS numeric))/population,0) AS Percentage_Population_fully_vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location, d.date, d.population;


/** CREATING VIEWS FOR DATA VISUALIZATION IN TABLEAU**/

--1. Global Numbers as of Oct 4, 2021. (Total Cases, Total Deaths, Mortality Rate, Total Vaccinations, Fully Vaccinated)

CREATE VIEW Global_Numbers AS
SELECT d.location, d.population, 
SUM(d.new_cases) AS Total_Cases, 
SUM(CAST(d.new_deaths AS INT)) AS Total_Deaths, 
ROUND(SUM(CAST(d.new_deaths AS INT))/SUM(d.new_cases)*100, 5) AS Mortality_Rate,
COALESCE(MAX(CAST(v.total_vaccinations AS numeric)),0) AS total_vaccinations, 
COALESCE(MAX(CAST(v.people_fully_vaccinated AS numeric)),0) AS fully_Vaccinated_population, 
COALESCE(MAX(CAST(people_fully_vaccinated AS numeric)),0)/d.population AS Percentage_Population_fully_vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NULL AND
d.location = 'World'
GROUP BY d.location, d.population;

--2. 
CREATE VIEW Global_Numbers_Countries AS
SELECT d.location, d.population, 
SUM(d.new_cases) AS Total_Cases, 
SUM(CAST(d.new_deaths AS INT)) AS Total_Deaths, 
ROUND(SUM(CAST(d.new_deaths AS INT))/SUM(d.new_cases)*100, 5) AS Mortality_Rate,
COALESCE(MAX(CAST(v.total_vaccinations AS numeric)),0) AS total_vaccinations, 
COALESCE(MAX(CAST(v.people_fully_vaccinated AS numeric)),0) AS fully_Vaccinated_population, 
COALESCE(MAX(CAST(people_fully_vaccinated AS numeric)),0)/d.population AS Percentage_Population_fully_vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location, d.population;

--2. Global Numbers by continents as of Oct 4, 2021. (Total Deaths & Death Percentage)
CREATE VIEW Global_Numbers_Continents AS
SELECT location, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, ROUND(SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100,5) AS Mortality_Rate
FROM Covid19..deaths
WHERE location NOT IN ('World', 'International', 'European Union') AND
continent IS NULL 
GROUP BY location;

--3. Continents with Highest Infection Rate Compared to population
--- Replaced null values with zero 
CREATE VIEW Infection_Rate_Continents AS 
SELECT location, population, COALESCE(MAX(total_cases),0) AS Highest_Infection_Count, COALESCE(ROUND(MAX((total_cases/population)*100),5),0) AS Infection_rate
FROM Covid19..deaths
WHERE location NOT IN ('World', 'International', 'European Union') AND
continent IS NULL 
GROUP BY location, population;


--3. Countries with highest infection rate compared to population
--- Replaced null values with zeros
CREATE VIEW Infection_Rate_Countries AS
SELECT location, population, COALESCE(MAX(total_cases),0) AS Highest_Infection_Count, COALESCE(ROUND(MAX((total_cases/population)*100),5),0) AS Infection_rate
FROM Covid19..deaths
WHERE continent IS NOT NULL 
GROUP BY location, population;


-- 4. Infection rate of countries over time
--- Replace null values with zeros
CREATE VIEW Infection_Rate_CountriesvsTime AS
SELECT Location, Population,date, COALESCE(MAX(total_cases),0) as HighestInfectionCount, COALESCE(ROUND(MAX((total_cases/population)*100),5),0) as Infection_rate
FROM Covid19..deaths
WHERE continent IS NOT NULL 
GROUP BY date, Location, Population

--5. Percentage of population that is Vaccinated with atleast 1 dose
--- Replace null values with zeros
CREATE VIEW Rolling_Population_Vaccinated AS
WITH Vax_vs_Population (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated) AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.Location ORDER BY d.location, d.Date) as Rolling_People_Vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
)
Select Continent, Location, Date, Population, COALESCE(New_Vaccinations,0) AS New_Vaccinations, COALESCE(Rolling_People_Vaccinated,0) AS Rolling_People_Vaccinated, COALESCE(ROUND((Rolling_People_Vaccinated/Population)*100,5),0) AS Rolling_People_Vaccinated_Percent
From Vax_vs_Population;

--6. Exploraing total doses administered and fully vaccinated population
CREATE VIEW Doses_Vaccinations_Countries AS
SELECT d.location, d.date, d.population, 
COALESCE(SUM(CAST(v.total_vaccinations AS numeric)),0) AS total_vaccinations, 
COALESCE(SUM(CAST(v.people_fully_vaccinated AS numeric)),0) AS fully_Vaccinated_population, 
COALESCE(SUM(CAST(people_fully_vaccinated AS numeric))/population,0) AS Percentage_Population_fully_vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location, d.date, d.population;

--7. Creating Views for Correlation Plots

CREATE VIEW Correlation_Data AS
SELECT d.location, d.population, v.population_density, v.handwashing_facilities, 
v.gdp_per_capita, v.hospital_beds_per_thousand, v.stringency_index,
COALESCE(MAX(d.total_cases),0) AS Highest_Infection_Count, 
COALESCE(ROUND(MAX((d.total_cases/d.population)*100),5),0) AS Infection_rate,
COALESCE(SUM(CAST(v.total_vaccinations AS numeric)),0) AS total_vaccinations, 
COALESCE(SUM(CAST(v.people_fully_vaccinated AS numeric)),0) AS fully_Vaccinated_population, 
COALESCE(SUM(CAST(v.people_fully_vaccinated AS numeric))/d.population,0) AS Percentage_Population_fully_vaccinated
FROM Covid19..deaths d
JOIN Covid19..vax v ON 
d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location, d.population, v.population_density, v.handwashing_facilities, 
v.gdp_per_capita, v.hospital_beds_per_thousand, v.stringency_index;
