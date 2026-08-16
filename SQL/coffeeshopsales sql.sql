SELECT * FROM coffee_shop_sales -- Display table

DESCRIBE coffee_shop_sales -- Displays table metadata

UPDATE coffee_shop_sales
SET transaction_date = STR_TO_DATE(transaction_date, '%d/%m/%Y'); -- converts string to date format

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_date DATE; -- converts data type to date

UPDATE coffee_shop_sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%S');-- converts string to date format (time) 

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_date TIME; -- converts data type to time

-- field transaction_id had text error, used alter and change column functions to correct

-- CALCULATE TOTAL SALES FOR EACH RESPECTIVE MONTH

SELECT CONCAT((ROUND(SUM(unit_price * transaction_qty)))/1000, "K") AS Total_Sales -- total $ sales for all months, rounded and abbreviated with "K"
FROM coffee_shop_sales
WHERE
MONTH(transaction_date) = 5 -- Filter by month, this one for May

-- CALCULATE MONTH-ON-MONTH CHANGE IN SALES

SELECT -- aggregated function
	MONTH(transaction_date) AS month, -- # of Month (Which month?)
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales, -- Total sales Column
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1) -- First piece gives value for current month/selected month (may-april sales) / Monthly Sales Difference
    OVER(ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1) -- Divide by previous month sales
    OVER(ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage -- Percentage change month-over-month
FROM
	coffee_shop_sales -- from table
WHERE
	MONTH(transaction_date) IN (4, 5) -- for months of April (PM) and May (CM)
GROUP BY
	MONTH(transaction_date) -- when using aggregated function with a dimension, have to group by same (transaction_id)
ORDER BY
	MONTH(transaction_date); -- order in ascending order by month of transaction date

-- TOTAL ORDERS FOR EACH MONTH

SELECT COUNT(transaction_id) as Total_Orders -- counts each unique transaction id
FROM coffee_shop_sales  -- from table
WHERE MONTH (transaction_date)= 5 -- for month of May

-- TOTAL ORDERS MOM CHANGE

SELECT  
	MONTH(transaction_date) AS month, 
	ROUND(COUNT(transaction_id)) AS total_orders, -- total orders for current month 
	(COUNT(transaction_id) - LAG(COUNT(transaction_id), 1)  
	OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1)  
	OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage 
FROM  
	coffee_shop_sales 
WHERE  
	MONTH(transaction_date) IN (4, 5) -- for April and May 
GROUP BY  
	MONTH(transaction_date) 
ORDER BY  
	MONTH(transaction_date);
    
-- TOTAL QUANTITY SOLD

SELECT SUM(transaction_qty) as Total_Quantity_Sold 
FROM coffee_shop_sales  
WHERE MONTH(transaction_date) = 5 -- for month of (CM-May)

-- TOTAL QUANTITY SOLD MOM CHANGE

SELECT  
	MONTH(transaction_date) AS month, 
	ROUND(SUM(transaction_qty)) AS total_quantity_sold, 
	(SUM(transaction_qty) - LAG(SUM(transaction_qty), 1)  
	OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1)  
	OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage 
FROM  
	coffee_shop_sales 
WHERE  
	MONTH(transaction_date) IN (4, 5)   -- for April and May 
GROUP BY  
	MONTH(transaction_date) 
ORDER BY  
	MONTH(transaction_date);
    
-- CALENDAR TABLE/HEAT MAP: DAILY SALES, QUANTITY, and TOTAL ORDERS

SELECT  
CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS total_sales, -- total sales, rounded to K
CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS total_orders, -- total orders, rounded to K
CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS total_quantity_sold -- total qty sold, rounded to K
FROM  
coffee_shop_sales 
WHERE  
transaction_date = '2023-05-18'; -- For May 18th 2023, select specific date

-- SALES BY WEEKDAY/WEEKEND
SELECT  
CASE  
        WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends' -- weekends counts as sunday and saturday, days 1 and 7
        ELSE 'Weekdays' 
    END AS day_type, 
    ROUND(SUM(unit_price * transaction_qty),2) AS total_sales 
FROM  
    coffee_shop_sales 
WHERE  
    MONTH(transaction_date) = 5  -- Filter for May 
GROUP BY  
    CASE  
        WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends' 
        ELSE 'Weekdays' 
    END;
    
-- SALES BY STORE LOCATION
SELECT  
	store_location, 
	CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,2), 'K') as Total_Sales 
