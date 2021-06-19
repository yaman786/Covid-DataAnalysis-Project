/*
COVID-19 Data Exploration

Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creatings Views, Converting Data Types

DatabaseName = CovidProject and TableName = covid_deaths$ and covid_vaccinations$ 
*/

Select * 
From CovidProject..covid_deaths$
Where continent is not null
Order by location,date

--Select Data that we are we going to start with

Select location,date,new_cases,total_cases,total_deaths,population
From CovidProject..covid_deaths$
order by location,date

--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From CovidProject..covid_deaths$
Where location like '%Nepal'
and continent is not null
Order by location,date

--Total Cases vs Population
--Shows what percentage of population infected with covid

Select location,date,population,total_cases,(total_cases/population)*100 as PercentPopulationInfected
From CovidProject..covid_deaths$
Order by location,date

--Countries with Highest Infection Rate compared to Population

Select location,population,MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..covid_deaths$
Group by location,population
Order by PercentPopulationInfected desc

--Countries with Highest Death Counts per Population

select location,MAX(CONVERT(int,total_deaths)) as TotalDeathCount
From CovidProject..covid_deaths$
Where continent is not null
Group by location
Order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT

--Showing continents with the highest death count

Select continent,MAX(CONVERT(int,total_deaths)) as TotalDeathCount
From CovidProject..covid_deaths$
Where continent is not null
Group by continent
Order by TotalDeathCount desc

--GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidProject..covid_deaths$
where continent is not null

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent,dea.location,dea.date,dea.population ,vac.new_vaccinations
,SUM(CONVERT(int,new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
From CovidProject..covid_deaths$ dea
Join CovidProject..covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..covid_deaths$ dea
Join CovidProject..covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
Where Location = 'Nepal'

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidProject..covid_deaths$ dea
Join CovidProject..covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..covid_deaths$ dea
Join CovidProject..covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

