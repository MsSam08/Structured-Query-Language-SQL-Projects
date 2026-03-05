# SQL Portfolio Projects

Welcome to my SQL portfolio repository 👋🏽

This repository showcases hands-on SQL projects focused on solving real-world business problems using relational databases. These projects demonstrate my ability to design schemas, write efficient queries, build stored procedures, and perform analytical reporting using SQL.

> This repository is actively growing, more projects will be added as I continue building. Check back for updates!

---

## Projects Included

### 📚 1. Library Management System

**Description:** A relational database system simulating a real-world library workflow, from book cataloguing and member management through to staff performance tracking and overdue fine calculation.

**Skills Demonstrated:**
- Database schema design with foreign key relationships across 6 tables
- Book issuance and return tracking with stored procedures
- Automatic inventory status updates using conditional logic
- Overdue detection and fine calculation with CTAS
- Branch performance reporting with multi-table joins

---

### 📊 2. User Submission Performance Analysis

**Description:** An analysis of user activity on an online learning platform, examining submission patterns, accuracy rates, and engagement trends over time.

**Skills Demonstrated:**
- Aggregation and ranking of user performance metrics
- Conditional counting using `CASE WHEN` to separate correct and incorrect submissions
- Daily and weekly leaderboards using `DENSE_RANK()` and window functions
- Time-based trend analysis using `LAG()` for week-on-week comparisons
- Consistency tracking across active days per user

---

### ☕ 3. Monday Coffee - Expansion Analysis

**Description:** A market analysis project for a fictional coffee brand selling online across Indian cities. The goal was to identify the top three cities for opening new physical store locations based on consumer demand, revenue performance, and cost efficiency.

**Skills Demonstrated:**
- Multi-table joins across sales, customers, city, and product data
- Revenue and customer aggregation by city and time period
- Month-on-month sales growth rate using `LAG()` window functions
- Market potential scoring combining rent, revenue, and population estimates
- CTE-based query structuring for complex multi-step analysis

---

## SQL Concepts Covered Across Projects

| Concept | Projects |
|---------|----------|
| Schema design & foreign keys | Library Management |
| CRUD operations | Library Management |
| Aggregation (`COUNT`, `SUM`, `AVG`) | All projects |
| Conditional aggregation (`CASE WHEN`) | Library Management, User Analysis |
| Window functions (`DENSE_RANK`, `LAG`) | User Analysis, Monday Coffee |
| CTEs (`WITH`) | User Analysis, Monday Coffee |
| Stored procedures | Library Management |
| CTAS (Create Table As Select) | Library Management, Monday Coffee |
| Date functions (`EXTRACT`, `TO_CHAR`) | User Analysis, Monday Coffee |
| Multi-table joins | All projects |

---

## Tools Used

- PostgreSQL
- pgAdmin / any SQL client

---

*Portfolio by Euodia Sam*
