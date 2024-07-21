-- Pro vytvoření finální tabulky, ze které udělám dotazy, které odpoví na otázky, musím:
-- 1. Udělat temporary table z dat pro mzdy
-- 2. Udělat temporary table z dat pro ceny potravin
-- 3. Spojit pomocí JOIN tyto dvě tabulky a ještě přidat sloupec s HDP
-- 4. Začít z této tabulky dělat dotazy, které odpoví na otázky

-- View s platy za daný rok v daném odvětví.
-- Eliminoval jsem kvartály a to tak, že jsem vypočítal průměrnou mzdu za daný rok a použil GROUP BY.
CREATE VIEW v_industry_wages AS 
SELECT 
	cp.payroll_year,
	cpi.name AS industry,
	ROUND(AVG(cp.value)) AS wage
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpi
	ON cp.industry_branch_code = cpi.code
	AND industry_branch_code IS NOT NULL 
	AND value_type_code = 5958
	AND calculation_code = 100
GROUP BY cpi.name, cp.payroll_year 
ORDER BY cpi.name, cp.payroll_year;

SELECT * FROM v_industry_wages viw;

-- View s cenami potravin za daný rok
CREATE VIEW v_grocery_prices AS
SELECT
	YEAR(cp.date_from) AS year_,
	cpc.name AS food,
	ROUND(AVG(cp.value), 2) AS price,
	cpc.price_value AS amount,
	cpc.price_unit AS unit
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
GROUP BY cpc.name, YEAR(cp.date_from)
ORDER BY year_;


-- Vytvoření finální tabulky
-- Předchozí tabulky jsem spojil a přidal jsem ještě HDP Česka
CREATE TABLE t_david_hruby_project_SQL_primary_final AS
SELECT 
	gp.*,
	iw.industry,
	iw.wage,
	ROUND(e.gdp) AS GDP
FROM v_industry_wages iw
JOIN v_grocery_prices gp
	ON iw.payroll_year = gp.year_
JOIN economies e
	ON e.`year` = iw.payroll_year
	AND e.country = 'Czech Republic'
ORDER BY gp.year_, iw.industry;

-- Implementace primárního klíče
ALTER TABLE t_david_hruby_project_SQL_primary_final
ADD PRIMARY KEY (year_, food, industry);