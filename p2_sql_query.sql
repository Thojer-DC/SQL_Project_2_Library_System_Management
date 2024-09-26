-- Project 2


--Create tables

--books table
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
	isbn VARCHAR(50) PRIMARY KEY,
	book_title VARCHAR(80),
	category VARCHAR(30),
	rental_price DECIMAL(10,2),
	status VARCHAR(10),
	author VARCHAR(30), 
	publisher VARCHAR(30)
);


-- branch table
DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(
	branch_id VARCHAR(10) PRIMARY KEY,
	manager_id VARCHAR(10),
	branch_address VARCHAR(30),
	contact_no VARCHAR(15)

);

-- members table
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
	member_id VARCHAR(10) PRIMARY KEY,
	member_name VARCHAR(55),
	member_address VARCHAR(55),
	reg_date DATE
);

-- employees table
DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(
	emp_id VARCHAR(15) PRIMARY KEY,
	emp_name VARCHAR(55),
	position VARCHAR(30),
	salary DECIMAL(10,2),
	branch_id VARCHAR(10), -- FOREIGN KEY
	FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);


-- issued_status table
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
	issued_id VARCHAR(15) PRIMARY KEY,
	issued_member_id VARCHAR(10),  -- FOREIGN KEY
	issued_book_name VARCHAR(55),
	issued_date DATE,
	issued_book_isbn VARCHAR(50), -- FOREIGN KEY
	issued_emp_id VARCHAR(15), -- FOREIGN KEY
	FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
	FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn),
	FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id)
);

-- return_status table
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
	return_id VARCHAR(15) PRIMARY KEY,
	issued_id VARCHAR(15),  -- FOREIGN KEY
	return_book_name VARCHAR(55),
	return_date DATE,
	return_book_isbn VARCHAR(15), -- FOREIGN KEY
	FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id)
);


-- Project TASK


-- ### 2. CRUD Operations


-- Task 1. Create a New Book Record
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn,	book_title,	category, rental_price,	status,	author,	publisher)
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '273 Narra St'
WHERE member_id = 'C101';


-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS140' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS140';


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT
	emp.emp_id,
	emp.emp_name,
	ist.issued_book_name,
	ist.issued_date
FROM employees AS emp
JOIN issued_status AS ist
ON emp.emp_id = ist.issued_emp_id
WHERE emp.emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT
	ist.issued_member_id,
	COUNT(ist.issued_member_id) AS no_issued_book
FROM issued_status AS ist
JOIN members as mem
ON ist.issued_member_id = mem.member_id
GROUP BY 1
HAVING COUNT(ist.issued_member_id) > 1;


-- ### 3. CTAS (Create Table As Select)
-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE issued_book_cnt
AS
	SELECT
		bk.isbn,
		bk.book_title,
		COUNT(issued_id) AS book_issued_cnt
	FROM issued_status AS ist
	JOIN books as bk
		ON ist.issued_book_isbn = bk.isbn
	GROUP BY 1,2;
	
SELECT * FROM issued_book_cnt;


-- ### 4. Data Analysis & Finding
-- Task 7. **Retrieve All Books in a Specific Category:
SELECT
	*
FROM books
WHERE category = 'History';


-- Task 8: Find Total Rental Income by Category:
SELECT
	category,
	SUM(rental_price) AS total_rental_price
FROM books
GROUP BY 1;


-- Task 9. **List Members Who Registered in the Last 180 Days**:
SELECT
	*
FROM members
WHERE reg_date >= CURRENT_DATE - 180;


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
SELECT
	e.emp_id,
	e.emp_name,
	b.manager_id,
	e2.emp_name AS manager_name,
	b.branch_id,
	b.branch_address
FROM employees AS e
JOIN branch AS b
ON e.branch_id = b.branch_id
JOIN employees AS e2
ON e2.emp_id = b.manager_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD
CREATE TABLE book_above_seven_usd 
AS
(
	SELECT 
		*
	FROM books
	WHERE rental_price > 7
);

SELECT * FROM book_above_seven_usd;


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT 
	*
FROM issued_status AS ist	
LEFT JOIN return_status AS rs
ON rs.issued_id = ist.issued_id
WHERE return_id IS NULL;


-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.
SELECT 
	m.member_name,
	ist.issued_book_name,
	ist.issued_date,
	CURRENT_DATE - ist.issued_date AS days_since_issued,
	(CURRENT_DATE - ist.issued_date - 30)AS days_overdue
FROM members AS m
JOIN issued_status AS ist
	ON m.member_id = ist.issued_member_id
LEFT JOIN return_status AS rs
	ON rs.issued_id = ist.issued_id
WHERE return_date IS NULL 
		AND 
	  (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).
