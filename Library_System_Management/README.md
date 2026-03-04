# Library Management System | SQL Project

## About This Project

This is an intermediate-level SQL project where I designed and queried a relational database for a Library Management System. The project covers everything from setting up the database schema and populating it with data, to writing advanced queries involving joins, stored procedures, and window functions.

The aim was to simulate how a real library would track its books, members, employees, and branches — and use SQL to extract useful operational insights from that data.

---

## Objectives

1. **Design and set up a relational database** with properly structured tables and foreign key relationships.
2. **Perform CRUD operations** — inserting, reading, updating, and deleting records across multiple tables.
3. **Use CTAS (Create Table As Select)** to generate summary and reporting tables from query results.
4. **Write advanced SQL queries** involving multi-table joins, aggregation, subqueries, and date arithmetic.
5. **Build stored procedures** to automate book issuance and return workflows with conditional logic.
6. **Analyse library operations** — including overdue tracking, fine calculation, branch performance, and employee productivity.

---

## Database: `library_db`

The database consists of six interrelated tables:

| Table | Description |
|-------|-------------|
| `branch` | Library branches and their managers |
| `employees` | Staff working across branches |
| `members` | Registered library members |
| `books` | Book catalogue with pricing and availability |
| `issued_status` | Records of books issued to members |
| `return_status` | Records of books returned by members |

---

## Database Setup
---
![Database](https://github.com/MsSam08/Machine-Learning-projects-AI-DL-included-/blob/main/The%20Customers%20Who%20Disappeared/feture%20importance.png)
### Schema Creation

```sql
CREATE DATABASE library_db;

CREATE TABLE branch (
    branch_id     VARCHAR(10) PRIMARY KEY,
    manager_id    VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no    VARCHAR(15)
);

CREATE TABLE employees (
    emp_id    VARCHAR(10) PRIMARY KEY,
    emp_name  VARCHAR(30),
    position  VARCHAR(30),
    salary    DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE members (
    member_id      VARCHAR(10) PRIMARY KEY,
    member_name    VARCHAR(30),
    member_address VARCHAR(30),
    reg_date       DATE
);

CREATE TABLE books (
    isbn         VARCHAR(50) PRIMARY KEY,
    book_title   VARCHAR(80),
    category     VARCHAR(30),
    rental_price DECIMAL(10,2),
    status       VARCHAR(10),
    author       VARCHAR(30),
    publisher    VARCHAR(30)
);

CREATE TABLE issued_status (
    issued_id         VARCHAR(10) PRIMARY KEY,
    issued_member_id  VARCHAR(30),
    issued_book_name  VARCHAR(80),
    issued_date       DATE,
    issued_book_isbn  VARCHAR(50),
    issued_emp_id     VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id)    REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

CREATE TABLE return_status (
    return_id        VARCHAR(10) PRIMARY KEY,
    issued_id        VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date      DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```

---

## CRUD Operations

### Task 1: Add a New Book to the Catalogue
```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

### Task 2: Update a Member's Address
```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
```

### Task 3: Delete a Record from Issued Status
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

### Task 4: Retrieve All Books Issued by a Specific Employee
```sql
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';
```

### Task 5: Find Members Who Have Issued More Than One Book
```sql
SELECT
    issued_emp_id,
    COUNT(*) AS total_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;
```

---

## CTAS — Create Table As Select

### Task 6: Summarise Issue Count Per Book
```sql
CREATE TABLE book_issued_cnt AS
SELECT
    b.isbn,
    b.book_title,
    COUNT(ist.issued_id) AS issue_count
FROM issued_status AS ist
JOIN books AS b ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;
```

---

## Data Analysis Queries

### Task 7: Retrieve All Books in a Specific Category
```sql
SELECT * FROM books
WHERE category = 'Classic';
```

### Task 8: Total Rental Income by Category
```sql
SELECT
    b.category,
    SUM(b.rental_price) AS total_income,
    COUNT(*) AS times_issued
FROM issued_status AS ist
JOIN books AS b ON b.isbn = ist.issued_book_isbn
GROUP BY b.category
ORDER BY total_income DESC;
```

### Task 9: Members Who Registered in the Last 180 Days
```sql
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';
```

### Task 10: Employees with Their Branch and Manager Details
```sql
SELECT
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name AS manager_name
FROM employees AS e1
JOIN branch AS b      ON e1.branch_id = b.branch_id
JOIN employees AS e2  ON e2.emp_id = b.manager_id;
```

### Task 11: Create a Table of Premium-Priced Books
```sql
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;
```

### Task 12: Books Not Yet Returned
```sql
SELECT ist.*
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;
```

---

## Advanced SQL

### Task 13: Identify Members with Overdue Books
**Logic:** Any book not returned within 30 days is considered overdue.

```sql
SELECT
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date AS days_overdue
FROM issued_status AS ist
JOIN members AS m       ON m.member_id = ist.issued_member_id
JOIN books AS bk        ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND (CURRENT_DATE - ist.issued_date) > 30
ORDER BY days_overdue DESC;
```

### Task 14: Stored Procedure — Process a Book Return
**Logic:** When a member returns a book, insert the return record and update the book's status back to 'yes'.

```sql
CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id    VARCHAR(10),
    p_issued_id    VARCHAR(10),
    p_book_quality VARCHAR(10)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_isbn      VARCHAR(50);
    v_book_name VARCHAR(80);
BEGIN
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books SET status = 'yes' WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning: %', v_book_name;
END;
$$;

-- Example call
CALL add_return_records('RS138', 'IS135', 'Good');
```

### Task 15: Branch Performance Report
```sql
CREATE TABLE branch_reports AS
SELECT
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id)  AS books_issued,
    COUNT(rs.return_id)   AS books_returned,
    SUM(bk.rental_price)  AS total_revenue
