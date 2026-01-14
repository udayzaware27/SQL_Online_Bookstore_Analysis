-- Create Database
CREATE DATABASE OnlineBookstore;

-- Switch to the database OnlineBookstore;

-- Creating a Books Table
DROP TABLE IF EXISTS Books;
CREATE TABLE Books(
	Book_ID INT PRIMARY KEY,
	Title VARCHAR(100),
	Author VARCHAR(80),
	Genre VARCHAR(50),
	Published_Year INT,
	Price NUMERIC(10,2),
	Stock INT
);

--import data in Books table
COPY Books
FROM '/Library/PostgreSQL/18/imports/Books.csv'
DELIMITER ','
CSV HEADER;


--CREATING CUSTOMERS TABLE
DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers(
	Customer_ID INT PRIMARY KEY,
	Name VARCHAR(50),
	Email VARCHAR(100),
	Phone VARCHAR(15),
	City VARCHAR(50),
	Country VARCHAR(50)
);

ALTER TABLE Customers
	ALTER COLUMN Country TYPE VARCHAR(100);

--importing data in Customers Table
COPY Customers
FROM '/Library/PostgreSQL/18/imports/Customers.csv'
DELIMITER ','
CSV HEADER;


--CREATING ORDERS TABLE
DROP TABLE IF EXISTS Orders;
CREATE TABLE Orders(
	Order_ID INT PRIMARY KEY,
	Customer_ID INT	REFERENCES Customers(Customer_ID),
	Book_ID	INT REFERENCES Books(Book_id),
	Order_Date DATE,
	Quantity INT,
	Total_Amount NUMERIC(10,2)
);

--imporing data in Orders Table
COPY Orders
FROM '/Library/PostgreSQL/18/imports/Orders.csv'
DELIMITER ','
CSV HEADER;


SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;



-- *** Basic Queries ***


-- 1) Retrieve all books in the "Fiction" genre:
SELECT * FROM Books WHERE Genre = 'Fiction';


-- 2) Find books published after the year 1950:
SELECT * FROM Books WHERE published_year > 1950;


-- 3) List all customers from the Canada:
SELECT * FROM Customers WHERE Country = 'Canada';


-- 4) Show orders placed in November 2023:
SELECT * FROM Orders WHERE order_date BETWEEN '2023-11-01' AND '2023-11-30';


-- 5) Retrieve the total stock of books available:
SELECT SUM(stock) FROM Books AS Total_Stocks; 


-- 6) Find the details of the most expensive book
SELECT * FROM Books WHERE price= (SELECT MAX(price) FROM Books);


-- 7) Show all customers who ordered more than 1 quantity of a book
SELECT * FROM Orders WHERE quantity > 1;


-- 8) Retrieve all orders where the total amount exceeds $20
SELECT * FROM Orders WHERE total_amount > 20;


-- 9) List all genres available in the Books table
SELECT DISTINCT genre FROM Books;


-- 10) Find the book with the lowest stock
SELECT * FROM Books WHERE stock = (SELECT MIN(stock) FROM Books);


-- 11) Calculate the total revenue generated from all orders
SELECT SUM(total_amount) AS Total_Revenue FROM Orders;



-- *** Advance Queries ***


-- 1) Retrieve the total number of books sold for each genre.
SELECT genre, SUM(quantity) AS Total_Books_Sold FROM Orders
JOIN Books
ON Orders.Book_ID = Books.Book_ID
GROUP BY genre;


-- 2) Find the average price of books in the "Fantasy" genre
SELECT AVG(price) ::NUMERIC(10,2) AS Average_Book_Price FROM Books WHERE genre = 'Fantasy';   --IF NOT WANT TO DISPLAY GENRE NAME

SELECT genre, AVG(price) ::NUMERIC(10,2) AS Average_Book_Price FROM Books WHERE genre = 'Fantasy' GROUP BY genre; --IF WANT TO DISPLAY GENRE NAME

SELECT DISTINCT genre,
	AVG(price) OVER(PARTITION BY GENRE)  ::NUMERIC(10,2) AS Average_Book_Price FROM BOOKS WHERE GENRE='Fantasy';   --COMPLEX


-- 3) List customers who have placed at least 2 orders
SELECT customer_id, COUNT(order_id) AS Order_Count
FROM Orders
GROUP BY customer_id
HAVING COUNT(order_id) >= 2;


-- 4) Find the most frequently ordered books
SELECT book_id, COUNT(order_id) AS Frequently_Ordered_Book
FROM Orders
GROUP BY book_id
HAVING COUNT(order_id) = (SELECT MAX(cnt)
							FROM (SELECT COUNT(order_id) AS cnt
									FROM Orders
									GROUP BY book_id));


-- 5) Show the top 3 most expensive books of 'Fantasy' Genre
SELECT * FROM Books WHERE genre = 'Fantasy' ORDER BY price DESC LIMIT 3;

SELECT * FROM Books WHERE genre = 'Fantasy'           --if more than 3 books share the same price
	AND price >= (SELECT price FROM Books 
					WHERE genre='Fantasy'
					ORDER BY price DESC
					LIMIT 1 OFFSET 2)
	ORDER BY price DESC;


-- 6) Retrieve the total quantity of books sold by each author
SELECT b.author, SUM(o.quantity) AS Total_Books_Sold
FROM Books AS b
JOIN Orders AS o
ON b.book_id = o.book_id
GROUP BY b.author;


-- 7) List the cities where customers who spent over $30 are located
SELECT DISTINCT c.city
FROM Customers AS c
JOIN Orders AS o
ON c.customer_id = o.customer_id
WHERE o.total_amount > 30;


-- 8) Find the customer who spent the most on orders
SELECT c.customer_id, c.name, SUM(o.total_amount) AS Total_Spent
FROM Customers AS c
JOIN Orders AS o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY Total_Spent DESC LIMIT 1;

SELECT c.customer_id, c.name, SUM(o.total_amount) AS Total_Spent     -- IF TWO OR MORE CUSTOMERS SPENT SAME AMOUNT
FROM Customers AS c
JOIN Orders AS o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.total_amount) = (SELECT MAX(total_spent)
								FROM (SELECT SUM(total_amount) AS total_spent FROM Orders
										GROUP BY customer_id));


-- 9) Calculate the stock remaining after fulfilling all orders
SELECT b.book_id, b.title, b.stock, COALESCE(SUM(quantity), 0) AS ordered_quantity,
					b.stock - COALESCE(SUM(quantity), 0) AS Remaining_Stock
FROM Books b
LEFT JOIN Orders o
ON b.book_id = o. book_id
GROUP BY b.book_id;


