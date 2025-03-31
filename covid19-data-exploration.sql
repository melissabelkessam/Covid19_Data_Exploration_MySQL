/*
Covid 19 Data Exploration (MySQL version)

*/

-- 1. Données brutes hors zones globales
SELECT *
FROM CovidDeaths2
WHERE continent IS NOT NULL
ORDER BY date, location;

-- 2. Données principales (lieu, cas, décès, population)
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths2
WHERE continent IS NOT NULL
ORDER BY location, date;

-- 3. Total Cases vs Total Deaths (pourcentage de mortalité)
SELECT location, date, total_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths2
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, date;

-- 4. Total Cases vs Population (taux d'infection)
SELECT location, date, population, total_cases,
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeaths2
ORDER BY location, date;

-- 5. Pays avec le taux d'infection le plus élevé
SELECT location, population,
       MAX(total_cases) AS HighestInfectionCount,
       MAX(total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeaths2
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 6. Pays avec le plus de décès
SELECT location,
       MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidDeaths2
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 7. Continents avec le plus de décès
SELECT continent,
       MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidDeaths2
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 8. Statistiques globales : total cas, décès, % décès
SELECT SUM(new_cases) AS total_cases,
       SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
       SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths2
WHERE continent IS NOT NULL;

-- 9. Population vs Vaccination avec cumul (sans CTE)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- 10. Vue pour cumul vaccination
CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- 11. Utilisation de la vue avec calcul du % vaccinés
SELECT *, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM PercentPopulationVaccinated;

-- 12. Requête équivalente avec sous-requête sans vue
SELECT pv.*, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
         SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
  FROM CovidDeaths2 dea
  JOIN CovidVaccinations2 vac
    ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
) AS pv;

-- 13. Simulation table temporaire (version simplifiée pour MySQL)
DROP TEMPORARY TABLE IF EXISTS TempPercentPopulationVaccinated;
CREATE TEMPORARY TABLE TempPercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
  ON dea.location = vac.location AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM TempPercentPopulationVaccinated;
