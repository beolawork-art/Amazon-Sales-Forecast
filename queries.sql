CREATE TABLE amazon_sales (
    -- Primary Identifiers (IDs)
    "index" INTEGER, 
    "Order ID" VARCHAR(50), 
    
    -- Date and Status
    "Date" DATE,             -- We'll clean the 'MM/DD/YYYY' string into this DATE type later
    "Status" VARCHAR(50),
    "Courier Status" VARCHAR(50),
    "Fulfilment" VARCHAR(50),

    -- Product Details
    "Category" VARCHAR(100),
    "Style" VARCHAR(100),
    "Size" VARCHAR(10),
    "ASIN" VARCHAR(15),
    "SKU" VARCHAR(50),

    -- Financials and Quantity
    "Qty" INTEGER,
    "currency" VARCHAR(10),
    "Amount" NUMERIC(10, 2), -- NUMERIC(10, 2) is best for money: 10 total digits, 2 after the decimal point
    
    -- Shipping and Location
    "ship-service-level" VARCHAR(50),
    "ship-city" VARCHAR(100),
    "ship-state" VARCHAR(100),
    "ship-postal-code" VARCHAR(10), -- Keeping this as text is safer than number
    "ship-country" VARCHAR(10),
    "B2B" BOOLEAN,             -- For TRUE/FALSE values
    
    -- Promotional and Other Data
    "promotion-ids" TEXT,      -- Use TEXT because some of these are very long
    "fulfilled-by" VARCHAR(50),
    "Sales Channel " VARCHAR(50)
   );

   DROP TABLE amazon_sales;

   CREATE TABLE amazon_sales (
    "index" INTEGER, 
    "Order ID" VARCHAR(50), 
    "Date" VARCHAR(50),             -- We'll import this as text first to avoid date conversion errors
    "Status" VARCHAR(50),
    "Fulfilment" VARCHAR(50),
    "Sales Channel " VARCHAR(50),   -- 👈 NOTE: This column has a space at the end!
    "ship-service-level" VARCHAR(50),
    "Style" VARCHAR(100),
    "SKU" VARCHAR(100),
    "Category" VARCHAR(100),
    "Size" VARCHAR(10),
    "ASIN" VARCHAR(15),
    "Courier Status" VARCHAR(50),
    "Qty" INTEGER,
    "currency" VARCHAR(10),
    "Amount" NUMERIC(10, 2), 
    "ship-city" VARCHAR(100),
    "ship-state" VARCHAR(100),
    "ship-postal-code" VARCHAR(10),
    "ship-country" VARCHAR(10),
    "promotion-ids" TEXT,
    "B2B" BOOLEAN,             
    "fulfilled-by" VARCHAR(50),
    "Unnamed: 22" TEXT
);

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN "Amount" IS NULL THEN 1 ELSE 0 END) AS missing_amount_count,
    SUM(CASE WHEN currency IS NULL OR TRIM(currency) = '' THEN 1 ELSE 0 END) AS missing_currency_count,
    SUM(CASE WHEN "Status" IS NULL OR TRIM("Status") = '' THEN 1 ELSE 0 END) AS missing_status_count
FROM
    amazon_sales;

DELETE FROM amazon_sales
WHERE "Amount" IS NULL
   OR "Date" IS NULL;

  SELECT
    COUNT(*) AS new_clean_total
FROM
    amazon_sales;

-- Question 1: What is the Top 5 Selling Product Categories?
SELECT
    "Category",
    COUNT(*) AS total_orders,
    SUM("Qty") AS total_items_sold,
    SUM("Amount") AS total_revenue
FROM
    amazon_sales
GROUP BY
    "Category" -- Group all the same categories together
ORDER BY
    total_revenue DESC -- Show the highest earning category first
LIMIT 5; -- Only show the top 5

-- Question 2: What is the Top 5 Performing Shipping City?
SELECT
    "ship-city",
    COUNT(*) AS total_orders,
    SUM("Amount") AS total_revenue
FROM
    amazon_sales
GROUP BY
    "ship-city"
ORDER BY
    total_revenue DESC
LIMIT 5;

-- Question 3: Which cities have the highest rate of "Cancelled" or "Returned" orders?
SELECT
    "ship-city",
    COUNT(*) AS total_orders,
    -- This counts all orders with a "bad" status
    SUM(CASE WHEN "Status" IN ('Cancelled', 'Returned', 'Refund') THEN 1 ELSE 0 END) AS problem_orders,
    -- This calculates the percentage (Problem Orders / Total Orders) * 100
    -- The CAST command cleans up the math to only show two decimal places.
    CAST(SUM(CASE WHEN "Status" IN ('Cancelled', 'Returned', 'Refund') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS NUMERIC(5, 2)) AS problem_rate_percent
FROM
    amazon_sales
GROUP BY
    "ship-city"
HAVING
    COUNT(*) >= 1000 -- Only look at cities with at least 1000 orders to make the percentage reliable
ORDER BY
    problem_rate_percent DESC -- Show the worst cities first
LIMIT 5;

-- Question 4: The products with the highest rate of returned or cancelled.ABORT
SELECT
    "Category",
    COUNT(*) AS total_orders,
    -- This counts all orders with a "bad" status
    SUM(CASE WHEN "Status" IN ('Cancelled', 'Returned', 'Refund') THEN 1 ELSE 0 END) AS problem_orders,
    -- This calculates the percentage (Problem Orders / Total Orders) * 100
    CAST(SUM(CASE WHEN "Status" IN ('Cancelled', 'Returned', 'Refund') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS NUMERIC(5, 2)) AS problem_rate_percent
FROM
    amazon_sales
GROUP BY
    "Category"
HAVING
    COUNT(*) >= 1000 -- Only look at categories with at least 1000 orders to make the percentage reliable
ORDER BY
    problem_rate_percent DESC
LIMIT 5;

-- Question 5: Finding out the top cities in the latest month.

WITH ConvertedSales AS (
    -- Temporary List 1: This converts the text date into a proper date column we call clean_date
    SELECT
        "ship-city",
        "Amount",
        TO_DATE("Date", 'MM/DD/YYYY') AS clean_date
    FROM
        amazon_sales
),
LatestMonth AS (
    -- Temporary List 2: This finds the most recent month from our clean dates
    SELECT
        DATE_TRUNC('month', MAX(clean_date)) AS latest_month
    FROM
        ConvertedSales
)
SELECT
    cs."ship-city",
    SUM(cs."Amount") AS latest_month_revenue
FROM
    ConvertedSales cs, LatestMonth lm
WHERE
    -- This is the filter: it compares the month of every order to the single "latest_month"
    DATE_TRUNC('month', cs.clean_date) = lm.latest_month
GROUP BY
    cs."ship-city"
ORDER BY
    latest_month_revenue DESC
LIMIT 5;