-- Script, kde budu tvořit sekundární tabulku
-- ÚKOL: zobrazit HDP, GINI a populaci dalších evropských států ve stejném období jako přehled o Česku

CREATE TABLE t_david_hruby_project_SQL_secondary_final AS
SELECT
	e.`year`,
	e.country,
	ROUND(e.GDP) AS GDP,
	IF(e.gini IS NULL, 'N/A', e.gini) AS gini,
	e.population
FROM economies e
JOIN countries c
	ON e.country = c.country
	AND c.continent = 'Europe'
	AND e.`year` BETWEEN 2006 AND 2018
ORDER BY e.country, e.year;
-- Zde je dokončená sekundární tabulka s všemi sloupci, které byli v zadání

-- Změna datového typu u country z text na VARCHAR(100)
ALTER TABLE t_david_hruby_project_sql_secondary_final 
MODIFY country VARCHAR(100);

-- Přidání primárního klíče
ALTER TABLE t_david_hruby_project_sql_secondary_final 
ADD PRIMARY KEY (year, country, population);