-- Creating Schema
create schema practice;

-- Getting into Schema
use practice;

-- Getting total count of rows for all the tables in the Schema
SELECT table_name, table_rows
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'practice';

-- Identifying column names having Null values in movies table
select * from movies;
SELECT MAX(id IS NULL) id,
       MAX(title IS NULL) title,
       MAX(year IS NULL) year,
       MAX(date_published IS NULL) date_published,
       MAX(duration IS NULL) duration,
       MAX(country IS NULL) country,
       sum(worlwide_gross_income IS NULL) worlwide_gross_income,
       MAX(languages IS NULL) languages,
       MAX(production_company IS NULL) production_company
FROM movies;

-- Identifying movies trend by Year and month
select Year, count(*) Num_Movies from movies
group by Year;

select cast(replace(substr(date_published, 1, 2), '/', '') as UNSIGNED) Monthly, 
count(*) Num_Movies from movies
group by cast(replace(substr(date_published, 1, 2), '/', '') as UNSIGNED)
order by 1;

-- Calculate the number of movies produced in the USA or India in the year 2019
select count(*) Num_Movies from movies
where country in ('India', 'USA') and Year = 2019;

-- Retrieve the unique list of genres present in the dataset.
select distinct genre from genre;

-- Identify the genre with the highest number of movies produced overall
select genre, count(*) Movie_Count from genre
group by genre order by 2 desc limit 1;

-- Determine the count of movies that belong to only one genre
select genre, count(*) Movie_Count from genre
group by genre order by 2 desc;

-- Calculate the average duration of movies in each genre
select a.genre, avg(b.duration) average_duaration from genre a, movies b
where a.movie_id = b.id group by a.genre; 

-- Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced
select * from (select genre, rank() over(order by count(*) desc) ranks from genre
group by genre) a where genre = 'Thriller';

-- Retrieve the minimum and maximum values in each column of the ratings table 
select max(avg_rating), min(avg_rating), 
max(total_votes), min(total_votes), 
max(median_rating), min(median_rating) from ratings;

-- Identify the top 10 movies based on average rating
select b.title, a.avg_rating from ratings a, movies b 
where a.movie_id = b.id
order by 2 desc limit 10;

-- Summarise the ratings table based on movie counts by median ratings
select median_rating, count(*) from ratings
group by median_rating order by 2 desc;

-- Identify the production house that has produced the most number of hit movies (average rating > 8)
select b.production_company, a.avg_rating from ratings a, movies b 
where a.movie_id = b.id and a.avg_rating > 8 and b.production_company != ''
order by 2 desc;

-- Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes
select count(*) from ratings a, movies b 
where a.movie_id = b.id and a.total_votes > 1000 and b.country = 'USA' and b.year = 2017 and 
cast(replace(substr(b.date_published, 1, 2), '/', '') as UNSIGNED);

-- Retrieve movies of each genre starting with the word 'The' and having an average rating > 8
select b.title, a.avg_rating from ratings a, movies b 
where a.movie_id = b.id and a.avg_rating > 8 and b.title like 'The %';

-- Identify the columns in the names table that have null values
SELECT MAX(id IS NULL) id,
       MAX(name IS NULL) name,
       MAX(height IS NULL) height,
       MAX(date_of_birth IS NULL) date_of_birth,
       MAX(known_for_movies IS NULL) known_for_movies
FROM names;

-- Determine the top three directors in the top three genres with movies having an average rating > 8
select a.name, c.avg_rating from names a, director_mapping b, ratings c
where a.id = b.name_id and b.movie_id = c.movie_id and c.avg_rating > 8
order by 2 desc limit 3;

-- Find the top two actors whose movies have a median rating >= 8
select * from role_mapping;
select a.name, c.median_rating from names a, role_mapping b, ratings c
where a.id = b.name_id and b.movie_id = c.movie_id and c.median_rating >= 8
order by 2 desc limit 2;

-- Identify the top three production houses based on the number of votes received by their movies
select a.production_company, sum(b.total_votes) total_votes from movies a, ratings b
where a.id = b.movie_id
group by a.production_company
order by 2 desc limit 3;

-- Rank actors based on their average ratings in Indian movies released in India
select a.name, b.avg_rating, rank() over(order by b.avg_rating desc) ranks from names a, ratings b, movies c, role_mapping d
where a.id = d.name_id and b.movie_id = d.movie_id and c.id = d.movie_id and c.country = 'India';

