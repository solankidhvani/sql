/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

--Finding NULLs
SELECT 
product_name
, product_size
, product_qty_type
FROM product
WHERE product_size IS NULL OR product_qty_type  IS NULL;
--Replacing NULLS with blank and unit
SELECT 
    product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

--Using ROW_NUMBER()
SELECT 
				customer_id,
				market_date,
				ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date ) AS visit_number
FROM ( 
				SELECT DISTINCT customer_id, market_date
				FROM customer_purchases
) AS unique_visits
ORDER BY customer_id, market_date;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--Reversing the numbering
SELECT 
				customer_id,
				market_date,
				ROW_NUMBER() OVER( PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number
FROM (
				SELECT DISTINCT customer_id, market_date
				FROM customer_purchases
) AS unique_visits 
ORDER BY customer_id, market_date DESC;
--Filtering to the most recent visit only
SELECT *
FROM (
    SELECT 
        customer_id,
        market_date,
        ROW_NUMBER() OVER ( PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number
    FROM ( 
        SELECT DISTINCT customer_id, market_date
        FROM customer_purchases
    ) AS unique_visits
) AS ranked_visits
WHERE visit_number = 1
ORDER BY customer_id;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */
SELECT cp.*,
				visit_counts.times_purchased
FROM customer_purchases cp
JOIN ( 
		SELECT customer_id,
						 product_id,
						 COUNT (DISTINCT market_date) AS times_purchased
		FROM customer_purchases
		GROUP BY customer_id, product_id
					) visit_counts
ON cp.customer_id = visit_counts.customer_id
AND cp.product_id = visit_counts.product_id
ORDER BY cp.customer_id, cp.product_id, cp.market_date;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

--Using INSTR, SUBSTR and TRIM functions
SELECT
				product_name,
				TRIM(
				CASE 
							WHEN INSTR (product_name, '-' ) > 0
							THEN SUBSTR(product_name, INSTR (product_name, '-') + 1)
						    END
						)	AS description
FROM product;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

--Fitering using REGEXP
SELECT
				product_name,
				product_size,
				CASE
							WHEN INSTR (product_name, '-' ) > 0
							THEN TRIM ( SUBSTR(product_name, INSTR (product_name, '-') + 1))
							ELSE NULL
				END AS description
FROM product
WHERE product_size REGEXP '[0-9]';
-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

--Aggregate sales by date
WITH daily_sales AS (
    SELECT 
        market_date,
        SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
)
--Rank the sales 
,ranked_sales AS (
    SELECT 
        market_date,
        total_sales,
        ROW_NUMBER() OVER(ORDER BY total_sales DESC) AS best_rank,
        ROW_NUMBER() OVER(ORDER BY total_sales ASC) AS worst_rank
    FROM daily_sales
)
-- Highest sales day and Lowest sales day  
SELECT market_date, total_sales, 'Highest Sales' AS sales_type
FROM ranked_sales
WHERE best_rank = 1
UNION

SELECT market_date, total_sales, 'Lowest Sales' AS sales_type
FROM ranked_sales
WHERE worst_rank = 1;



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
SELECT
    v.vendor_name,
    p.product_name,
    COUNT(*) * 5 * vi.original_price AS potential_revenue
FROM 
    (SELECT DISTINCT vendor_id, product_id, original_price 
     FROM vendor_inventory) vi
JOIN vendor v ON vi.vendor_id = v.vendor_id
JOIN product p ON vi.product_id = p.product_id
CROSS JOIN (SELECT DISTINCT customer_id FROM customer_purchases) c
GROUP BY
    v.vendor_name,
    p.product_name,
    vi.original_price
ORDER BY v.vendor_name, p.product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

-- Create the product_units table structure (if it doesn't exist)
CREATE TABLE IF NOT EXISTS product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE 1=0; --creates the structure without inserting data
-- Insert data into product_units table
INSERT INTO product_units
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

SELECT * FROM product_units;


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

--Inserting a new row
INSERT INTO product_units (
							product_id,
							product_name,
							product_size,
							product_category_id,
							product_qty_type,
							snapshot_timestamp
) VALUES (
108,
'Dhvani Organic Honey',
'16 oz',
99,
'unit',
CURRENT_TIMESTAMP
);

SELECT * FROM product_units;
-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

--View all records to undderstaand what we have
SELECT product_id, product_name, snapshot_timestamp 
FROM product_units 
WHERE product_id = 108
ORDER BY snapshot_timestamp;
--Preview what would be deleted

SELECT product_id, product_name, snapshot_timestamp,
       'WOULD BE DELETED' as action
FROM product_units 
WHERE product_id = 108
  AND snapshot_timestamp < (
    SELECT MAX(snapshot_timestamp) 
    FROM product_units 
    WHERE product_id =108
  );
--RUN only after confirming the previews
DELETE FROM product_units
WHERE product_id =108
		AND snapshot_timestamp < (
		SELECT MAX (snapshot_timestamp)
		FROM product_units
		WHERE product_id =108
		);
SELECT * FROM product_units;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


--STEP 1: Add the new column to product_units table
ALTER TABLE product_units
ADD current_quantity INT;

-- STEP 2: Let's first understand the data structure
-- (Run this to see what vendor_inventory looks like)
SELECT product_id, quantity, market_date 
FROM vendor_inventory 
ORDER BY product_id, market_date DESC;

-- STEP 3: Find the "last" quantity per product
-- (This gets the most recent inventory record for each product)
SELECT product_id, 
       quantity as last_quantity,
       market_date
FROM vendor_inventory v1
WHERE market_date = (
    SELECT MAX(market_date) 
    FROM vendor_inventory v2 
    WHERE v2.product_id = v1.product_id
)
ORDER BY product_id;

-- STEP 4: Test the COALESCE with potential NULL values
-- (This handles products that might not have inventory records)
SELECT pu.product_id,
       COALESCE(
           (SELECT quantity 
            FROM vendor_inventory vi 
            WHERE vi.product_id = pu.product_id 
              AND market_date = (
                  SELECT MAX(market_date) 
                  FROM vendor_inventory vi2 
                  WHERE vi2.product_id = pu.product_id
              )
           ), 0
       ) as calculated_quantity
FROM product_units pu
ORDER BY pu.product_id;

-- STEP 5: The final UPDATE statement
UPDATE product_units 
SET current_quantity = COALESCE(
    (SELECT quantity 
     FROM vendor_inventory vi 
     WHERE vi.product_id = product_units.product_id 
       AND market_date = (
           SELECT MAX(market_date) 
           FROM vendor_inventory vi2 
           WHERE vi2.product_id = product_units.product_id
       )
    ), 0
)
WHERE product_units.product_id IS NOT NULL;
SELECT * FROM product_units;










