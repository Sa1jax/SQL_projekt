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


-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- Vytvoření dočasné tabulky pro průměrnou mzdu v letech 2006 a 2018
CREATE TEMPORARY TABLE temp_avg_wage_06_18 AS 
SELECT
	year_,
	wage AS avg_wage
FROM primary_final pf
WHERE year_ IN (2006, 2018)
GROUP BY year_;

-- Vytvoření dočasné tabulky pro průměrnou cenu chleba a mléka v letech 2006 a 2018
CREATE TEMPORARY TABLE temp_avg_price_06_18 AS
SELECT DISTINCT
	year_,
	food,
	price,
	amount,
	unit
FROM primary_final pf
WHERE year_ IN (2006, 2018)
	AND food IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované');
	
-- Spojení obou tabulek pro finální výpočty
SELECT 
	a.*,
	b.avg_wage,
	ROUND(b.avg_wage / a.price) AS purchasing_power
FROM temp_avg_price_06_18 a
JOIN temp_avg_wage_06_18 b
	ON a.year_ = b.year_;
-- Zde je výsledná tabulka, která ukazuje kolik litrů mléka a kilogramů chleba si mohl člověk koupit za průměrnou mzdu v těchto letech
-- Je vidět, že kupní síla na tyto dvě potraviny v letech 2006-2018 mírně rostla


-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
-- Vytvoření dočasné tabulky, která obsahuje procentuální změnu a growth_factor pro výpočet geometrického průměru
CREATE TEMPORARY TABLE temp_food_price_growth AS
WITH cte2 AS (
	SELECT DISTINCT 
		year_,
		food,
		price
	FROM primary_final pf
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

-- Výpočet geometrického průměru a tvorba tabulky pro odpověď na třetí otázku
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
