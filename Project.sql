use github_db;
select * from netflix_titles_clean;
select * from netflix_subscriptions_clean;
select * from netflix_reviews_clean;
select * from netflix_viewership_clean;

SET SQL_SAFE_UPDATES = 0;


UPDATE netflix_titles_clean
SET 
    title = NULLIF(TRIM(title), ''),
    type = NULLIF(TRIM(type), ''),
    genre = NULLIF(TRIM(genre), ''),
    rating = NULLIF(TRIM(rating), ''),
    director = NULLIF(TRIM(director), ''),
    country = NULLIF(TRIM(country), ''),
    language = NULLIF(TRIM(language), ''),
    date_added = NULLIF(TRIM(date_added), ''),
    age_certification = NULLIF(TRIM(age_certification), '');

UPDATE netflix_viewership_clean
SET 
    region = NULLIF(TRIM(region), ''),
    device_type = NULLIF(TRIM(device_type), '');

UPDATE netflix_reviews_clean
SET 
    sentiment = NULLIF(TRIM(sentiment), ''),
    review_text = NULLIF(TRIM(review_text), ''),
    review_date = NULLIF(TRIM(review_date), '');

UPDATE netflix_reviews_clean
SET 
    sentiment = NULLIF(TRIM(sentiment), ''),
    review_text = NULLIF(TRIM(review_text), ''),
    review_date = NULLIF(TRIM(review_date), '');

-- 1. List all Netflix titles with their type (Movie/TV Show) and release year.
select title,type,release_year
from netflix_titles_clean;

-- 2.Find all movies released after 2018.
select * from netflix_titles_clean
where release_year>2018 and type= "Movie";

-- 3.Show top 10 most recently added titles.

select * from netflix_titles_clean
order by date_added desc
limit 10;

-- 4.Count total number of Movies vs TV Shows.
select type,count(*) as Total from netflix_titles_clean
where type = "TV SHOW"or type="Movie"
group by type;

-- Q5. Which Netflix titles have highest total watch hours along with their IMDb score and budget?

select
  t.title,
  v.watch_hours_millions,
  t.imdb_score,
  t.budget_millions
from netflix_titles_clean t
join netflix_viewership_clean v
on t.show_id = v.show_id
order by v.watch_hours_millions desc,t.imdb_score desc,t.budget_millions desc
limit 1;

-- 6. Compare Movies vs TV Shows based on average watch hours and average IMDb score.

select t.type,avg(v.watch_hours_millions) as Average_Watch_Hour_millions,avg(imdb_score) as Average_imdb_score
from netflix_titles_clean t
join netflix_viewership_clean v
on t.show_id=v.show_id
where type in ("TV Show","Movie")
group by t.type;

-- 7.Top 10 genres with highest total views and average completion rate.

select genre, sum(views_millions) as Total_Views,avg(completion_rate) as Average_Completion_Rate
from netflix_titles_clean as t
join netflix_viewership_clean as v
on t.show_id=v.show_id
group by genre
order by Total_Views desc,Average_Completion_Rate desc limit 10;


-- 8.Which countries produce content that receives highest watch hours globally?
select t.country,sum(v.watch_hours_millions) as Total_Watch_Hours
from netflix_titles_clean t
join netflix_viewership_clean v
on t.show_id=v.show_id
group by t.country
order by Total_Watch_Hours desc
limit 1;


-- 9.Which language content has highest average user rating and total views?

select language,avg(r.rating) as Average_Rating , sum(v.views) as Total_Views
from netflix_titles_clean as t
left join(select show_id,avg(rating) as rating
 from netflix_reviews_clean 
 group by show_id
 )as r
on t.show_id=r.show_id
left join (select show_id,sum(views_millions) as views
from netflix_viewership_clean
group by show_id) as v
on t.show_id=v.show_id
group by t.language
order by Average_Rating desc,Total_Views desc
limit 1
;

-- 10.Does higher IMDb score lead to higher user ratings and more watch hours?
with review_avg as (
    select 
        show_id,
        avg(rating) as avg_user_rating
    from netflix_reviews_clean
    group by show_id
),

view_data as (
    select 
        show_id,
        sum(watch_hours_millions) as total_watch_hours
    from netflix_viewership_clean
    group by show_id
)

select 
    t.show_id,
    t.imdb_score,
    r.avg_user_rating,
    v.total_watch_hours
from netflix_titles_clean t
left join review_avg r
    on t.show_id = r.show_id
left join view_data v
    on t.show_id = v.show_id
where t.imdb_score is not null;

-- 11.Which sentiment category (Positive / Neutral / Negative) is associated with highest completion rate?

