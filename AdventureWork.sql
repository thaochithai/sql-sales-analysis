--chỉnh lại tên CTE thành raw_data hoặc gì đó, mình đặt CTE nó kì lắm, giống như mình đặt tên table là table vậy :D

----Query 01: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M --
SELECT 
  FORMAT_TIMESTAMP('%b %Y', TIMESTAMP(s.OrderDate)) AS period,
  p.Subcategory as Name,
  SUM(OrderQty) as qty_item,
  SUM(LineTotal) as total_sales,
  COUNT(DISTINCT SalesOrderID) as order_cnt
FROM adventureworks2019.Sales.SalesTable s
LEFT JOIN adventureworks2019.Production.ProductTable p
ON s.ProductID = p.ProductID
GROUP BY period, p.Subcategory
HAVING period IN (
  SELECT 
    DISTINCT FORMAT_TIMESTAMP('%b %Y', TIMESTAMP(SalesTable.OrderDate)) as time
  FROM adventureworks2019.Sales.SalesTable
  ORDER BY time DESC
  LIMIT 12) 
ORDER BY period DESC,name ASC

--đây là cách mình filter ngày
--1 số cách khác để filter L12M:
where date(a.ModifiedDate) >=  (select date_sub(date(max(a.ModifiedDate)), INTERVAL 12 month)
                                from `adventureworks2019.Sales.SalesOrderDetail` )--2013-06-30
-- where date(a.ModifiedDate) >= date(2013,06,30)
-- where date(a.ModifiedDate) between   date(2013,06,30) and date(2014,06,30)

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
LIMIT 3

-->bài yêu cầu mình lấy top 3 thì mình bên dense rank, để make sure là lấy đủ top 3
--còn limit nó chỉ giới hạn output thoi, trong trường hợp có nhiều số đồng hạng thì mình sẽ lấy thiếu data

with 
sale_info as (
  SELECT 
      FORMAT_TIMESTAMP("%Y", a.ModifiedDate) as yr
      , c.Name
      , sum(a.OrderQty) as qty_item

  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID

  GROUP BY 1,2
  ORDER BY 2 asc , 1 desc
),

sale_diff as (
  select *
  , lead (qty_item) over (partition by Name order by yr desc) as prv_qty
  , round(qty_item / (lead (qty_item) over (partition by Name order by yr desc)) -1,2) as qty_diff
  from sale_info
  order by 5 desc 
),

rk_qty_diff as (
  select *
      ,dense_rank() over( order by qty_diff desc) dk
  from sale_diff
)

select distinct Name
      , qty_item
      , prv_qty
      , qty_diff
from rk_qty_diff 
where dk <=3
order by dk ;


--Query 03: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number--
WITH cte AS(
SELECT 
  EXTRACT(YEAR FROM s.OrderDate) as yr,
  s.TerritoryID as TerritoryID,
  SUM(OrderQty) as order_cnt,
FROM adventureworks2019.Sales.SalesTable s
GROUP BY yr,TerritoryID
), rank AS (
SELECT
  yr,
  TerritoryID,
  order_cnt,
  ROW_NUMBER() OVER(PARTITION BY yr ORDER BY order_cnt DESC) as rk
FROM cte
)
SELECT *
FROM rank
WHERE rk IN (1,2,3)
ORDER BY yr DESC

--thay vì đặt tên cte thì mình nên đặt tên là raw_data

--Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory--
SELECT
  EXTRACT(YEAR FROM s.ModifiedDate) as yr,
  p.Subcategory as Name,
  SUM(UnitPrice*OrderQty*DiscountPct) as total_cost
FROM adventureworks2019.Sales.SalesOrderDetail s
LEFT JOIN adventureworks2019.Production.ProductTable p
ON s.ProductID = p.ProductID
LEFT JOIN adventureworks2019.Sales.SpecialOffer t
ON s.SpecialOfferID = t.SpecialOfferID
WHERE type ='Seasonal Discount'
GROUP BY yr,name

--> mình nên luôn tách aggregate function và field*field ra, cho dễ nhìn, dễ kiểm soát output 
select 
    FORMAT_TIMESTAMP("%Y", ModifiedDate)
    , Name
    , sum(disc_cost) as total_cost
from (
      select distinct a.ModifiedDate
      , c.Name
      , d.DiscountPct, d.Type
      , a.OrderQty * d.DiscountPct * UnitPrice as disc_cost 
      from `adventureworks2019.Sales.SalesOrderDetail` a
      LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
      LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
      LEFT JOIN `adventureworks2019.Sales.SpecialOffer` d on a.SpecialOfferID = d.SpecialOfferID
      WHERE lower(d.Type) like '%seasonal discount%' 
)
group by 1,2;


----Q5: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)----

