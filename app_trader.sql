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
	ROUND(ROUND(AVG(rating)*2, 0) / 2, 1) AS avg_rating_rounded,
	ROUND(SUM(review_count)/1000000, 2) AS review_count_millions,
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
	AND SUM(review_count) >= 1000000 
ORDER BY net_profit DESC, review_count_millions DESC
LIMIT 10;