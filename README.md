# 🚲 AdventureWorks SQL Analysis Project - Bicycle Sales

## 📊 Project Overview  
This project features SQL queries designed to analyze the AdventureWorks2019 dataset on **Google BigQuery**. The analysis focuses on key business areas including:

- Sales performance  
- Product inventory  
- Customer retention  
- Discount effectiveness  

---

## 🗃️ Dataset  
**AdventureWorks** is a fictional bicycle manufacturing company dataset provided by Microsoft. This project uses the **2019 version** hosted on **Google BigQuery**.

---

## ❓ Business Questions & 💡 SQL Solutions

### 1. 🔝 Sales Performance by Product Subcategory (Last 12 Months)  
**Question:**  
What are the top 10 products in terms of items sold, total sales, and order volume by subcategory in the past 12 months?

**Summary Result:**  
Mountain Bikes, Road Bikes, and Touring Bikes are the top revenue drivers.

| Subcategory       | Quantity Sold | Total Sales         | Order Count |
|------------------|----------------|---------------------|--------------|
| Mountain Bikes   | 12,572         | 14,191,948.94       | 3,755        |
| Road Bikes       | 14,501         | 13,779,554.20       | 4,364        |
| Touring Bikes    | 13,861         | 13,618,940.34       | 2,535        |
| ...              | ...            | ...                 | ...          |

---

### 2. 📈 Year-over-Year Growth by Subcategory  
**Question:**  
Which subcategories had the highest year-over-year (YoY) growth rates?

**Insight:**  
Though bikes drive revenue, **Frames** and **Socks** show the highest growth — likely due to their replacement frequency.

| Subcategory      | Qty (This Year) | Qty (Last Year) | Growth Rate |
|------------------|------------------|-------------------|--------------|
| Mountain Frames  | 3,168            | 510               | +521%        |
| Socks            | 2,724            | 523               | +421%        |
| Road Frames      | 5,564            | 1,137             | +389%        |

---

### 3. 🌍 Top Territories by Order Quantity  
**Question:**  
Which 3 territories recorded the highest order quantities each year (with consistent ranking, even on ties)?

**Insight:**  
Territories 1, 4, and 6 consistently lead in sales volume across years.

| Year | Territory ID | Total Quantity | Rank |
|------|--------------|----------------|------|
| 2014 | 4            | 11,632         | 1    |
| 2014 | 6            | 9,711          | 2    |
| 2014 | 1            | 8,823          | 3    |
| ...  | ...          | ...            | ...  |

---

### 4. 💸 Seasonal Discount Cost Analysis  
**Question:**  
How much did seasonal discounts cost per subcategory?

**Insight:**  
Only **Helmets** had seasonal discounts, costing around **6–10%** of their total sales value annually.

| Year | Subcategory | Discount Cost | % of Sales |
|------|-------------|----------------|-------------|
| 2012 | Helmets     | 827.65         | 10.0%       |
| 2013 | Helmets     | 1,606.04       | 6.6%        |

---

### 5. 👥 Customer Retention Analysis (2014)  
**Question:**  
What was the monthly retention trend of customers with successfully shipped orders in 2014?

**Insight:**  
Most customers dropped after the **first month**, suggesting the need for stronger post-purchase engagement.

| Join Month | Month Difference | Customer Count |
|------------|------------------|----------------|
| 1          | M - 0            | 2,076          |
| 1          | M - 1            | 78             |
| 1          | M - 3            | 252            |
| ...        | ...              | ...            |

---

### 6. 🏷️ Monthly Stock Level Trends (2011)  
**Question:**  
What were the month-over-month changes in stock levels in 2011?

**Insight:**  
This helps monitor inventory fluctuations and identify patterns for restocking.

| Product Name              | Month | Stock Qty | MoM % Change |
|---------------------------|-------|-----------|----------------|
| Road-650 Red, 62          | 11    | 56        | +64.7%         |
| HL Mountain Frame - Black | 12    | 27        | -22.9%         |
| ...                       | ...   | ...       | ...            |

---

### 7. 🧮 Stock-to-Sales Ratio (2011)  
**Question:**  
How did stock levels compare to sales per product in 2011?

**Insight:**  
High stock-to-sales ratios can indicate overstocking or slow movers.

| Month | Product Name             | Sales | Stock | Ratio |
|--------|--------------------------|--------|--------|--------|
| 11     | Road-650 Red, 62         | 1      | 56     | 56.0   |
| 10     | LL Road Frame - Black, 60| 1      | 46     | 46.0   |
| ...    | ...                      | ...    | ...    | ...    |

---

### 8. ⏳ Pending Purchase Orders (2014)  
**Question:**  
How many purchase orders were pending in 2014 and what was their total value?

**Insight:**  
There were **224 pending orders**, totaling nearly **$3.87 million**.

| Year | Status | Order Count | Total Value    |
|------|--------|--------------|----------------|
| 2014 | Pending (1) | 224      | $3,873,579.01  |

---

## 💼 Insights & Business Value

This SQL analysis offers actionable insights to drive business decisions:

- ✅ Identify top-performing and fast-growing product subcategories  
- 🔄 Improve customer loyalty through retention analysis  
- 🧾 Optimize inventory with stock-to-sales and MoM stock trend tracking  
- 🎯 Evaluate effectiveness of promotions like seasonal discounts  
- 📍 Understand geographic sales performance to target high-performing territories  
