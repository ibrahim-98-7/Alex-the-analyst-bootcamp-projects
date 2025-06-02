-- data cleaning
select * 
from layoffs

-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways

create table layoffs_stagging
like layoffs;

select * 
from layoffs_stagging

insert layoffs_stagging
select *
from layoffs;

select * ,
ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off,`date`) AS row_num
from layoffs_stagging;

With duplicate_cte as (
select * ,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions) as row_num
from layoffs_stagging 
)
select * 
from duplicate_cte
where row_num > 1;

select * 
from layoffs_stagging
where company ='Casper';

CREATE TABLE `layoffs_stagging_copy` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_stagging_copy

INSERT into layoffs_stagging_copy
select * ,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions) as row_num
from layoffs_stagging ;

select * from layoffs_stagging_copy
where row_num > 1;

delete from layoffs_stagging_copy
where row_num > 1;

-- standerizing data

select company, trim(company)
from layoffs_stagging_copy;

update layoffs_stagging_copy
set company =trim(company);

select distinct industry 
from layoffs_stagging_copy
order by 1;

select *
from layoffs_stagging_copy
where industry like '%crypto%' ;

update layoffs_stagging_copy
set industry = 'Crypto'
where industry like 'Crypto%' ;

select distinct country
from layoffs_stagging_copy
order by 1;

SELECT country, COUNT(country) as count
FROM layoffs_stagging_copy
GROUP BY country
having country like 'United States%'

-- united states triming or update
update layoffs_stagging_copy
set country = trim( trailing '.'  from country )
where country like 'United States%' ;

-- or 

SELECT distinct country, trim( trailing '.'  from country )
FROM layoffs_stagging_copy
order by 1;

select date ,
str_to_date(date,'%m/%d/%Y') 
from layoffs_stagging_copy;

update layoffs_stagging_copy
set date = str_to_date(date,'%m/%d/%Y') ;

select * 
from layoffs_stagging_copy;

ALTER Table layoffs_stagging_copy
modify column date date;

select * 
from layoffs_stagging_copy
where total_laid_off is null
and percentage_laid_off is null;

select * 
from layoffs_stagging_copy
where industry is null or industry = '';

select *
from layoffs_stagging_copy
where company = 'Airbnb'; 

select t1.industry , t2.industry
from layoffs_stagging_copy as t1
join layoffs_stagging_copy as t2
on t1.company = t2.company
and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_stagging_copy
set industry = null
where industry = '';

update layoffs_stagging_copy as t1
join layoffs_stagging_copy as t2
	on t1.company = t2.company
set  t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

select *
from layoffs_stagging_copy
where company = "Bally's Interactive"; 

select *
from layoffs_stagging_copy;


select * 
from layoffs_stagging_copy
where total_laid_off is null
and percentage_laid_off is null;

delete
from layoffs_stagging_copy
where total_laid_off is null
and percentage_laid_off is null;

alter table layoffs_stagging_copy
drop column row_num;

select *
from layoffs_stagging_copy;

select max(total_laid_off) ,max(percentage_laid_off)
from layoffs_stagging_copy;

select *
from layoffs_stagging_copy
where percentage_laid_off = 1
order by total_laid_off desc;

select company, sum(total_laid_off)
from layoffs_stagging_copy
group by company
order by 2 desc;

select min(date), max(date)
from layoffs_stagging_copy;

select industry, sum(total_laid_off)
from layoffs_stagging_copy
group by industry
order by 2 desc;

select country, sum(total_laid_off)
from layoffs_stagging_copy
group by country
order by 2 desc;

select year(date) as year, sum(total_laid_off) as laid_off
from layoffs_stagging_copy
group by year
order by 1 desc;

select stage, sum(total_laid_off) as laid_off
from layoffs_stagging_copy
group by stage
order by 1 desc;

select country, avg(percentage_laid_off) perc_layoff
from layoffs_stagging_copy
group by country
order by 2 desc;

select substring(date,1,7) as month , sum(total_laid_off) as laid_off
from layoffs_stagging_copy
where substring(date,1,7) is not null
group by month 
order by 1 asc;

with rolling_total as (
select substring(date,1,7) as month , sum(total_laid_off) as laid_off
from layoffs_stagging_copy
where substring(date,1,7) is not null
group by month 
order by 1 asc
)
select month ,laid_off, sum(laid_off) over(order by month ) rolling_total
from rolling_total;

select company, year(date) as year ,sum(total_laid_off) as total_layoff
from layoffs_stagging_copy
group by company , year(date)
order by company desc;

with company_by_year as (
select company, year(date) as years ,sum(total_laid_off) as total_layoff
from layoffs_stagging_copy
group by company , year(date)
order by company desc
) , company_year_rank as (
select *, dense_rank() over (partition by years order by total_layoff desc) as ranks
from company_by_year
where years is not null
)
select *
from company_year_rank
where ranks <= 5;

with funds as (
select  year(date) as years,industry ,company, funds_raised_millions ,percentage_laid_off
from layoffs_stagging_copy
where funds_raised_millions is not null and industry is not null
)
select *
from funds
order by 1 desc;


SELECT
    CASE
        WHEN funds_raised_millions < 100 THEN 'Under $100M'
        WHEN funds_raised_millions >= 100 AND funds_raised_millions < 500 THEN '$100M - $500M'
        WHEN funds_raised_millions >= 500 THEN 'Over $500M'
        ELSE 'Unknown'
    END AS funding_tier,
    AVG(total_laid_off) AS avg_laid_off,
    COUNT(*) AS number_of_companies
FROM
    layoffs_stagging_copy
WHERE
    total_laid_off IS NOT NULL AND funds_raised_millions IS NOT NULL
GROUP BY
    funding_tier
ORDER BY
    funding_tier;
    
SELECT
    industry,
    AVG(funds_raised_millions) AS avg_funds_raised,
    AVG(total_laid_off) AS avg_laid_off,
    AVG(percentage_laid_off) AS avg_percentage_laid_off,
    COUNT(*) AS number_of_layoff_events
FROM
    layoffs_stagging_copy
WHERE
    industry IS NOT NULL AND funds_raised_millions IS NOT NULL
GROUP BY
    industry
ORDER BY
    avg_funds_raised DESC; 
    
SELECT
    country,
    SUM(funds_raised_millions) AS total_funds_raised_in_country,
    AVG(total_laid_off) AS avg_country_laid_off,
    AVG(percentage_laid_off) AS avg_country_percentage_laid_off,
    COUNT(*) AS number_of_layoff_events
FROM
    layoffs_stagging_copy
WHERE
    country IS NOT NULL AND funds_raised_millions IS NOT NULL
GROUP BY
    country
ORDER BY
    total_funds_raised_in_country DESC;
