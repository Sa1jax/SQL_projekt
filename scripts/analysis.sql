-- V tomto scriptu budu odpovídat na otázky z projektu.

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- Vytvoření cte a výpočet procentuální změny oproti předchozímu roku
-- Následné vytvoření view, abych ho mohl použít pro výpočet geometrického průměru
CREATE VIEW v_wage_growth AS
WITH cte1 AS (
	SELECT DISTINCT year_, industry, wage 
	FROM t_david_hruby_project_SQL_primary_final pf
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
FROM v_wage_growth wg
GROUP BY industry
ORDER BY avg_growth;
-- V závislosti na této tabulce lze odpovědět na první otázku
-- ODPOVĚĎ: I když se objeví rok, ve kterém mzdy klesnou, tak celkově během let mzdy rostou ve všech odvětví.


-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- Vytvořil jsem cte pro mezivýpočet a následně jsem je spojil dohromady
WITH avg_wage_06_18 AS (
	SELECT DISTINCT
		year_,
		ROUND(AVG(wage)) AS avg_wage
	FROM t_david_hruby_project_SQL_primary_final pf
	WHERE year_ IN (2006, 2018)
	GROUP BY year_
), 
avg_price_06_18 AS (
	SELECT DISTINCT
		year_,
		food,
		price AS avg_price,
		amount,
		unit
	FROM t_david_hruby_project_SQL_primary_final pf
	WHERE year_ IN (2006, 2018)
		AND food IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
)
SELECT 
	a.*,
	b.avg_wage,
	ROUND(b.avg_wage / a.avg_price) AS purchasing_power
FROM avg_price_06_18 a
JOIN avg_wage_06_18 b
	ON a.year_ = b.year_;
-- Zde je výsledný dotaz, který ukazuje kolik litrů mléka a kilogramů chleba si mohl člověk koupit za průměrnou mzdu v těchto letech


-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
-- Vytvoření view, které obsahuje procentuální změnu a growth_factor pro výpočet geometrického průměru
CREATE TEMPORARY TABLE temp_food_price_growth AS
WITH cte2 AS (
	SELECT DISTINCT 
		year_,
		food,
		price
	FROM t_david_hruby_project_SQL_primary_final pf
)
SELECT
	*,
	CASE 
		WHEN (price - LAG(price, 1) OVER(PARTITION BY food ORDER BY year_)) / LAG(price, 1) OVER(PARTITION BY food ORDER BY year_) * 100 IS NULL THEN 0 
		ELSE ROUND((price - LAG(price, 1) OVER(PARTITION BY food ORDER BY year_)) / LAG(price, 1) OVER(PARTITION BY food ORDER BY year_) * 100, 2)
	END AS percent_change,
	CASE 
		WHEN (price - LAG(price, 1) OVER(PARTITION BY food ORDER BY year_)) / LAG(price, 1) OVER(PARTITION BY food ORDER BY year_) * 100 IS NULL THEN 1 
		ELSE ROUND(1 + (price - LAG(price, 1) OVER(PARTITION BY food ORDER BY year_)) / LAG(price, 1) OVER(PARTITION BY food ORDER BY year_), 4)
	END AS growth_factor
FROM cte2
ORDER BY food, year_;

-- Výpočet geometrického průměru a tvorba dotazu pro odpověď na třetí otázku
SELECT 
	ROW_NUMBER() OVER(ORDER BY food) AS id,
	food,
	ROUND((EXP(SUM(LOG(growth_factor)) / COUNT(*)) - 1) * 100, 2) AS avg_growth
FROM temp_food_price_growth
GROUP BY food
ORDER BY avg_growth;
-- ODPOVĚĎ: Nejpomaleji zdražuje cukr, který dokonce během let zlevnil.


-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
-- Zvolil jsem obecný přehled, kdy porovnám průměr mezd všech odvětví pro daný rok s průměrným růstem všech potravin za daný rok
-- Vynechal jsem rok 2006, protože tam nemám data k růstu potravin
-- Pro jistotu, aby nedošlo ke zkreslenému výpočtu použil cte na mezivýpočet a pak až tabulky spojil 
WITH cte_wage AS (
	SELECT 
		year_,
		ROUND(AVG(percent_change), 2) AS avg_percent_change_wage
	FROM temp_wage_growth 
	WHERE year_ > 2006
	GROUP BY year_
),
cte_food AS (
	SELECT 
		year_,
		ROUND(AVG(percent_change), 2) AS avg_percent_change_food
	FROM temp_food_price_growth 
	WHERE year_ > 2006
	GROUP BY year_
)
SELECT 
	w.*,
	f.avg_percent_change_food
FROM cte_wage w
JOIN cte_food f
	ON w.year_ = f.year_
WHERE f.avg_percent_change_food > w.avg_percent_change_wage
ORDER BY w.year_;
-- ODPOVĚĎ: V tomto dotazu lze vypozorovat, že neexistuje rok, kdy by ceny potravin rostly o 10+% více než mzdy.


/* 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
	  projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? */
-- Vytvoření dočasné tabulky pro uchování tabulky s růstem hdp
CREATE TEMPORARY TABLE temp_gdp_growth AS
WITH cte3 AS (
	SELECT DISTINCT
		year_,
		GDP
	FROM t_david_hruby_project_SQL_primary_final pf
)
SELECT
	year_,
	CASE
		WHEN (GDP - LAG(GDP, 1) OVER(ORDER BY year_)) / LAG(GDP, 1) OVER(ORDER BY year_) * 100 IS NULL THEN 0 
		ELSE ROUND((GDP - LAG(GDP, 1) OVER(ORDER BY year_)) / LAG(GDP, 1) OVER(ORDER BY year_) * 100, 2)
	END AS gdp_growth
FROM cte3;

-- Vytvoření dotazu pro odpověď na otázku číslo 5
WITH cte_wage2 AS (
	SELECT 
		year_,
		ROUND(AVG(percent_change), 2) AS avg_percent_change_wage
	FROM temp_wage_growth 
	WHERE year_ > 2006
	GROUP BY year_
),
cte_food2 AS (
	SELECT 
		year_,
		ROUND(AVG(percent_change), 2) AS avg_percent_change_food
	FROM temp_food_price_growth 
	WHERE year_ > 2006
	GROUP BY year_
)
SELECT
	g.year_,
	g.gdp_growth,
	w.avg_percent_change_wage AS wage_growth, 
	f.avg_percent_change_food AS food_price_growth
FROM temp_gdp_growth g
JOIN cte_wage2 w
	ON g.year_ = w.year_
JOIN cte_food2 f
	ON g.year_ = f.year_;
/* ODPOVĚĎ: Růst HDP nějaký vliv na ceny a mzdy určitě má.
			Například v letech 2009 a 2010 po krizi v roce 2008 je vidět, že při poklesu HDP klesly i ceny a mzdy.
			Naopak v období růstu HDP v letech 2015-2018 je vidět, že mzdy a ceny rostly.
			Korelace mezi hdp a mzdami bude větší než mezi hdp a cenami. */