-- ========================================================
-- Vytvoření tabulky t_jan_gondas_project_sql_primary_final
-- ========================================================

create table t_jan_gondas_project_sql_primary_final as
select
    p.payroll_year,
    p.payroll_quarter,
    vb.code as value_type_code,
    vb.name as value_type_name,
    cb.code as industry_branch_code,
    cb.name as industry_branch_name,
    cu.code as calculation_code,
    cu.name as calculation_name,
    p.value as payroll_value,
    u.code as unit_code,
    u.name as unit_name,
    prc.date_from,
    prc.date_to,
    pc.code as price_category_code,
	pc.name as price_category_name,
	pc.price_value as category_price_value,
	pc.price_unit,
	prc.value as price_value,
    prc.region_code
from czechia_payroll p
join czechia_payroll_value_type vb on p.value_type_code = vb.code
join czechia_payroll_industry_branch cb on p.industry_branch_code = cb.code
join czechia_payroll_calculation cu on p.calculation_code = cu.code
join czechia_payroll_unit u on p.unit_code = u.code
left join czechia_price prc on p.payroll_year = extract(year from prc.date_from)
left join czechia_price_category pc on prc.category_code = pc.code
where
    vb.code in (5958)
    and cu.code = 100
;

-- ==========================================================
-- Vytvoření tabulky t_jan_gondas_project_sql_secondary_final
-- ==========================================================

create table t_jan_gondas_project_sql_secondary_final as
select
e.country,
e.year,
e.gdp,
e.gini,
e.taxes
from economies e
left join countries c on e.country = c.country
--where e.year between 2006 and 2021
order by e.country, e.year;


-- =================================================================================
-- OTÁZKA 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- =================================================================================

create or replace view v_jan_gondas_project_sql_primary_final_payrolls as
select
    industry_branch_code,
    industry_branch_name,
    payroll_year,
    round(avg(payroll_value)::numeric, 2) as avg_payroll,
    lag(round(avg(payroll_value)::numeric, 2)) over (partition by industry_branch_code order by payroll_year) as prev_year_payroll,
    round(
        100.0 * (avg(payroll_value) - lag(avg(payroll_value)) over (partition by industry_branch_code order by payroll_year)) /
        nullif(lag(avg(payroll_value)) over (partition by industry_branch_code order by payroll_year), 0)
        , 2
    ) as yoy_change_pct
from t_jan_gondas_project_sql_primary_final
group by industry_branch_code, industry_branch_name, payroll_year
order by industry_branch_name, payroll_year;

select 
	*
from v_jan_gondas_project_sql_primary_final_payrolls;

create or replace view v_jan_gondas_project_sql_primary_final_decreasing_payroll as
with payroll_changes as (
    select
        industry_branch_code,
        industry_branch_name,
        payroll_year,
        round(avg(payroll_value)::numeric, 2) as avg_payroll,
        lag(round(avg(payroll_value)::numeric, 2)) over (partition by industry_branch_code order by payroll_year) as prev_year_payroll,
        round(
            100.0 * (avg(payroll_value) - lag(avg(payroll_value)) over (partition by industry_branch_code order by payroll_year)) /
            nullif(lag(avg(payroll_value)) over (partition by industry_branch_code order by payroll_year), 0),
            2
        ) as yoy_change_pct
    from t_jan_gondas_project_sql_primary_final
    group by industry_branch_code, industry_branch_name, payroll_year
)
select *
from payroll_changes
where avg_payroll < prev_year_payroll
order by industry_branch_name, payroll_year;

select
	*
from v_jan_gondas_project_sql_primary_final_decreasing_payroll;

-- ========================================================================================================================================
-- OTÁZKA 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- ========================================================================================================================================

create or replace view v_jan_gondas_project_sql_primary_final_milk_bread as
with base_data as (
    select
        payroll_year,
        price_category_name,
        round(avg(payroll_value)::numeric, 2) as avg_salary,
        round(avg(price_value)::numeric, 2) as avg_price
    from t_jan_gondas_project_sql_primary_final
    where price_category_name in (
        'Chléb konzumní kmínový',
        'Mléko polotučné pasterované'
    )
    and value_type_code = 5958  -- průměrná hrubá mzda
    and calculation_code = 100  -- fyzické osoby
    group by payroll_year, price_category_name
),
min_max_years as (
    select min(payroll_year) as first_year, max(payroll_year) as last_year from base_data
)
select
    d.payroll_year,
    d.price_category_name,
    d.avg_salary,
    d.avg_price,
    round(d.avg_salary / d.avg_price, 2) as quantity_affordable
from base_data d
join min_max_years y on d.payroll_year in (y.first_year, y.last_year)
order by d.payroll_year, d.price_category_name;

