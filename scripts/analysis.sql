-- V tomto scriptu budu odpovídat na otázky z projektu.

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- Vytvoření cte a výpočet procentuální změny oproti předchozímu roku
-- Následné vytvoření dočasné tabulky, abych ji mohl použít pro výpočet geometrického průměru
CREATE TEMPORARY TABLE temp_wage_growth AS
WITH cte1 AS (
	SELECT DISTINCT year_, industry, wage 
	FROM primary_final pf
	ORDER BY industry, year_
)
SELECT 
	*, 
	CASE 
		WHEN (wage - LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_)) / LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_) * 100 IS NULL THEN 0
		ELSE ROUND((wage - LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_)) / LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_) * 100, 2)
	END AS percent_change,
	CASE 
		WHEN (wage - LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_)) / LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_) * 100 IS NULL THEN 1
		ELSE 1 + (wage - LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_)) / LAG(wage, 1) OVER(PARTITION BY industry ORDER BY year_)
	END AS growth_factor
FROM cte1;
-- Ještě jsem přidal sloupec growth_factor, protože budu počítat geometrický průměr


-- Výpočet geometrického průměru
SELECT 
	ROW_NUMBER() OVER(ORDER BY industry) AS id, 
	industry,
	ROUND((EXP(SUM(LOG(growth_factor)) / COUNT(*)) - 1) * 100, 2) AS avg_growth
FROM temp_wage_growth wg
GROUP BY industry
ORDER BY avg_growth;
-- V závislosti na této tabulce lze odpovědět na první otázku
-- ODPOVĚĎ: I když se objeví rok, ve kterém mzdy klesnou, tak celkově během let mzdy rostou ve všech odvětví.