-- Identify the top five actresses in Hindi movies released in India based on their average ratings
select a.name, b.avg_rating, rank() over(order by b.avg_rating desc) ranks from names a, ratings b, movies c, role_mapping d
where a.id = d.name_id and b.movie_id = d.movie_id and c.id = d.movie_id and c.country = 'India' and c.languages = 'Hindi' 
and d.category = 'actress' limit 5;

-- Classify thriller movies based on average ratings into different categories
select a.title Title, 
	(case 
		when b.avg_rating > 8 then 'Excellent'
        when b.avg_rating between 6 and 8 then 'Good'
        when b.avg_rating between 3 and 5 then 'Average'
        else 'Flop' 
	end) 
        Category
from movies a, ratings b, genre c
where a.id = b.movie_id and a.id = c.movie_id and c.genre = 'Thriller' order by 1;

-- analyse the genre-wise running total and moving average of the average movie duration
select c.genre, (select sum(b.duration) from movies b where b.id <= a.id) Running_Total, 
(select avg(b.duration) from movies b where b.id <= a.id) Moving_Average
from movies a, genre c 
where a.id = c.movie_id order by 1;
    
-- Identify the five highest-grossing movies of each year that belong to the top three genres
select * from (select a.year, a.title, sum(a.worlwide_gross_income) worlwide_gross_income, 
rank() over(partition by a.year order by sum(a.worlwide_gross_income) desc) ranks from movies a, genre b, 
(select a.genre, sum(b.worlwide_gross_income) worlwide_gross_income
    from genre a, movies b where a.movie_id = b.id
    group by a.genre order by 2 desc limit 3) c
where a.id = b.movie_id and b.genre = c.genre group by a.year, a.title order by a.year, 3 desc) a 
where ranks <=5;

-- Determine the top two production houses that have produced the highest number of hits among multilingual movies
select a.production_company, count(*) from movies a, ratings b
where a.id = b.movie_id and b.avg_rating >= 6 and languages like '%,%' and a.production_company != ''
group by a.production_company order by 2 desc limit 2;

-- Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre
select a.name, count(*) cnt from names a, role_mapping b, genre c, ratings d
where a.id = b.name_id and b.category = 'actress' and 
b.movie_id = c.movie_id and c.genre = 'Drama' and b.movie_id = d.movie_id and d.avg_rating > 8
group by a.name order by 2 desc limit 3;

-- Retrieve details for the top nine directors based on the number of movies, 
-- including average inter-movie duration, ratings, and more
select a.name, count(*) as num_movies, avg(b.avg_rating) as avg_rating, avg(c.duration) avg_duration, 
min(b.avg_rating) min_rating, max(b.avg_rating) max_rating, sum(b.total_votes) total_votes, 
min(b.total_votes) min_votes, max(b.total_votes) max_votes, sum(case when b.avg_rating > 8 then 1 else 0 end) super_hits,
sum(case when b.avg_rating between 6 and 8 then 1 else 0 end) hits, 
sum(case when b.avg_rating between 3 and 5.9 then 1 else 0 end) average,
sum(case when b.avg_rating < 3 then 1 else 0 end) flops
from names a, ratings b, movies c, director_mapping d where a.id = d.name_id and d.movie_id = b.movie_id and
d.movie_id = c.id group by a.name order by 2 desc limit 9;

select a.name, count(*) as num_movies, avg(b.avg_rating) as avg_rating, avg(c.duration) avg_duration, 
min(b.avg_rating) min_rating, max(b.avg_rating) max_rating, sum(b.total_votes) total_votes, 
min(b.total_votes) min_votes, max(b.total_votes) max_votes, sum(case when b.avg_rating > 8 then 1 else 0 end) super_hits,
sum(case when b.avg_rating between 6 and 8 then 1 else 0 end) hits, 
sum(case when b.avg_rating between 3 and 5.9 then 1 else 0 end) average,
sum(case when b.avg_rating < 3 then 1 else 0 end) flops
from names a, ratings b, movies c, director_mapping d where a.id = d.name_id and d.movie_id = b.movie_id and
d.movie_id = c.id group by a.name order by 10 desc limit 9;

-- Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing
-- 1. Based on the Analysis Adventure, Action and Drama are the top 3 genres with highest worlwide grossing. So, choosing the script based
-- on these genres will result in high success 
-- 2. Directors James Mangold, Michael Powell, Emeric Pressburger, Mel Gibson and Noah Baumbach having good hits and super hits 
-- paring with them will result in high sucess
-- 3. Mel Novak and Christian Bale are the top two actors with median_rating of 10
-- 4. Month 1, 3, 9 and 10 having highest movie release trend
-- 5. Month 7 and 12 having low movie release trend