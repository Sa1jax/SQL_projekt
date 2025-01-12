# SQL-projekt
Analýza růstu cen a mezd v ČR

### Úvod
Tento projekt se zaměřuje na analýzu ekonomických dat. Poskytl jsem datasety, které jsem použil a scripty, které vám umožní analyzovat vývoj cen potravin, mezd a HDP mezi lety 2006-2018. Cílem je poskytnout nástroje pro provedení analýzy a odpovědět na specifické otázky týkající se ekonomických trendů.

### Struktura projektu
Projekt obsahuje toto **README**, .gitignore, **průvodní listinu**, kde popisuji postupy a metody, které jsem během analýzy dat použil a dvě složku s názvem **scripts/**. Uvnitř složky scripts se nacházejí **SQL scripty**, které vytvářejí a zobrazují jednotlivé tabulky, ze kterých jsem vytvářel odpovědi na otázky.

### Návod k použití
##### **1. Stažení a příprava**
Nejdříve naklonujte můj repozitář a jelikož používám Git Bash, tak zde je příkaz, který můžete použít:
![image](https://github.com/user-attachments/assets/4359d781-fe92-4d62-932a-c5e59a023b5a)
Pokud máte místo, kam byste chtěli repozitář stáhnout, tak před tímto příkazem použijte **cd "cestu k vaší složce"**
##### **2. Import datasetů**
Vytvořte si lokální databázi a pomocí vašeho editoru naimportujte datasety do databáze.
##### **3. Spuštění scriptů**
Scripty musíte spouštět ve správném pořadí. První spusťte script s názvem **final_table_primary.sql**, který vytvoří primární tabulku, ze keré jsem prováděl finální analýzy. Poté spusťte **final_table_secondary.sql** a jako poslední spusťte **analysis.sql**, kde se již nachází finální analýzy, díky kterým jsem vypracoval odpovědi na otázky. Také musíte spustit všechny dotazy, které vytvářejí dočasné tabulky (TEMPORARY TABLE), jinak vám některé dotazy nemusí fungovat!
##### **4. Ověření výsledků**
Zkontrolujte zda byly tabulky správně vytvořeny a obsahují správná data.
#### **Odkaz na průvodní listinu**
[--Průvodní listina--](https://github.com/Sa1jax/SQL_projekt/blob/main/pruvodni_listina.pdf)

### Závěr
Doufám, že tento projekt vám poskytne užitečné nástroje a informace pro analýzu ekonomických trendů.

#### Autor a kontakt
**David Hrubý**
**email**: hrubyd74@gmail.com

