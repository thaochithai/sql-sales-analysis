----Query 01: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M --
SELECT 
  p.Subcategory AS subcategory_name,
  SUM(OrderQty) AS quantity_sold,
  SUM(LineTotal) AS total_sales,
  COUNT(DISTINCT SalesOrderID) AS order_count
FROM adventureworks2019.Sales.SalesTable s
LEFT JOIN adventureworks2019.Production.ProductTable p
  ON s.ProductID = p.ProductID
GROUP BY p.Subcategory
HAVING period IN (
  SELECT 
    DISTINCT FORMAT_TIMESTAMP('%b %Y', TIMESTAMP(SalesTable.OrderDate)) AS month_year
  FROM adventureworks2019.Sales.SalesTable
  ORDER BY month_year DESC
  LIMIT 12
) 
ORDER BY total_sales DESC;

--Query 02: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal--
WITH cte AS(
SELECT 
  FORMAT_TIMESTAMP('%Y', TIMESTAMP(s.OrderDate)) AS period,
  p.Subcategory as Name,
  SUM(OrderQty) as qty_item
FROM adventureworks2019.Sales.SalesTable s
LEFT JOIN adventureworks2019.Production.ProductTable p
ON s.ProductID = p.ProductID
GROUP BY period, p.Subcategory
ORDER BY Name ASC,period asc
)
SELECT 
  cte.Name,
  cte.qty_item,
  lag(cte.qty_item) OVER(PARTITION BY name ORDER BY period ASC) as prv_qty,
  ROUND(cte.qty_item/lag(cte.qty_item) OVER(PARTITION BY name ORDER BY period ASC)-1,2) as qty_diff
FROM cte
ORDER BY qty_diff DESC

--Query 03: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number--
WITH territory_yearly_sales AS (
  SELECT 
    EXTRACT(YEAR FROM s.OrderDate) AS year,
    s.TerritoryID,
    SUM(OrderQty) AS total_quantity
  FROM adventureworks2019.Sales.SalesTable s
  GROUP BY year, TerritoryID
),

territory_ranking AS (
  SELECT
    year,
    TerritoryID,
    total_quantity,
    DENSE_RANK() OVER(PARTITION BY year ORDER BY total_quantity DESC) AS rank
  FROM territory_yearly_sales
)
SELECT *
FROM territory_ranking
WHERE rank <= 3
ORDER BY year DESC, rank;

--Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory--
SELECT
  FORMAT_TIMESTAMP("%Y", s.ModifiedDate) AS year,
  p.Subcategory AS subcategory_name,
  SUM(UnitPrice * OrderQty * DiscountPct) AS total_discount_cost,
  SUM(UnitPrice * OrderQty )/SUM(UnitPrice * OrderQty * DiscountPct) AS vs_total_sales
FROM adventureworks2019.Sales.SalesOrderDetail s
LEFT JOIN adventureworks2019.Production.ProductTable p
  ON s.ProductID = p.ProductID
LEFT JOIN adventureworks2019.Sales.SpecialOffer t
  ON s.SpecialOfferID = t.SpecialOfferID
WHERE LOWER(t.type) LIKE '%seasonal discount%'
GROUP BY year, subcategory_name
ORDER BY year, subcategory_name;

--Query 5: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)----
WITH customer_orders AS (
  SELECT  
    EXTRACT(MONTH FROM ModifiedDate) AS month_number,
    EXTRACT(YEAR FROM ModifiedDate) AS year_number,
    CustomerID,
    COUNT(DISTINCT SalesOrderID) AS order_count
  FROM adventureworks2019.Sales.SalesOrderHeader
  WHERE FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2014'
    AND Status = 5
  GROUP BY month_number, year_number, CustomerID
),
customer_first_order AS (
  SELECT 
    CustomerID,
    MIN(month_number) AS first_month
  FROM customer_orders
  GROUP BY CustomerID
),
monthly_cohort AS (
  SELECT 
    o.CustomerID,
    f.first_month AS month_joined,
    o.month_number AS month_ordered,
    o.order_count,
    CONCAT('M - ', o.month_number - f.first_month) AS month_difference
  FROM customer_orders o 
  JOIN customer_first_order f 
    ON o.CustomerID = f.CustomerID
)
SELECT 
  month_joined,
  month_difference, 
  COUNT(DISTINCT CustomerID) AS customer_count
FROM monthly_cohort
GROUP BY month_joined, month_difference
ORDER BY month_joined, month_difference;

--Query 6:Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal----

WITH monthly_stock AS (
  SELECT
    EXTRACT(MONTH FROM a.ModifiedDate) AS month, 
    EXTRACT(YEAR FROM a.ModifiedDate) AS year, 
    b.Name AS product_name,
    SUM(StockedQty) AS stock_quantity
  FROM adventureworks2019.Production.WorkOrder a
  LEFT JOIN adventureworks2019.Production.Product b 
    ON a.ProductID = b.ProductID
  WHERE FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  GROUP BY month, year, product_name
),

stock_with_previous AS (
  SELECT 
    product_name,
    month, 
    year, 
    stock_quantity,
    LAG(stock_quantity) OVER (PARTITION BY product_name ORDER BY month DESC) AS previous_month_stock
  FROM monthly_stock
)

SELECT  
  product_name,
  month, 
  year, 
  stock_quantity,
  previous_month_stock,
  ROUND(
    COALESCE((stock_quantity / NULLIF(previous_month_stock, 0) - 1) * 100, 0),
    1
  ) AS percent_difference
FROM stock_with_previous
ORDER BY product_name ASC, month DESC;

--Query 7: Calc MoM Ratio of Stock / Sales in 2011 by product name----

WITH 
sale_info AS (
  SELECT 
      EXTRACT(MONTH FROM a.ModifiedDate) AS mth,
      EXTRACT(YEAR FROM a.ModifiedDate) AS yr,
      a.ProductId,
      b.Name,
      SUM(a.OrderQty) AS sales
  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b 
    ON a.ProductID = b.ProductID
  WHERE FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  GROUP BY 1, 2, 3, 4
), 

stock_info AS (
  SELECT
      EXTRACT(MONTH FROM ModifiedDate) AS mth,
      EXTRACT(YEAR FROM ModifiedDate) AS yr,
      ProductId,
      SUM(StockedQty) AS stock_cnt
  FROM `adventureworks2019.Production.WorkOrder`  -- Changed single quotes to backticks
  WHERE FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
  GROUP BY 1, 2, 3
)

SELECT
      a.mth,
      a.yr,
      a.ProductId,
      a.Name,
      a.sales,
      b.stock_cnt AS stock,
      ROUND(COALESCE(b.stock_cnt, 0) / NULLIF(a.sales, 0), 2) AS ratio  
FROM sale_info a 
FULL JOIN stock_info b 
  ON a.ProductId = b.ProductId
  AND a.mth = b.mth 
  AND a.yr = b.yr
ORDER BY 1 DESC, 7 DESC;

----Q8: No of order and value at Pending status in 2014---
SELECT 
  EXTRACT(YEAR FROM ModifiedDate) AS year,
  Status,
  COUNT(DISTINCT PurchaseOrderID) AS order_count, 
  SUM(TotalDue) AS total_value
FROM adventureworks2019.Purchasing.PurchaseOrderHeader
WHERE Status = 1 -- Pending status
  AND EXTRACT(YEAR FROM ModifiedDate) = 2014
GROUP BY year, Status;


