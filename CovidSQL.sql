SELECT *
FROM dbo.CovidDeaths
ORDER BY  3,4

--SELECT * 
--FROM dbo.CovidVac
--ORDER BY 3,4

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM dbo.CovidDeaths
ORDER BY location,date


-- Looking at total cases vs total deaths
-- Shows likelihood of dying if contract covid in each  country
SELECT continent,location, date, total_cases, Total_deaths, (total_deaths/total_cases)*100 AS Death_rate
from dbo.coviddeaths
WHERE continent like '%asia%'
Order by 1,2

-- Looking at total cases vs Population in each  country
SELECT location, date, total_cases,population, (total_cases/population) * 100 AS infected_rate
from dbo.coviddeaths
Order by 1,2

--Looking at which country has the highest infected_rate, DESCENDING
SELECT location,population, MAX(cast(total_cases as int)) as HighestInfectionCount, MAX((total_cases/population))* 100 as Percent_Infected,MAX(cast(total_deaths as INT))as DeathCount
FROM dbo.coviddeaths
GROUP BY Location,Population
ORDER BY Percent_Infected DESC

--Showing Countries with High Death Count per Population
SELECT location,population,MAX(cast(total_deaths as int)) AS TotalDeathCount--, (TotalDeathCount/population)*100 AS PopDeathRate
FROM dbo.coviddeaths
WHERE continent is NOT null
GROUP BY Location,population
ORDER BY TotalDeathCount DESC

-- Showing Death Counts all over the world by Region(?)
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
From dbo.coviddeaths
WHERE continent is Null AND location NOT like '%income%' 
Group by location
Order by TotalDeathCount desc


-- Showing Continent with the Highest Death Count per Population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM dbo.coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Showing the new cases globally and a global death percentage (rolling)
SELECT dea.date, SUM(cast(dea.new_cases as int)) as CasesLoggedOnTheDay, SUM(cast(dea.new_deaths as INT)) as DeathsRecordedOnTheDay, SUM(cast(dea.new_deaths as INT))/SUM(dea.new_cases)*100 AS DeathPercentage--, SUM(Convert(bigint,dea.new_deaths)) OVER (Partition by dea.date ORDER BY dea.date) AS DeathRollCount
FROM dbo.coviddeaths dea
JOIN dbo.covidvacs vac
	on dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
GROUP BY dea.date
ORDER BY dea.date, CasesLoggedOnTheDay


--Showing Total Cases and Total Deaths globally, with DeathPercentage
SELECT sum(new_cases) as TotalCases, sum(cast(new_deaths as INT)) as TotalDeaths, SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage
FROM dbo.coviddeaths
WHERE continent is NOT NULL


--Joining both datasets on date and location, then showing the vaccination rollouts by Location with a rolling count.
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations as VaccinationsOnTheDay, SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS VacRollingCount
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVacs vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3
;
--USING A CTE TO SHOW ROLLING PERCENT POPULATION VACCINATED, because we can't use a column we just created (VacRollingCount)
WITH PopvsVAC (Continent,Location,Date,Population,VaccinationsOnTheDay,VacRollingCount)
as
(
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations as VaccinationsOnTheDay, SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS VacRollingCount
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVacs vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3
)
SELECT *,(VacRollingCount/Population)*100 as PercentPopulationVaccinated
From PopvsVAC

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
VaccinationsOnTheDay numeric,
VacRolling numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations as VaccinationsOnTheDay, SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS VacRolling
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVacs vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3

SELECT *, (VacRolling/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated

--TEMP TABLE 2 PERCENT VAC EXCEEDS 100% due to the fact that a person receives multiple doses
DROP Table if exists #NewPercentPopVac
CREATE Table #NewPercentPopVac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
VaccinationsOnTheDay numeric,
VacRolling numeric
)
INSERT INTO #NewPercentPopVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations AS VaccinationsOnTheDay, SUM(Cast(vac.new_vaccinations as BIGINT)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) AS VacRolling
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVacs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (VacRolling/POPULATION)*100 as PercentVac
FROM #NewPercentPopVac
WHERE location like 'Brunei'
ORDER BY 2,3