CREATE OR REPLACE PROCEDURE update_book_status(p_return_id VARCHAR(15), p_issued_id VARCHAR(15), p_book_quality VARCHAR(15))
LANGUAGE plpgsql
AS
$$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
BEGIN
	-- Inserting returned book
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES (p_return_id,  p_issued_id, CURRENT_DATE, p_book_quality);

	-- extrating the isbn and and book name and storing them to a variable
	SELECT
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;
	
	-- Updating book status to 'yes' whrn returned
	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'ISBN: % | Book: % returned.', v_isbn, v_book_name;
	
END;
$$

-- calling procedure
CALL update_book_status('RS171', 'IS156', 'good');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
CREATE TABLE branch_perf_report
AS
	SELECT 
		br.branch_id,
		COUNT(ist.issued_id) AS num_of_issued_books,
		COUNT(rs.return_id) AS num_of_returned_books,
		SUM(bk.rental_price) AS total_revenue
	FROM branch AS br
	JOIN employees AS e
		ON br.branch_id = e.branch_id
	JOIN issued_status AS ist
		ON ist.issued_emp_id = e.emp_id
	JOIN books AS bk
		ON bk.isbn = ist.issued_book_isbn
	LEFT JOIN return_status AS rs
		ON rs.issued_id = ist.issued_id
	GROUP BY 1;
	
SELECT * FROM branch_perf_report;


-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 6 months.
SELECT
	*
FROM members
WHERE member_id IN
(
	SELECT
		DISTINCT(issued_member_id)
	FROM  issued_status
	WHERE issued_date >= CURRENT_DATE - INTERVAL '6 months'
);


-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT 
	e.emp_name,
	COUNT(ist.issued_id) AS num_book_processed,
	br.*
FROM branch AS br
JOIN employees AS e
	ON br.branch_id = e.branch_id
JOIN issued_status as ist
	ON e.emp_id = ist.issued_emp_id
GROUP BY 1,3
ORDER BY 2 DESC
LIMIT 3;



-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table.
-- Display the member name, book title, and the number of times they've issued damaged books.    

SELECT 
	ist.issued_member_id,
	m.member_name,
	ist.issued_book_name,
	COUNT(rs.book_quality) as num_issued_damaged_books
FROM issued_status AS ist
JOIN return_status AS rs
	ON rs.issued_id = ist.issued_id
JOIN books AS bk
	ON bk.isbn = ist.issued_book_isbn
JOIN members AS m
	ON m.member_id = ist.issued_member_id
WHERE rs.book_quality = 'Damaged'
GROUP BY 1,2,3;


-- Task 19: Stored Procedure
-- Objective: Create a stored procedure to manage the status of books in a library system.
--     Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
--     If a book is issued, the status should change to 'no'.
--     If a book is returned, the status should change to 'yes'.
SELECT * FROM issued_status; 
SELECT * FROM books; 

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(15), p_issued_member_id VARCHAR(15),p_issued_book_isbn VARCHAR(50), p_issued_emp_id VARCHAR(15))
LANGUAGE plpgsql AS $$

DECLARE
	v_book_title VARCHAR(80);
	v_status VARCHAR(10);
BEGIN
	-- extrating the book name, status and storing them to a variable.
	SELECT 
		book_title, status
		INTO
		v_book_title, v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	-- If yes, approved issuance
	IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
		VALUES (p_issued_id, p_issued_member_id, v_book_title, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
	
		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;
		
		RAISE NOTICE 'Book records added successfully for book isbn : % : %', p_issued_book_isbn, v_book_title;
	ELSE
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: % : %', p_issued_book_isbn, v_book_title;
	END IF;
END;
$$

-- Call procedure 
CALL issue_book('IS164', 'C109', '978-0-393-05081-8', 'E101');

-- Task 20: Create Table As Select (CTAS)
-- Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days.
-- The table should include:
-- 		The number of overdue books.
-- 		The total fines, with each day's fine calculated at $0.50.
-- 		The number of books issued by each member.
-- The resulting table should show:
-- 		Member ID
-- 		Number of overdue books
-- 		Total fines

CREATE TABLE members_fines
AS
SELECT 
	ist.issued_member_id,
	-- (CURRENT_DATE - ist.issued_date) AS days_sinced_issued,
	(CURRENT_DATE - ist.issued_date -30) AS days_over_due,
	((CURRENT_DATE - ist.issued_date - 30 ) * 0.5) AS total_fines
FROM issued_status AS ist
LEFT JOIN return_status AS rs
	ON ist.issued_id = rs.issued_id
WHERE return_id IS NULL AND (CURRENT_DATE - ist.issued_date) > 30;

SELECT * FROM members_fines;








