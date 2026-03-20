Project Overview
This project performs a full analytical pipeline on a global retail superstore dataset — covering data joining, cleaning, transformation, exploratory analysis in SQL Server, and business intelligence reporting through a 3-page interactive Power BI dashboard.
The dataset consists of two tables — Orders and Returns — which are joined and cleaned in SQL Server to produce a working table used for all downstream analysis. The Power BI dashboard then visualises the findings across three KPI areas: Revenue, Profit, and Shipment.

Business Problem
A global superstore operates across multiple markets, countries, customer segments, and product categories. The business needs clear visibility into three areas.
The first is revenue — where is revenue coming from, which markets and segments are driving sales, and how does the return rate affect overall revenue performance. The second is profit — which segments and categories are genuinely profitable, what is the profit ratio, and how does profit trend over time. The third is shipment — how long does shipping take across markets, what does shipping cost by mode, and which order priorities have the best fulfilment performance.

Dataset
DetailInfoSourceGlobal Superstore DatasetTablesOrders$ (transactions) + Returns$ (returned orders)Working table rows51,290 after join and cleaningKey dimensionsMarket, Country, Segment, Category, Sub-category, Ship Mode, Order PriorityKey metricsSales, Profit, Discount, Shipping Cost, Quantity

Tools Used
ToolPurposeSQL Server — T-SQLData joining, cleaning, transformation, and all EDA queriesPower BI Desktop3-page interactive dashboard covering Revenue, Profit, and Shipment KPIs

Repository Structure
global-superstore-analysis/
│
├── SQL/
│   └── superstore_analysis.sql       # Complete T-SQL script
│
├── PowerBI/
│   └── Superstore_Power_BI_visual.pbix   # Power BI dashboard file
│
└── README.md

Project Workflow
The raw Orders and Returns tables were first joined using a CTE with a LEFT JOIN on order ID and market. The result was persisted as a permanent working table for all downstream analysis. A view was also created for flexible on-demand querying without modifying the base tables.
Feature engineering was then applied directly to the working table — two computed columns were added: Final_sales_amount (sale price after discount) and Shipment_days (days between order placed and shipped). The return status column was standardised from NULL and 'Yes' values into 'Complete_sales' and 'Returned' labels. A duplicate check using ROW_NUMBER() OVER (PARTITION BY ...) confirmed no duplicates existed. A NULL check on key fields confirmed data integrity.
With the data clean and enriched, 30+ EDA queries were written covering revenue, profit, customer behaviour, product performance, and market analysis. The cleaned working table was then connected to Power BI for dashboard reporting.

Data Cleaning Steps
Step 1 — Join Orders and Returns via CTE
A LEFT JOIN was used to preserve all orders, with NULL return status for orders never returned. The result was written into a permanent working table using SELECT INTO.
sqlWITH our_cte AS (
  SELECT Orders$.*, Returns$.Returned AS Returned_status
  FROM Orders$
  LEFT JOIN Returns$
    ON Orders$.order_id = Returns$.[Order ID]
    AND Orders$.market = Returns$.Market
)
SELECT * INTO Working_table FROM our_cte;
Step 2 — Computed columns
sqlALTER TABLE Working_table
ADD Final_sales_amount AS (total_without_discount - Discount_amount),
    Shipment_days AS DATEDIFF(day, order_date, ship_date);
Step 3 — Standardise return status
sqlUPDATE Working_table SET Returned_status = 'Complete_sales'
WHERE Returned_status IS NULL;

UPDATE Working_table SET Returned_status = 'Returned'
WHERE Returned_status = 'Yes';
Step 4 — Duplicate and NULL check
sqlSELECT *, ROW_NUMBER() OVER (
  PARTITION BY order_id, product_name
  ORDER BY order_id
) AS rownumber
FROM Working_table
ORDER BY rownumber DESC;
-- Result: No duplicates found

SELECT * FROM Working_table
WHERE order_id IS NULL OR Final_sales_amount IS NULL;
-- Result: No NULLs in critical fields

SQL Analysis
Revenue by country and market
sqlSELECT country, SUM(Final_sales_amount) AS Sales_Amount
FROM Working_table
GROUP BY country
ORDER BY Sales_Amount DESC;

SELECT market, SUM(Final_sales_amount) AS Sales_Amount
FROM Working_table
WHERE Returned_status = 'Complete_sales'
GROUP BY market;
Profit lost to returns — using temp tables
One of the more advanced queries in this project compares three profit scenarios side by side: profit from returned orders (lost revenue), total potential profit, and actual profit from completed sales. This was achieved by building three separate temp tables and joining them.
sqlSELECT sum(profit) AS PROFIT_MIGHT_HAVE_EXTENDED, segment
INTO #temp_tbl1 FROM Working_table
WHERE Returned_status = 'Returned' GROUP BY segment;

