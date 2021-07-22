/* 

Data Exploration on Covid 19 Dataset

The complete downloaded dataset file was split into two parts
By doing that I can have two tables and Join them using date and location columns.

*/
-----------------------------------------------------------

---- GLOBAL REPORTS ----

-- Total cases per country, but only those with more than 1000 cases
SELECT location, MAX(total_cases) as TotalCases
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_cases) > 1000
ORDER BY TotalCases DESC


-- Total deaths per country
-- We need to convert 'total_death' column because we need it to be int
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeaths
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC


-- Calculating the death ratio as deaths/cases by country
SELECT location, MAX(total_cases) as TotalCases, MAX(CAST(total_deaths as int)) as TotalDeaths,
(MAX(CAST(total_deaths as int)) / MAX(total_cases)) *100 as DeathRatio
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
	AND Total_cases > 1000
GROUP BY location
ORDER BY DeathRatio DESC


-- Total Global Numbers for each day since 01/01/20
SELECT date, SUM(new_cases) as TotalCases, SUM(CONVERT(int,new_deaths)) as TotalDeaths
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total Global Numbers in one row
SELECT SUM(new_cases) as TotalCases, SUM(CONVERT(int,new_deaths)) as TotalDeaths,
(SUM(CONVERT(int,new_deaths)) / SUM(new_cases))*100 as DeathPercentage
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL


-- Total Cases versus population on each country
-- Shows daily percentage of population infected
SELECT location, date, population, total_cases, 
(total_cases/population)*100 as PercentPopInfected
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Countries with highest infection rates compared to population
SELECT location, MAX(total_cases) as TotalCases, MAX(Population) as Population,
(MAX(total_cases)/MAX(Population))*100 as InfectionRate
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC


-- Countries with highest death count
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeaths
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC


-- Death/population ratio for each country
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeaths, 
MAX(Population) as Population,
(MAX(CAST(total_deaths as int))/MAX(Population))*100 as DeathPopRate
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC


-- Death count and population for each continent
SELECT continent, SUM(CAST(new_deaths as int)) as TotalDeaths,
MAX(Population) as TotalPopulation
FROM CovidPortProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC


-- Let's check the vaccination table and do some joins
-- As I don't have Primary and Foreign keys I'll do Joins based on location+date
-- In both tables each row  has a unique location+date combination

-- Total amount of people vaccinated on each country
SELECT deaths.location, MAX(CAST(vacc.people_vaccinated as int)) as PeopleVaccinated
FROM CovidPortProject..CovidDeaths as deaths
INNER JOIN CovidPortProject..CovidVaccinations as vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.location
ORDER BY PeopleVaccinated DESC


-- Percentage of people vaccinated grouped by continent
SELECT deaths.continent, MAX(CAST(vacc.people_vaccinated as int)) as PeopleVaccinated,
MAX(deaths.population) as Population,
(MAX(CAST(vacc.people_vaccinated as int)) / MAX(deaths.population)) *100 
	as VaccinationPercentage
FROM CovidPortProject..CovidDeaths as deaths
INNER JOIN CovidPortProject..CovidVaccinations as vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.continent
ORDER BY VaccinationPercentage DESC


-- Total Population vs Vaccinations in Europe
-- Shows Percentage of Population that is vaccinated on each country
SELECT deaths.location, MAX(CAST(vacc.people_vaccinated as int)) as PeopleVaccinated,
MAX(deaths.population) as Population,
(MAX(CAST(vacc.people_vaccinated as int)) / MAX(deaths.population)) *100
	as VaccinationPercentage
FROM CovidPortProject..CovidDeaths as deaths
INNER JOIN CovidPortProject..CovidVaccinations as vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent LIKE '%Euro%' 
GROUP BY deaths.location
ORDER BY 1

-- Using CTE to perform reports in previous query
-- Top 10 countries in Europe in terms of vaccination percentage
-- Only for countries with a population over 1 million
WITH EuropeVacc (Location, PeopleVaccinated, Population, VaccinationPercentage)
as
(
SELECT deaths.location, MAX(CAST(vacc.people_vaccinated as int)), MAX(deaths.population),
(MAX(CAST(vacc.people_vaccinated as int)) / MAX(deaths.population)) *100
FROM CovidPortProject..CovidDeaths as deaths
INNER JOIN CovidPortProject..CovidVaccinations as vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent LIKE '%Euro%' 
GROUP BY deaths.location
)
SELECT TOP 10 *
FROM EuropeVacc
WHERE population > 1000000
	AND VaccinationPercentage BETWEEN 0.001 AND 100
ORDER BY VaccinationPercentage DESC


---- ARGENTINA ----
-- Argentina's Temp Table to make some queries
DROP Table if exists #CovidArgentina
Create Table #CovidArgentina (
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population int,
TotalCases int,
NewCases int,
TotalDeaths int,
NewDeaths int,
TotalVaccinations int,
PeopleFullyVaccinated int,
NewVaccinations int)

INSERT INTO #CovidArgentina
Select deaths.continent, deaths.location, deaths.date, deaths.population, deaths.total_cases,
deaths.new_cases, deaths.total_deaths, deaths.new_deaths, vacc.total_vaccinations,
vacc.people_fully_vaccinated, vacc.new_vaccinations
FROM CovidPortProject..CovidDeaths as deaths
INNER JOIN CovidPortProject..CovidVaccinations as vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.location = 'Argentina'


-- Daily Total Cases versus total deaths in Argentina since first citizen died
SELECT #CovidArgentina.Date, #CovidArgentina.Location, #CovidArgentina.TotalCases,
#CovidArgentina.TotalDeaths, 
(CAST(#CovidArgentina.TotalDeaths as numeric) / #CovidArgentina.TotalCases) *100 as ArgDailyDeathRatio
FROM #CovidArgentina
WHERE #CovidArgentina.TotalDeaths IS NOT NULL


-- Rolling people vaccinated in Argentina
SELECT #CovidArgentina.Location, #CovidArgentina.date, #CovidArgentina.NewVaccinations, 
SUM(#CovidArgentina.NewVaccinations) 
	OVER (PARTITION BY #CovidArgentina.Location
		ORDER BY #CovidArgentina.Date) as RollingPeopleVaccinated
FROM #CovidArgentina
ORDER BY #CovidArgentina.Date


-- Average daily death count in Argentina since first case
SELECT #CovidArgentina.Location, AVG(#CovidArgentina.NewDeaths) as AvgDailyDeathCount
FROM #CovidArgentina
WHERE #CovidArgentina.TotalCases IS NOT NULL
GROUP BY #CovidArgentina.Location

-- Using calculation made in last query to classify each day in terms of deaths
SELECT #CovidArgentina.Location, #CovidArgentina.Date,#CovidArgentina.NewDeaths,
CASE
	WHEN #CovidArgentina.NewDeaths IS NULL THEN ''
	WHEN #CovidArgentina.NewDeaths > AVG(#CovidArgentina.NewDeaths) OVER (PARTITION BY #CovidArgentina.Location) THEN 'Above Average'
	WHEN #CovidArgentina.NewDeaths = AVG(#CovidArgentina.NewDeaths) OVER (PARTITION BY #CovidArgentina.Location) THEN 'Average'
	ELSE 'Below Average'
END as DailyDeathsAvgClass
FROM #CovidArgentina
ORDER BY #CovidArgentina.Date
