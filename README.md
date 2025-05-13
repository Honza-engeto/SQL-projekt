# SQL Projekt: Dostupnost potravin vs. mzdy

## O projektu
Cílem projektu je analyzovat vývoj průměrných mezd a cen základních potravin v ČR, a odpovědět na několik výzkumných otázek zaměřených na kupní sílu, inflaci a vliv makroekonomických faktorů jako je HDP.

## Použitá data
Data pochází z předpřipravené databáze dodané v rámci kurzu, která čerpá z veřejně dostupných zdrojů, zejména z Portálu otevřených dat ČR. Obsahují informace o:
- průměrných mzdách v jednotlivých odvětvích,
- cenách vybraných potravin,
- HDP, GINI indexu a dalších makroekonomických indikátorech.


## Struktura projektu
- `SQL_skripty.sql` – všechny SQL dotazy potřebné k vytvoření výsledných tabulek a analýz.
- `pruvodni_listina.md` – odpovědi na jednotlivé výzkumné otázky.
- `t_jan_gondas_project_sql_primary_final` – finální tabulka se sjednocenými daty o mzdách a cenách v ČR.
- `t_jan_gondas_project_sql_secondary_final` – tabulka s dodatečnými daty (např. HDP, GINI).

## Výzkumné otázky
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

## Autor
Ján Gondáš – projekt v rámci kurzu datové akademie od Engeto Academy.