SELECT sum(profit) AS PROFIT_WOULD_HAVE_BEEN_DONE, segment
INTO #temp_tbl2 FROM Working_table GROUP BY segment;

SELECT sum(profit) AS ACTUAL_PROFIT_MADE, segment
INTO #temp_tbl3 FROM Working_table
WHERE Returned_status = 'Complete_sales' GROUP BY segment;

SELECT
  t1.PROFIT_MIGHT_HAVE_EXTENDED,
  t2.PROFIT_WOULD_HAVE_BEEN_DONE,
  t3.ACTUAL_PROFIT_MADE,
  t1.segment
FROM #temp_tbl1 t1
JOIN #temp_tbl2 t2 ON t1.segment = t2.segment
JOIN #temp_tbl3 t3 ON t1.segment = t3.segment;
Sub-category sales classification using CASE WHEN
sqlSELECT
  sub_category,
  SUM(Final_sales_amount) AS Final_Sales,
  CASE
    WHEN SUM(Final_sales_amount) < 200000  THEN 'Poor Sales'
    WHEN SUM(Final_sales_amount) <= 500000 THEN 'Quite Average'
    WHEN SUM(Final_sales_amount) < 1000000 THEN 'Very Good'
    WHEN SUM(Final_sales_amount) > 1000000 THEN 'Extremely Good'
  END AS Sales_Status
FROM Working_table
GROUP BY sub_category
ORDER BY Final_Sales;
Stored procedures — for data access control
sql-- General access procedure
CREATE PROCEDURE Working_table_procedure
AS (SELECT * FROM Working_table);

EXEC Working_table_procedure;

-- Parameterised by category
CREATE PROCEDURE parametered_procedure_category
  @category NVARCHAR(20)
AS (SELECT * FROM Working_table WHERE category = @category);

EXEC parametered_procedure_category @category = 'Furniture';

SQL Techniques Covered
TechniqueUsage in this projectLEFT JOIN + CTEJoining Orders and Returns tablesSELECT INTOCreating persistent working table from CTEVIEWOur_view (joined data), Market_Demand (aggregated demand)Computed columnsFinal_sales_amount, Shipment_days via ALTER TABLETemp tablesThree #temp tables joined for profit comparisonStored proceduresGeneral access + parameterised by categoryROW_NUMBER()Duplicate detection via PARTITION BYCASE WHENSub-category sales classificationHAVINGSegment filter on aggregated sales > 5,000,000SubqueriesIN subquery for return status filteringTOP NTop/bottom customers, countries, productsGROUP BY + aggregatesRevenue, profit, order counts across all dimensionsDATEDIFFComputing shipment days between order and ship date

Power BI Dashboard
The dashboard has three pages, each focused on a specific KPI area. A market slicer on each page cross-filters all visuals on that page.
Page 1 — Sale Revenue KPI
This page gives a complete picture of revenue performance. It includes a total sales revenue KPI card, a column chart showing revenue by segment and category with drill-down capability, a bar chart of revenue by market, an area chart showing revenue trend over years split by return status, a clustered bar chart of revenue by order priority, two summary tables showing revenue and order count by return status, a donut chart for return status breakdown, and a market slicer.
Page 2 — Profit KPI
This page covers profitability in depth. It includes a total profit KPI card, a scatter chart plotting profit against sales amount by market, a profit by status table, profit ratio tables per category and per segment (using DAX measures), a binned profit distribution chart, a clustered column chart of profit by market split by return status, a line chart showing profit trend by year, and a year slicer.
Page 3 — Shipment KPI
This page analyses fulfilment performance. It includes a total shipment count KPI card, an average shipping days KPI card, a filled map showing average shipping days by country, a scatter chart of shipping cost versus shipping days by market, a clustered column chart of shipping cost by ship mode, a line chart of shipping cost trend by year, an order priority breakdown table, and market and category slicers.

How to Run
SQL Server:

Import the Orders and Returns CSV files into SQL Server
Open superstore_analysis.sql in SSMS
Run the script in order — join and cleaning first, then EDA queries

Power BI:

Open Superstore_Power_BI_visual.pbix in Power BI Desktop
If the data source path has changed, update the connection under Transform Data → Data Source Settings


Skills Demonstrated

Joining multiple source tables using CTEs and LEFT JOIN
Building a persistent working table for reusable downstream analysis
Feature engineering with computed columns using ALTER TABLE
Data cleaning — NULL handling, value standardisation, duplicate detection
30+ EDA queries covering revenue, profit, customers, products, and shipment
Advanced temp table pattern for multi-scenario profit comparison
Stored procedures including parameterised procedures for data access control
Views for reusable aggregated and joined query objects
3-page Power BI dashboard with KPI cards, drill-down charts, DAX measures, slicers, scatter charts, and a filled map