--lấy min cũng là 1 cách, nhưng nếu nó chỉ đúng khi mình lấy data chỉ trong 1 năm 2014, còn nếu lấy 2014 2015 thì sẽ sai, do mình đang extract số tháng
--mình nên tính toán, cộng trừ nhân chia hết ở các cte trên cùng, sau đó xuống các cte mình chỉ row num rồi mapping thoi
with 
info as (
  select  
      extract(month from ModifiedDate) as month_no
      , extract(year from ModifiedDate) as year_no
      , CustomerID
      , count(Distinct SalesOrderID) as order_cnt
  from `adventureworks2019.Sales.SalesOrderHeader`
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2014'
  and Status = 5
  group by 1,2,3
  order by 3,1 
),

row_num as (--đánh số thứ tự các tháng họ mua hàng
  select *
      , row_number() over (partition by CustomerID order by month_no) as row_numb
  from info 
), 

first_order as (   --lấy ra tháng đầu tiên của từng khách
  select *
  from row_num
  where row_numb = 1
), 

month_gap as (
  select 
      a.CustomerID
      , b.month_no as month_join
      , a.month_no as month_order
      , a.order_cnt
      , concat('M - ',a.month_no - b.month_no) as month_diff
  from info a 
  left join first_order b 
  on a.CustomerID = b.CustomerID
  order by 1,3
)

select month_join
      , month_diff 
      , count(distinct CustomerID) as customer_cnt
from month_gap
group by 1,2
order by 1,2;

----Q6:Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal----
--vừa lag vừa tính ratio nó hơi dài, nếu có thể thì mình nên ghi tách ra cho dễ đọc
--nếu mình đi apply job thì mình mong muốn được người đọc hiểu 1 cách nhanh nhất chứ k phải đọc 1 câu query phức tạp nhất

with 
raw_data as (
  select
      extract(month from a.ModifiedDate) as mth 
      , extract(year from a.ModifiedDate) as yr 
      , b.Name
      , sum(StockedQty) as stock_qty

  from `adventureworks2019.Production.WorkOrder` a
  left join `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3
  order by 1 desc 
)

select  Name
      , mth, yr 
      , stock_qty
      , stock_prv    --mình k nên để coalesce ở đây để biến null thành 0, nó sẽ làm sai tính đúng đắn của dữ liệu
      , round(coalesce((stock_qty /stock_prv -1)*100 ,0) ,1) as diff   --dùng coalesce ở chỗ này để khi phép tính chia k đc, ra null, 
from (                                                                 --thì mình replace chỗ null đó thành số 0
      select *
      , lead (stock_qty) over (partition by Name order by mth desc) as stock_prv
      from raw_data
      )
order by 1 asc, 2 desc;


----Q7: Calc MoM Ratio of Stock / Sales in 2011 by product name----

--bổ sung hàm coalesce ở bước tính Ratio, để khi k có số stock và sale để tính, thì nó sẽ trả ra số 0
--chứ mình k nên dùng để replace stock vs sales thành số 0, vì nó làm sai số liệu nguyên gốc
--nên dùng full join, inner join nó chỉ hện ra những tháng vừa có sale vừa có stock thoi, nên có thể gây mismatch data
--nên bổ sung year = year để tránh trường hợp month của 2011 map với month 2010, ví dụ vậy

with 
sale_info as (
  select 
      extract(month from a.ModifiedDate) as mth 
     , extract(year from a.ModifiedDate) as yr 
     , a.ProductId
     , b.Name
     , sum(a.OrderQty) as sales
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b 
    on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3,4
), 

stock_info as (
  select
      extract(month from ModifiedDate) as mth 
      , extract(year from ModifiedDate) as yr 
      , ProductId
      , sum(StockedQty) as stock_cnt
  from 'adventureworks2019.Production.WorkOrder'
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
  group by 1,2,3
)

select
      a.*
    , b.stock_cnt as stock  --(*)
    , round(coalesce(b.stock_cnt,0) / sales,2) as ratio
from sale_info a 
full join stock_info b 
  on a.ProductId = b.ProductId
and a.mth = b.mth 
and a.yr = b.yr
order by 1 desc, 7 desc;

--(*) nếu nó null thì mình cứ để null, mình đổi lại thành 0 đôi lúc sẽ sai ý nghĩa
--giống như đi thi đc 0 điểm khác với việc k đi thi á

----Q8: No of order and value at Pending status in 2014---
select 
    extract (year from ModifiedDate) as yr
    , Status
    , count(distinct PurchaseOrderID) as order_Cnt 
    , sum(TotalDue) as value
from `adventureworks2019.Purchasing.PurchaseOrderHeader`
where Status = 1
and extract(year from ModifiedDate) = 2014
group by 1,2
;
