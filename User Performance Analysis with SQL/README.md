# User Performance Analysis with SQL

## About This Project

As part of my data science and SQL learning journey, I built this project to practise writing real-world SQL queries against a structured dataset. The dataset comes from an online learning platform and tracks how users engage with coding questions over time including how many they get right, how many they get wrong, and how many points they accumulate.

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

## SQL Concepts Practised

- **Aggregation**: `COUNT`, `SUM`, `AVG` to summarise submission data
- **Date functions**: `TO_CHAR()` and `EXTRACT()` to group by day and week
- **Conditional aggregation**: `CASE WHEN` to separate correct from incorrect submissions
- **Window functions**: `DENSE_RANK()` to rank users within date partitions
- **CTEs**: breaking complex logic into readable, reusable steps with `WITH`

---

## What I Learned

Working through this project helped me get comfortable with some of the trickier parts of SQL that often come up in data analytics roles. Conditional aggregation with `CASE WHEN` was particularly useful for splitting a single column (points) into multiple meaningful metrics. Using `DENSE_RANK()` inside a CTE to produce per-day and per-week rankings felt like a big step up from basic `GROUP BY` queries.

---

## Tools Used

- PostgreSQL
- pgAdmin / any SQL client

---

*Project by Euodia Sam - February 2026*