FROM coffee_shop_sales 
WHERE 
MONTH(transaction_date) = 5 -- Month of May
GROUP BY store_location 
ORDER BY  
	SUM(unit_price * transaction_qty) DESC
    
-- DAILY SALES WITH AVERAGE LINE

SELECT 
	CONCAT(ROUND(AVG(total_sales)/1000, 1), 'K') AS average_sales 
FROM ( 
    SELECT  
        SUM(unit_price * transaction_qty) AS total_sales -- This input/inner query fed into outer query then averaged; avg sales/month
    FROM  
        coffee_shop_sales 
 WHERE  
        MONTH(transaction_date) = 5  -- Filter for May 
    GROUP BY  
        transaction_date -- will aggregate sum for each and every date
) AS internal_query;

-- DAILY SALES FOR SELECTED MONTH
SELECT  
	DAY(transaction_date) AS day_of_month, 
	ROUND(SUM(unit_price * transaction_qty),1) AS total_sales 
FROM  
	coffee_shop_sales 
WHERE  
	MONTH(transaction_date) = 5  -- Filter for May 
GROUP BY  
	DAY(transaction_date) 
ORDER BY  
	DAY(transaction_date);
    
-- BELOW/ABOVE AVERAGE SALES
SELECT  
	day_of_month, 
	CASE  
	WHEN total_sales < avg_sales THEN 'Below Average' 
	WHEN total_sales > avg_sales THEN 'Above Average' 
ELSE 'Average' 
	END AS sales_status, 
    total_sales 
FROM ( 
    SELECT  
        DAY(transaction_date) AS day_of_month, 
        SUM(unit_price * transaction_qty) AS total_sales, 
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales 
    FROM  
        coffee_shop_sales 
    WHERE  
        MONTH(transaction_date) = 5  -- Filter for May 
    GROUP BY  
        DAY(transaction_date) 
) AS sales_data 
ORDER BY  
    day_of_month;
    
-- SALES BY PRODUCT CATEGORY
    
SELECT  
	product_category, 
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales 
FROM coffee_shop_sales 
WHERE 
	MONTH(transaction_date) = 5  
GROUP BY product_category 
ORDER BY SUM(unit_price * transaction_qty) DESC

-- TOP 10 PRODUCTS // TOP REVENUE
SELECT  
	product_type, 
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales 
FROM coffee_shop_sales 
WHERE 
	MONTH(transaction_date) = 5  AND product_category = 'Coffee' -- can filter by product category here as well; top sellers in category
GROUP BY product_type 
ORDER BY SUM(unit_price * transaction_qty) DESC 
LIMIT 10 

-- SALES BY DAY & HOUR
SELECT  
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales, 
    SUM(transaction_qty) AS Total_Quantity, 
    COUNT(*) AS Total_Orders 
FROM  
    coffee_shop_sales 
WHERE  
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8 
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)
    
-- MON-SUN SALES FOR ANY MONTH // DETERMINE PEAK DAYS

SELECT  
    CASE  
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday' 
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday' 
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday' 
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday' 
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday' 
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday' 
        ELSE 'Sunday' 
    END AS Day_of_Week, 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales 
FROM  
    coffee_shop_sales 
WHERE  
    MONTH(transaction_date) = 5 -- Filter for May (month number 5) 
GROUP BY  
    CASE  
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday' 
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday' 
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday' 
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday' 
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday' 
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday' 
        ELSE 'Sunday' 
    END;
    
-- SALES FOR ALL HOURS FOR ANY MONTH // DETERMINE PEAK HOURS

SELECT  
    HOUR(transaction_time) AS Hour_of_Day, 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales 
FROM  
    coffee_shop_sales 
WHERE  
    MONTH(transaction_date) = 5 -- Filter for May (month number 5) 
GROUP BY  
    HOUR(transaction_time) 
ORDER BY  
    HOUR(transaction_time);
    
-- ALL QUERIES FIRED