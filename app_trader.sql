--Exploration

SELECT *
FROM play_store_apps 
WHERE genres ILIKE '%Game%' 
ORDER BY rating DESC
LIMIT 10

SELECT DISTINCT genres
FROM play_store_apps

SELECT  primary_genre
FROM app_store_apps 
GROUP BY primary_genre
ORDER BY COUNT(*) DESC

SELECT *
FROM app_store_apps
WHERE primary_genre = 'Games' AND rating = 5.0 AND price BETWEEN 0 AND 1
--ORDER BY rating DESC
-- LIMIT 30

SELECT *
FROM app_store_apps
WHERE primary_genre = 'Education' AND rating = 5.0 AND price BETWEEN 0 AND 1

SELECT DISTINCT currency
FROM app_store_apps

SELECT COUNT(*) FROM app_store_apps 7197
SELECT COUNT(*) FROM play_store_apps 10840 

--Apple query

SELECT name, review_count::numeric, content_rating
FROM app_store_apps
WHERE primary_genre = 'Games' 
	AND rating = 5.0 
	AND price BETWEEN 0 AND 1
ORDER BY review_count DESC

--Play query

SELECT name, review_count::numeric, content_rating, rating
FROM play_store_apps
WHERE category = 'GAME' --there are a lot listed under FAMILY but not all in family are games...
-- 	(category = 'GAME'
-- 	OR genres ILIKE '%Game%') --go in later and see what other words tag games
	AND rating = 5.0 --necessary to lower to 4.5 since there aren't any 5.0 games, but more may show up after fixing game filter
	AND REPLACE(price, '$', '')::numeric BETWEEN 0 AND 1
ORDER BY review_count DESC

SELECT *
FROM play_store_apps
--WHERE category = 'FAMILY'
WHERE name ILIKE '%plants%zombies%'

SELECT category
FROM play_store_apps
GROUP BY category
ORDER BY COUNT(*)

---Unioned query---
	--check for other categories on Play store that might be games
	--possibly filter by num_reviews over 1mil? Or include potentially up and coming games?
	--format $ as money...

WITH apps AS 
(
	(SELECT name, rating, review_count::numeric, price
	FROM app_store_apps
	WHERE primary_genre = 'Games' 
	)
	UNION ALL
	(
	SELECT name, rating, review_count::numeric, REPLACE(price, '$', '')::numeric
	FROM play_store_apps
	WHERE category IN ('GAME', 'FAMILY'))
)
SELECT 
	name, 
	COUNT(name), --remove this later, it's just to check my work
	ROUND(ROUND(AVG(rating)*2, 0) / 2, 1) AS avg_rating_rounded,
	ROUND(SUM(review_count)/1000000, 2) AS review_count_millions, -- edit to report in millions
	MAX(price) AS price,
	CASE WHEN MAX(price) <= 1 THEN 10000 
		ELSE MAX(price)*10000 END 
		AS purchase_price,
	(CASE WHEN name IN (SELECT name FROM app_store_apps) THEN 5000 ELSE 0 END +
		CASE WHEN name IN (SELECT name FROM play_store_apps) THEN 5000 ELSE 0 END) * 12 
		AS yearly_income, 
	CASE WHEN ROUND(AVG(rating)*2, 0) / 2 = 5.0 THEN 11 
		WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.5 THEN 10 
		WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.0 THEN 9 
		END 
		AS lifespan,
	ROUND(
		(((CASE WHEN name IN (SELECT name FROM app_store_apps) THEN 5000 ELSE 0 END +
			CASE WHEN name IN (SELECT name FROM play_store_apps) THEN 5000 ELSE 0 END) * 12)
		* 
		(CASE WHEN ROUND(AVG(rating)*2, 0) / 2 = 5.0 THEN 11 
			WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.5 THEN 10 
			WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.0 THEN 9 END))
		- 
		((CASE WHEN ROUND(AVG(rating)*2, 0) / 2 = 5.0 THEN 11 
			WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.5 THEN 10 
			WHEN ROUND(AVG(rating)*2, 0) / 2 = 4.0 THEN 9 END) 
		* 1000) 
		- 
		(CASE WHEN MAX(price) <= 1 THEN 10000 ELSE MAX(price)*10000 END)
		, 0)
		AS net_profit -- (yearly_income * lifespan) - (lifespan * 1000) - purchase price
FROM apps
GROUP BY name
HAVING ROUND(ROUND(AVG(rating)*2, 0) / 2, 1) >= 4.0
	AND SUM(review_count) >= 1000000 	--Possibly filter
ORDER BY net_profit DESC, review_count_millions DESC
LIMIT 10;