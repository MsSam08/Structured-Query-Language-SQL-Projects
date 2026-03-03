# User Performance Analysis with SQL

## About This Project

As part of my data science and SQL learning journey, I built this project to practise writing real-world SQL queries against a structured dataset. The dataset comes from an online learning platform and tracks how users engage with coding questions over time — including how many they get right, how many they get wrong, and how many points they accumulate.

The goal was simple: use SQL to turn raw submission data into meaningful insights about user behaviour and performance.

---

## Dataset

The dataset is a single table called `user_submissions`. Each row represents one question attempt by a user and contains the following fields:

| Column | Description |
|--------|-------------|
| `id` | Unique submission ID |
| `user_id` | Unique identifier for the user |
| `question_id` | The question that was attempted |
| `points` | Points awarded (positive = correct, negative = incorrect) |
| `submitted_at` | Timestamp of the submission |
| `username` | Display name of the user |

---

## Questions I Explored

### Q1. Overall User Stats
**What is each user's total number of submissions and total points earned?**

```sql
SELECT 
    username,
    COUNT(id) AS total_submissions,
    SUM(points) AS points_earned
FROM user_submissions
GROUP BY username
ORDER BY total_submissions DESC;
```

---

### Q2. Daily Average Points Per User
**On each day, what was the average number of points each user earned?**

```sql
SELECT 
    TO_CHAR(submitted_at, 'DD-MM') AS day,
    username,
    AVG(points) AS daily_avg_points
FROM user_submissions
GROUP BY 1, 2
ORDER BY username;
```

---

### Q3. Top 3 Users by Correct Submissions Each Day
**Who were the top 3 most accurate users on each individual day?**

```sql
WITH daily_submissions AS (
    SELECT 
        TO_CHAR(submitted_at, 'DD-MM') AS daily,
        username,
        SUM(CASE WHEN points > 0 THEN 1 ELSE 0 END) AS correct_submissions
    FROM user_submissions
    GROUP BY 1, 2
),
users_rank AS (
    SELECT 
        daily,
        username,
        correct_submissions,
        DENSE_RANK() OVER(PARTITION BY daily ORDER BY correct_submissions DESC) AS rank
    FROM daily_submissions
)
SELECT 
    daily,
    username,
    correct_submissions
FROM users_rank
WHERE rank <= 3;
```

---

### Q4. Top 5 Users with the Most Incorrect Submissions
**Which users struggled the most, and how does that compare to their correct attempts?**

```sql
SELECT 
    username,
    SUM(CASE WHEN points < 0 THEN 1 ELSE 0 END) AS incorrect_submissions,
    SUM(CASE WHEN points > 0 THEN 1 ELSE 0 END) AS correct_submissions,
    SUM(CASE WHEN points < 0 THEN points ELSE 0 END) AS points_lost,
    SUM(CASE WHEN points > 0 THEN points ELSE 0 END) AS points_earned,
    SUM(points) AS net_points
FROM user_submissions
GROUP BY 1
ORDER BY incorrect_submissions DESC
LIMIT 5;
```

---

### Q5. Top 10 Performers Each Week
**Who were the highest scorers when ranked by total points per week?**

```sql
SELECT * FROM (
    SELECT 
        EXTRACT(WEEK FROM submitted_at) AS week_no,
        username,
        SUM(points) AS total_points_earned,
        DENSE_RANK() OVER(
            PARTITION BY EXTRACT(WEEK FROM submitted_at) 
            ORDER BY SUM(points) DESC
        ) AS rank
    FROM user_submissions
    GROUP BY 1, 2
    ORDER BY week_no, total_points_earned DESC
)
WHERE rank <= 10;
```

---

### Q6. Most Active Hour of the Day
**At what hour of the day do users submit the most answers, and does activity level affect accuracy?**

```sql
SELECT 
    EXTRACT(HOUR FROM submitted_at) AS hour_of_day,
    COUNT(id) AS total_submissions,
    ROUND(AVG(points), 2) AS avg_points,
    SUM(CASE WHEN points > 0 THEN 1 ELSE 0 END) AS correct_submissions,
    SUM(CASE WHEN points < 0 THEN 1 ELSE 0 END) AS incorrect_submissions
FROM user_submissions
GROUP BY 1
ORDER BY total_submissions DESC;
```

---

### Q7. Monthly Points Trend Per User
**How does each user's total points and submission volume change from month to month?**

```sql
SELECT 
    TO_CHAR(submitted_at, 'YYYY-MM') AS month,
    username,
    SUM(points) AS total_points,
    COUNT(id) AS total_submissions
FROM user_submissions
GROUP BY 1, 2
ORDER BY username, month;
```

---

### Q8. Best vs Worst Single Day for Each User
**What was each user's highest-scoring day and lowest-scoring day, and how wide is the gap?**

```sql
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
```

---

### Q9. Most Consistent Users (Active Days Count)
**Which users showed up most consistently by submitting on the highest number of distinct days?**

```sql
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
```

---

### Q10. Weekly Points Change Per User (Week-on-Week Growth)
**How did each user's weekly points total change compared to the previous week?**

```sql
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
```

---

## SQL Concepts Practised

- **Aggregation**: `COUNT`, `SUM`, `AVG` to summarise submission data
- **Date functions**: `TO_CHAR()`, `EXTRACT()`, and `DATE()` to group by hour, day, week, and month
- **Conditional aggregation**: `CASE WHEN` to separate correct from incorrect submissions
- **Window functions**: `DENSE_RANK()` and `LAG()` to rank users and compare across time periods
- **CTEs**: breaking complex logic into readable, reusable steps with `WITH`

---

## What I Learned

Working through this project helped me get comfortable with some of the trickier parts of SQL that often come up in data analytics roles. Conditional aggregation with `CASE WHEN` was particularly useful for splitting a single column (points) into multiple meaningful metrics. Using `DENSE_RANK()` inside a CTE to produce per-day and per-week rankings felt like a big step up from basic `GROUP BY` queries. The extended questions pushed me further using `LAG()` to track week-on-week change was a great introduction to time-series thinking in SQL, and building the consistency analysis made me think about user behaviour in a more nuanced way.

---

## Tools Used

- PostgreSQL
- pgAdmin / any SQL client

---

*Project by Euodia Sam - February 2026*
