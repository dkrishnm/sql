-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

with sum_price as 
(select sum(original_price*5) as totalvalue , product_id, vendor_id from (
SELECT DISTINCT(product_id), vendor_id, original_price, customer_first_name, customer_id
FROM vendor_inventory  cross join customer) group by product_id, vendor_id) 
select p.product_name, v.vendor_name, sum_price.totalvalue  from sum_price 
inner join product p on p.product_id = sum_price.product_id
inner join vendor v on v.vendor_id = sum_price.vendor_id

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
CREATE TABLE product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units 
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_name = 'Apple Pie';


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE snapshot_timestamp = (
    SELECT MIN(snapshot_timestamp)
    FROM product_units where product_name = 'Apple Pie'
) and product_name = 'Apple Pie'


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


WITH inventory AS (
    SELECT product_id, SUM(quantity) AS i_qty
    FROM vendor_inventory
    GROUP BY product_id
),
bought AS (
    SELECT product_id, SUM(quantity) AS b_qty
    FROM customer_purchases
    GROUP BY product_id
),
prodcurrqty AS (
SELECT inventory.product_id, (inventory.i_qty - COALESCE(bought.b_qty, 0)) AS difference
FROM inventory
LEFT JOIN bought ON inventory.product_id = bought.product_id
)
update product_units as pu 
set current_quantity = pcq.difference
from prodcurrqty pcq
where pcq.product_id = pu.product_id;
