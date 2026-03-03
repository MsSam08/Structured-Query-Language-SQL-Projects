-- SQL Mini Project 1
-- SQL Mentor User Performance

-- DROP TABLE user_submissions; 

CREATE TABLE user_submissions (
    id SERIAL PRIMARY KEY,
    user_id BIGINT,
    question_id INT,
    points INT,
    submitted_at TIMESTAMP WITH TIME ZONE,
    username VARCHAR(50)
);

SELECT * FROM user_submissions;


-- Q.1 List all distinct users and their stats (return user_name, total_submissions, points earned)
-- Q.2 Calculate the daily average points for each user.
-- Q.3 Find the top 3 users with the most positive submissions for each day.
-- Q.4 Find the top 5 users with the highest number of incorrect submissions.
-- Q.5 Find the top 10 performers for each week.


-- Please note for each questions return current stats for the users
-- user_name, total points earned, correct submissions, incorrect submissions no


-- -------------------
-- My Solutions
-- -------------------

-- Q.1 List all distinct users and their stats (return user_name, total_submissions, points earned)

-- SELECT 
-- DISTINCT username   - COUNT(DISTINCT username)
-- FROM user_submissions


SELECT 
	username,
	COUNT(id) AS total_submissions,
	SUM(points) AS points_earned
FROM user_submissions
GROUP BY username
ORDER BY total_submissions DESC;


-- -- Q.2 Calculate the daily average points for each user.
-- each day
-- each user and their daily avg points
-- group by day and user

SELECT * FROM user_submissions;

SELECT 
	-- EXTRACT(DAY FROM submitted_at) AS day,
	TO_CHAR(submitted_at, 'DD-MM') AS day,
	username,
	AVG(points) AS daily_avg_points
FROM user_submissions
GROUP BY 1, 2
ORDER BY username;


-- Q.3 Find the top 3 users with the most correct submissions for each day.

-- each day
-- most correct submissions


SELECT * FROM user_submissions;

-- SELECT 
-- 	-- EXTRACT(DAY FROM submitted_at) AS day,
-- 	TO_CHAR(submitted_at, 'DD-MM') AS daily, username,
-- 	SUM(CASE 
-- 		WHEN points > 0 THEN 1 ELSE 0
-- 	END) AS correct_submissions
-- FROM user_submissions
-- GROUP BY 1, 2
-- ORDER BY username;
	

WITH daily_submissions
AS
(
	SELECT 
		-- EXTRACT(DAY FROM submitted_at) as day,
		TO_CHAR(submitted_at, 'DD-MM') as daily,
		username,
		SUM(CASE 
			WHEN points > 0 THEN 1 ELSE 0
		END) as correct_submissions
	FROM user_submissions
	GROUP BY 1, 2
),
users_rank
as
(SELECT 
	daily,
	username,
	correct_submissions,
	DENSE_RANK() OVER(PARTITION BY daily ORDER BY correct_submissions DESC) as rank
FROM daily_submissions
)

SELECT 
	daily,
	username,
	correct_submissions
FROM users_rank
WHERE rank <= 3;

-- Q.4 Find the top 5 users with the highest number of incorrect submissions.

-- SELECT
-- 	username,
-- 	SUM(CASE 
-- 		WHEN points < 0 THEN 1 ELSE 0
-- 	END) as incorrect_submissions,
-- 	SUM(CASE 
-- 			WHEN points > 0 THEN 1 ELSE 0
-- 		END) as correct_submissions
-- FROM user_submissions
-- GROUP BY 1
-- ORDER BY incorrect_submissions DESC
-- LIMIT 5;

SELECT 
	username,
	SUM(CASE 
		WHEN points < 0 THEN 1 ELSE 0
	END) AS incorrect_submissions,
	SUM(CASE 
			WHEN points > 0 THEN 1 ELSE 0
		END) AS correct_submissions,
	SUM(CASE 
		WHEN points < 0 THEN points ELSE 0
	END) AS incorrect_submissions_points,
	SUM(CASE 
			WHEN points > 0 THEN points ELSE 0
		END) AS correct_submissions_points_earned,
	SUM(points) AS points_earned
FROM user_submissions
GROUP BY 1
ORDER BY incorrect_submissions DESC
-- LIMIT 5

-- Q.5 Find the top 10 performers for each week.


SELECT *  
FROM
(
	SELECT 
		-- WEEK()
		EXTRACT(WEEK FROM submitted_at) as week_no,
		username,
		SUM(points) as total_points_earned,
		DENSE_RANK() OVER(PARTITION BY EXTRACT(WEEK FROM submitted_at) ORDER BY SUM(points) DESC) as rank
	FROM user_submissions
	GROUP BY 1, 2
	ORDER BY week_no, total_points_earned DESC
)
WHERE rank <= 10

-- Q6. Most Active Hour of the Day

SELECT 
    EXTRACT(HOUR FROM submitted_at) AS hour_of_day,
    COUNT(id) AS total_submissions,
    ROUND(AVG(points), 2) AS avg_points,
    SUM(CASE WHEN points > 0 THEN 1 ELSE 0 END) AS correct_submissions,
    SUM(CASE WHEN points < 0 THEN 1 ELSE 0 END) AS incorrect_submissions
FROM user_submissions
GROUP BY 1
ORDER BY total_submissions DESC;

-- Q7. Monthly Points Trend Per User
SELECT 
    TO_CHAR(submitted_at, 'YYYY-MM') AS month,
    username,
    SUM(points) AS total_points,
    COUNT(id) AS total_submissions
FROM user_submissions
GROUP BY 1, 2
ORDER BY username, month;

-- Q8. Best vs Worst Single Day for Each User
WITH daily_totals AS (
    SELECT 
        username,
        TO_CHAR(submitted_at, 'DD-MM-YYYY') AS day,
        SUM(points) AS daily_points
    FROM user_submissions
    GROUP BY 1, 2
)
SELECT 
    username,
    MAX(daily_points) AS best_day_points,
    MIN(daily_points) AS worst_day_points,
    ROUND(AVG(daily_points), 2) AS avg_daily_points,
    MAX(daily_points) - MIN(daily_points) AS points_range
FROM daily_totals
GROUP BY username
ORDER BY best_day_points DESC;

-- Q9. Most Consistent Users (Active Days Count)
WITH daily_active AS (
    SELECT 
        username,
        DATE(submitted_at) AS active_day
    FROM user_submissions
    GROUP BY 1, 2
),
consistency AS (
    SELECT 
        username,
        COUNT(active_day) AS active_days
    FROM daily_active
    GROUP BY username
)
SELECT 
    username,
    active_days,
    DENSE_RANK() OVER(ORDER BY active_days DESC) AS consistency_rank
FROM consistency
ORDER BY active_days DESC;

-- Q10. Weekly Points Change Per User (Week-on-Week Growth)
WITH weekly_points AS (
    SELECT 
        username,
        EXTRACT(WEEK FROM submitted_at) AS week_no,
        SUM(points) AS total_points
    FROM user_submissions
    GROUP BY 1, 2
)
SELECT 
    username,
    week_no,
    total_points,
    LAG(total_points) OVER(PARTITION BY username ORDER BY week_no) AS prev_week_points,
    total_points - LAG(total_points) OVER(PARTITION BY username ORDER BY week_no) AS points_change
FROM weekly_points
ORDER BY week_no, total_points DESC;