select * from v_jan_gondas_project_sql_primary_final_milk_bread;

-- =========================================================================================================
-- OTÁZKA 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
-- =========================================================================================================

create or replace view v_jan_gondas_project_sql_primary_final_slowest_rising_food as
with yearly_prices as (
    select
        price_category_name,
        payroll_year,
        round(avg(price_value)::numeric, 2) as avg_price
    from t_jan_gondas_project_sql_primary_final
    where price_value is not null
    group by price_category_name, payroll_year
),
price_growth as (
    select
        price_category_name,
        payroll_year,
        avg_price,
        lag(avg_price) over (partition by price_category_name order by payroll_year) as prev_year_price,
        round(
            100.0 * (avg_price - lag(avg_price) over (partition by price_category_name order by payroll_year)) /
            nullif(lag(avg_price) over (partition by price_category_name order by payroll_year), 0),
            2
        ) as yoy_growth_pct
    from yearly_prices
),
avg_growth_by_category as (
    select
        price_category_name,
        round(avg(yoy_growth_pct)::numeric, 2) as avg_yoy_growth_pct
    from price_growth
    where yoy_growth_pct is not null
    group by price_category_name
)
select *
from avg_growth_by_category
order by avg_yoy_growth_pct asc;

select
	*
from v_jan_gondas_project_sql_primary_final_slowest_rising_food;

-- =================================================================================================================
-- OTÁZKA 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
-- =================================================================================================================

create or replace view v_jan_gondas_project_sql_primary_final_price_vs_salary_growth as
with yearly_data as (
    select
        payroll_year,
        round(avg(price_value)::numeric, 2) as avg_price,
        round(avg(payroll_value)::numeric, 2) as avg_salary
    from t_jan_gondas_project_sql_primary_final
    where price_value is not null and payroll_value is not null
    group by payroll_year
),
growths as (
    select
        payroll_year,
        avg_price,
        avg_salary,
        lag(avg_price) over (order by payroll_year) as prev_price,
        lag(avg_salary) over (order by payroll_year) as prev_salary,
        round(100.0 * (avg_price - lag(avg_price) over (order by payroll_year)) / nullif(lag(avg_price) over (order by payroll_year), 0), 2) as price_growth_pct,
        round(100.0 * (avg_salary - lag(avg_salary) over (order by payroll_year)) / nullif(lag(avg_salary) over (order by payroll_year), 0), 2) as salary_growth_pct
    from yearly_data
)
select *,
       round(price_growth_pct - salary_growth_pct, 2) as difference_pct
from growths
where price_growth_pct is not null and salary_growth_pct is not null
order by difference_pct desc;


select * from v_jan_gondas_project_sql_primary_final_price_vs_salary_growth;

-- =====================================================================================================================================================================================================================
-- OTÁZKA 5: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
-- =====================================================================================================================================================================================================================

create or replace view v_jan_gondas_project_sql_secondary_final_hdp_vs_delayed_effect as
with czech_hdp as (
    select
        year as payroll_year,
        gdp
    from t_jan_gondas_project_sql_secondary_final
    where country like '%Czech%'
),
core_data as (
    select
        payroll_year,
        round(avg(payroll_value)::numeric, 2) as avg_salary,
        round(avg(price_value)::numeric, 2) as avg_price
    from t_jan_gondas_project_sql_primary_final
    group by payroll_year
),
lagged as (
    select
        c.payroll_year,
        h.gdp,
        c.avg_salary,
        c.avg_price,
        lag(h.gdp) over (order by c.payroll_year) as prev_gdp,
        lag(c.avg_salary) over (order by c.payroll_year) as prev_salary,
        lag(c.avg_price) over (order by c.payroll_year) as prev_price,
        lead(c.avg_salary) over (order by c.payroll_year) as next_salary,
        lead(c.avg_price) over (order by c.payroll_year) as next_price
    from core_data c
    join czech_hdp h on c.payroll_year = h.payroll_year
),
final as (
    select
        *,
        round(((gdp - prev_gdp) / nullif(prev_gdp, 0))::numeric * 100, 2) as gdp_growth_pct,
        round(((avg_salary - prev_salary) / nullif(prev_salary, 0))::numeric * 100, 2) as salary_growth_pct,
        round(((avg_price - prev_price) / nullif(prev_price, 0))::numeric * 100, 2) as price_growth_pct,
        round(((next_salary - avg_salary) / nullif(avg_salary, 0))::numeric * 100, 2) as salary_growth_next_year,
        round(((next_price - avg_price) / nullif(avg_price, 0))::numeric * 100, 2) as price_growth_next_year
    from lagged
)
select * from final
order by payroll_year;

select * from v_jan_gondas_project_sql_secondary_final_hdp_vs_delayed_effect;