select r.sentiment,avg(v.Completion_Rate) as Average_Completion_Rate
from netflix_reviews_clean  as r
join (select show_id,avg(completion_rate) as Completion_Rate from netflix_viewership_clean group by show_id ) as v
on r.show_id=v.show_id
group by r.sentiment
order by avg(v.Completion_Rate) desc
limit 1;


-- 12. Find top 10 directors whose shows receive highest average user rating and watch hours.

select t.director,avg(r.Rating) as Average_Rating , sum(v.Watch) as Total_Hours
from netflix_titles_clean as t
join (select show_id,avg(rating) as Rating from netflix_reviews_clean group by show_id) as r
on t.show_id=r.show_id
join (select show_id,sum(watch_hours_millions) as Watch from netflix_viewership_clean group by show_id) as v
on t.show_id=v.show_id
group by t.director
order by Average_Rating desc , Total_Hours desc
limit 10;

-- 13.How does age certification affect viewership and completion rate?

select t.age_certification,sum(Views)as Total_Views , avg(Completion) as Average_Completion
from netflix_titles_clean as t
join (select show_id,sum(views_millions) as Views , avg(completion_rate) as Completion from netflix_viewership_clean group by show_id) as v
on t.show_id=v.show_id
group by t.age_certification;

-- 14.Which subscription type generates highest total revenue and watch hours?

select s.subscription_type,sum(Revenue) as Total_Revenue, sum(Watch_Hours) as Total_Watch_Hours
from (select show_id,subscription_type,sum(subscription_price) as Revenue from netflix_subscriptions_clean group by show_id,subscription_type) as s
join (select show_id , sum(watch_hours_millions) as Watch_Hours from netflix_viewership_clean group by show_id) as v
on s.show_id=v.show_id
group by s.subscription_type
order by Total_Revenue desc ,Total_Watch_Hours desc
limit 1;

-- 15.Which shows attract the most Premium subscription users?

select t.title,count(s.subscription_id) as Total_Shows
from netflix_titles_clean t
join netflix_subscriptions_clean as s
on t.show_id=s.show_id
where s.subscription_type="Premium"
group by t.title
order by Total_Shows desc
limit 10
;

-- 16.Which region watches most content and prefers which device type?

select v.region,v.device_type,sum(v.watch_hours_millions) as Total_Watch_Hours 
from netflix_viewership_clean as v
group by v.region,v.device_type
order by Total_Watch_Hours desc 
limit 1;

-- 17.Do newly added shows receive higher watch hours compared to older ones?
select 
    year(t.date_added) as Year_Added,
    round(sum(v.watch_hours_millions),2) as Total_Watch_Hours
from netflix_titles_clean t
join netflix_viewership_clean v
    on t.show_id = v.show_id
group by year(t.date_added)
order by Year_Added;

-- 18.Which genre gives highest return on investment?

select t.genre,(sum(watch_hours_millions) / sum(budget_millions)) as ROI
from netflix_titles_clean as t
join netflix_viewership_clean  as v
on t.show_id=v.show_id
group by t.genre
order by ROI desc
limit 1;


-- 19. Which content rating generates highest engagement?

select 
    t.rating,
    round(avg(v.Watch_Hours),2) as Avg_Watch_Hours
from netflix_titles_clean t
join (
    select show_id, sum(watch_hours_millions) as Watch_Hours
    from netflix_viewership_clean
    group by show_id
) v
on t.show_id = v.show_id
group by t.rating
order by Avg_Watch_Hours desc
limit 1;


 -- Q20. Build Overall Performance Score for Each Show
/*
IMDb score
User rating
Watch hours
Completion rate
Subscription price influence
*/
SELECT 
    t.show_id,
    t.imdb_score AS IMDB_Score,
    r.rating AS Avg_User_Rating,
    s.price AS Total_Subscription_Price,
    v.watch_hours AS Total_Watch_Hours,
    v.completion AS Avg_Completion_Rate
FROM netflix_titles_clean AS t

LEFT JOIN (
    SELECT show_id, AVG(rating) AS rating
    FROM netflix_reviews_clean
    GROUP BY show_id
) AS r ON t.show_id = r.show_id

LEFT JOIN (
    SELECT show_id, SUM(subscription_price) AS price
    FROM netflix_subscriptions_clean
    GROUP BY show_id
) AS s ON t.show_id = s.show_id

LEFT JOIN (
    SELECT 
        show_id,
        SUM(watch_hours_millions) AS watch_hours,
        AVG(completion_rate) AS completion
    FROM netflix_viewership_clean
    GROUP BY show_id
) AS v ON t.show_id = v.show_id;

