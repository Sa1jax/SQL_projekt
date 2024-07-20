-- Pro vytvoření finální tabulky, ze které udělám dotazy, které odpoví na otázky, musím:
-- 1. Udělat temporary table z dat pro mzdy
-- 2. Udělat temporary table z dat pro ceny potravin
-- 3. Spojit pomocí JOIN tyto dvě tabulky a ještě přidat sloupec s HDP
-- 4. Začít z této tabulky dělat dotazy, které odpoví na otázky

-- Dočasná tabulka s platy za daný rok v daném odvětví.
-- Eliminoval jsem kvartály a to tak, že jsem vypočítal průměrnou mzdu za daný rok a použil GROUP BY.
CREATE TEMPORARY TABLE temp_industry_wages AS 
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