FROM issued_status AS ist
JOIN employees AS e    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b       ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books AS bk       ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;
```

### Task 16: Active Members in the Last 2 Months
```sql
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL '2 months'
);
```

### Task 17: Top 3 Employees by Books Processed
```sql
SELECT
    e.emp_name,
    b.branch_id,
    b.branch_address,
    COUNT(ist.issued_id) AS books_processed
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b    ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id, b.branch_address
ORDER BY books_processed DESC
LIMIT 3;
```

### Task 18: Members Who Repeatedly Issue Damaged Books
```sql
SELECT
    m.member_name,
    bk.book_title,
    COUNT(ist.issued_id) AS times_issued_damaged
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books AS bk  ON bk.isbn = ist.issued_book_isbn
WHERE bk.status = 'damaged'
GROUP BY m.member_name, bk.book_title
HAVING COUNT(ist.issued_id) > 2
ORDER BY times_issued_damaged DESC;
```

### Task 19: Stored Procedure — Issue a Book
**Logic:** Check if the book is available. If yes, issue it and mark it as unavailable. If no, notify the caller.

```sql
CREATE OR REPLACE PROCEDURE issue_book(
    p_issued_id         VARCHAR(10),
    p_issued_member_id  VARCHAR(30),
    p_issued_book_isbn  VARCHAR(30),
    p_issued_emp_id     VARCHAR(10)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    SELECT status INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books SET status = 'no' WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book issued successfully. ISBN: %', p_issued_book_isbn;
    ELSE
        RAISE NOTICE 'Book is currently unavailable. ISBN: %', p_issued_book_isbn;
    END IF;
END;
$$;

-- Example calls
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');
```

### Task 20: CTAS — Overdue Books with Fine Calculation
**Logic:** Each overdue day costs $0.50.

```sql
CREATE TABLE overdue_fines AS
SELECT
    ist.issued_member_id AS member_id,
    COUNT(*)             AS overdue_books,
    SUM((CURRENT_DATE - ist.issued_date) * 0.50) AS total_fine
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND (CURRENT_DATE - ist.issued_date) > 30
GROUP BY ist.issued_member_id
ORDER BY total_fine DESC;
```

---

## SQL Concepts Covered

- **CRUD Operations** — Insert, Select, Update, Delete across multiple tables
- **Joins** — INNER, LEFT JOIN across up to four tables simultaneously
- **Aggregation** — `COUNT`, `SUM` with `GROUP BY` and `HAVING`
- **CTAS** — Creating derived tables from query results for reporting
- **Subqueries** — Filtering with nested SELECT statements
- **Stored Procedures** — Reusable procedural logic with conditional branching
- **Date Arithmetic** — Calculating overdue days and filtering by date intervals

---

## What I Learned

This project gave me hands-on experience with relational database design — understanding how foreign keys enforce data integrity across tables was a key takeaway. Writing the stored procedures for issuing and returning books was the most challenging part, as it required combining DML statements with conditional logic inside a single transaction. The overdue fine calculation using CTAS also reinforced how powerful it is to create persistent summary tables directly from query results.

---

## Tools Used

- PostgreSQL
- pgAdmin / any SQL client

---

*Project by Euodia Sam — 2026*
