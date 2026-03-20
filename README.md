Project Overview
This project performs a complete end-to-end sales analysis on a global retail superstore dataset. The pipeline covers data joining, cleaning, transformation, and exploratory analysis in both SQL Server and Python, followed by a 3-page interactive Power BI dashboard for business intelligence reporting.
The dataset consists of two source tables — Orders and Returns — which are joined and cleaned in both tools to produce a unified working dataset. The same analytical questions are answered across SQL and Python, demonstrating cross-tool competency. The Power BI dashboard then visualises the findings across three KPI areas: Revenue, Profit, and Shipment.

Business Problem
A global superstore operates across multiple markets, countries, customer segments, and product categories. The business needs clear answers to three areas of performance.
For revenue — where is revenue coming from, which markets and segments are performing best, and how much revenue is lost to returned orders. For profit — which segments and categories are genuinely profitable, how does profit trend over time, and what is the impact of discounting on profit. For shipment — how long does shipping take by market and country, what does shipping cost by ship mode, and which order priorities are fulfilled fastest.

Dataset
DetailInfoSourceGlobal Superstore Dataset (Excel — Orders + Returns sheets)Orders rows51,290Returns rows1,173Final working rows51,290 after LEFT JOINDate range2011 – 2014Key dimensionsMarket, Country, Segment, Category, Sub-category, Ship Mode, Order PriorityKey metricsSales, Profit, Discount, Shipping Cost, Quantity, Final Sales Amount, Shipment Days

Tools Used
ToolPurposeSQL Server — T-SQLData joining, cleaning, feature engineering, and all EDA queriesPython — pandas, NumPy, matplotlibParallel cleaning pipeline, EDA, and data visualisationsPower BI Desktop3-page interactive dashboard covering Revenue, Profit, and Shipment KPIs

Repository Structure
global-superstore-analysis/
│
├── SQL/
│   └── superstore_analysis.sql            # Complete T-SQL script
│
├── Python/
│   └── superstore_analysis.ipynb          # Jupyter notebook
│
├── PowerBI/
│   └── Superstore_Power_BI_visual.pbix    # Power BI dashboard
│
└── README.md

Project Workflow
superstore_sales_raw.xlsx  (Orders sheet + Returns sheet)
              │
              ▼
 ┌────────────────────────┐     ┌────────────────────────┐
 │   SQL Server            │     │   Python / pandas      │
 │   LEFT JOIN via CTE     │     │   .merge() LEFT JOIN   │
 │   → Working_table       │     │   → final_data         │
 └───────────┬────────────┘     └───────────┬────────────┘
             │                               │
             └──────────────┬────────────────┘
                            ▼
               ┌─────────────────────────┐
               │   Data Cleaning          │   NULL handling, value standardisation,
               │   + Feature Engineering  │   computed columns, duplicate check
               └────────────┬────────────┘
                            ▼
               ┌─────────────────────────┐
               │   Exploratory            │   Revenue, profit, customer, product,
               │   Data Analysis          │   shipment, correlation analysis
               └────────────┬────────────┘
                            ▼
               ┌─────────────────────────┐
               │   Power BI Dashboard     │   3 pages — Revenue / Profit / Shipment
               └─────────────────────────┘

Data Cleaning and Transformation
SQL Server approach
The Orders and Returns tables were joined using a CTE with a LEFT JOIN on both order ID and market, preserving all orders with NULL return status for orders never returned. The result was written into a permanent working table using SELECT INTO, and a VIEW was created for flexible on-demand querying.
sqlWITH our_cte AS (
  SELECT Orders$.*, Returns$.Returned AS Returned_status
  FROM Orders$
  LEFT JOIN Returns$
    ON Orders$.order_id = Returns$.[Order ID]
    AND Orders$.market = Returns$.Market
)
SELECT * INTO Working_table FROM our_cte;
Two computed columns were then added directly to the working table:
sqlALTER TABLE Working_table
ADD Final_sales_amount AS (total_without_discount - Discount_amount),
    Shipment_days AS DATEDIFF(day, order_date, ship_date);
Return status was standardised from NULL and 'Yes' values into meaningful labels:
sqlUPDATE Working_table SET Returned_status = 'Complete_sales' WHERE Returned_status IS NULL;
UPDATE Working_table SET Returned_status = 'Returned' WHERE Returned_status = 'Yes';
A duplicate check using ROW_NUMBER confirmed no duplicates existed in the data.
Python approach
Both sheets were loaded from the Excel file using pd.read_excel() with the sheet name parameter. The tables were then merged using .merge() with a LEFT JOIN on order ID and market.
pythonour_order_data = pd.read_excel(r'superstore_sales_raw.xlsx', 'Orders')
our_return_data = pd.read_excel(r'superstore_sales_raw.xlsx', 'Returns')

final_data = our_order_data.merge(
    our_return_data,
    left_on=['order_id', 'market'],
    right_on=['Order ID', 'Market'],
    how='left'
)
Duplicate columns from the Returns table were dropped and NULLs in the Returned column were filled:
pythonfinal_data.drop(columns=['Order ID', 'Market'], inplace=True)
final_data['Returned'].fillna('Not_returned', inplace=True)
final_data['Returned'].replace('Yes', 'Returned_order', inplace=True)
The state and region columns were removed as not required for this analysis. Two feature columns were then engineered:
python# Final sales amount after discount
final_data['Final Sales Amount'] = final_data['total_without_discount'] - final_data['Discount_amount']

# Shipment days using NumPy timedelta for accurate day calculation
final_data['Shipment Days'] = final_data['ship_date'] - final_data['order_date']
final_data['Shipment Days'] = final_data['Shipment Days'] / np.timedelta64(1, 'D')
final_data['Shipment Days'] = final_data['Shipment Days'].astype('int')
After cleaning, the final dataset had 51,290 rows across 24 columns with no nulls in any critical field.

Data Cleaning Summary
StepIssueSQL ApproachPython ApproachJoin tablesOrders and Returns in separate tablesCTE + LEFT JOIN → SELECT INTO.merge() LEFT JOINDrop redundant columnsOrder ID and Market duplicated from ReturnsNot applicable.drop(columns=[...])NULL return status49,047 rows had no return recordUPDATE ... SET = 'Complete_sales' WHERE NULL.fillna('Not_returned')Standardise return values'Yes' not meaningfulUPDATE ... SET = 'Returned'.replace('Yes', 'Returned_order')Drop unused columnsState and region not neededALTER TABLE DROP COLUMN.drop(columns=['state','region'])Final sales amountNo post-discount revenue columnComputed column via ALTER TABLE ADDDirect column assignmentShipment daysNo fulfilment time metricDATEDIFF(day, order_date, ship_date)Date subtraction + np.timedelta64Duplicate checkVerify data integrityROW_NUMBER() OVER (PARTITION BY ...).duplicated() — no duplicates found

Key Findings
Revenue
StatusTotal Revenue ($)Complete sales (Not returned)11,856,501.59Returned orders648,453.28
Revenue grew consistently year over year:
YearTotal Revenue ($)20112,216,173.3420122,653,030.3520133,375,432.6520144,260,318.52
Revenue by ship mode (all orders):
Ship ModeRevenue ($)Standard Class7,329,919.14Second Class2,582,030.33First Class1,900,918.78Same Day692,086.61

Orders
Return StatusOrder CountNot returned49,047Returned2,243
Orders by segment:
SegmentOrder CountConsumer26,518Corporate15,429Home Office9,343

Profit
Total actual profit from completed sales: $1,372,521.96
Profit from returned orders (lost): $96,512.86
Profit by market (all orders):
MarketTotal Profit ($)APAC437,577.58EU372,829.74US286,397.02LATAM221,643.49Africa88,871.63EMEA43,897.97Canada17,817.39
Profit vs Discount correlation: r = -0.322 — a meaningful negative relationship. Higher discounts consistently reduce profit margins.

Revenue by Market and Return Status
MarketNot Returned ($)Returned ($)APAC3,266,326.68274,190.20EU2,719,486.08208,610.66US2,179,252.73—LATAM1,984,926.48165,652.42Africa824,117.19—EMEA808,058.63—Canada74,333.80—

Top 10 Customers by Revenue (Completed Sales)
CustomerTotal Revenue ($)Tom Ashbrook38,574.75Tamara Chand36,715.79Greg Tran34,915.66Christopher Conant33,055.91Penelope Sewall30,261.34Fred Hopkins29,881.05Hunter Lopez29,786.00Natalie Fritzler29,694.02Jane Waco29,516.17Raymond Buch29,272.21

Top 10 Profit Providers — USA Only
CustomerSegmentOrder IDProfit ($)Tamara ChandCorporateCA-2013-1186898,762.39Raymond BuchConsumerCA-2014-1401516,734.47Hunter LopezConsumerCA-2014-1667095,039.99Adrian BartonConsumerCA-2013-1171214,946.37Sanjit ChandConsumerCA-2011-1169044,668.69Tom AshbrookHome OfficeCA-2014-1271804,597.17Christopher MartinezConsumerCA-2012-1453523,192.07Sanjit EngleConsumerCA-2013-1588412,825.29Daniel RaglinHome OfficeUS-2013-1401582,640.48Andy ReiterConsumerCA-2014-1382892,602.09

Revenue by Sub-Category
Sub-CategoryRevenue ($)Phones1,703,652.63Copiers1,539,214.60Chairs1,455,233.29Bookcases1,453,893.28Storage1,128,046.18Appliances1,017,898.89Labels75,266.72Fasteners84,134.11

Shipment
Average shipping days by market:
MarketAvg Shipping Cost ($)APAC35.19EU30.94US23.83LATAM22.74Canada19.29Africa19.22EMEA17.57
Average shipment days for India: 3.97 days
Sales in key countries (completed orders):
CountryRevenue ($)United States2,179,252.73Australia890,761.80India645,213.74Canada74,333.80

Correlation Matrix — Key Findings
PairCorrelationSales vs Final Sales Amount0.978 — very strong positiveShipping cost vs Total without discount0.810 — strong positiveProfit vs Discount amount-0.322 — meaningful negativeProfit vs Final Sales Amount0.596 — moderate positiveShipment Days vs any metricnear zero — shipment time is independent
The strongest business insight from the correlation analysis is that higher discounts negatively impact profit (r = -0.322), while shipment days have no meaningful relationship with order value or profit.

Visualisations Produced
ChartVariablesKey InsightHorizontal barRevenue by yearConsistent upward growth 2011–2014Line chart (dotted)Profit by yearProfit growing alongside revenueLine chartOrder count by segmentConsumer dominates, Home Office lowestHorizontal barRevenue by return statusReturned orders represent ~5% of total revenueHorizontal barProfit by sub-category (completed sales)Technology sub-categories lead profitPie charts (side by side)Segment split — complete vs returnedConsumer largest in bothHistograms (side by side)Sales distribution — complete vs returnedBoth right-skewed; returned orders smallerStacked lineTotal orders vs returned orders by segmentReturned rate consistent across segmentsScatter plotProfit vs Discount amountVisible negative trend — confirms r = -0.322

Key SQL Techniques
sql-- Multi-temp-table profit comparison
SELECT t1.PROFIT_MIGHT_HAVE_EXTENDED,
       t2.PROFIT_WOULD_HAVE_BEEN_DONE,
       t3.ACTUAL_PROFIT_MADE,
       t1.segment
FROM #temp_tbl1 t1
JOIN #temp_tbl2 t2 ON t1.segment = t2.segment
JOIN #temp_tbl3 t3 ON t1.segment = t3.segment;

-- Sub-category classification using CASE WHEN
SELECT sub_category, SUM(Final_sales_amount) AS Final_Sales,
  CASE
    WHEN SUM(Final_sales_amount) < 200000  THEN 'Poor Sales'
    WHEN SUM(Final_sales_amount) <= 500000 THEN 'Quite Average'
    WHEN SUM(Final_sales_amount) < 1000000 THEN 'Very Good'
    WHEN SUM(Final_sales_amount) > 1000000 THEN 'Extremely Good'
  END AS Sales_Status
FROM Working_table
GROUP BY sub_category;

-- Parameterised stored procedure
CREATE PROCEDURE parametered_procedure_category
  @category NVARCHAR(20)
AS (SELECT * FROM Working_table WHERE category = @category);

EXEC parametered_procedure_category @category = 'Furniture';

Key Python Techniques
python# Multi-sheet Excel load
our_order_data = pd.read_excel(r'superstore_sales_raw.xlsx', 'Orders')
our_return_data = pd.read_excel(r'superstore_sales_raw.xlsx', 'Returns')

# LEFT JOIN merge on two keys
final_data = our_order_data.merge(
    our_return_data,
    left_on=['order_id', 'market'],
    right_on=['Order ID', 'Market'],
    how='left'
)

# Shipment days using NumPy timedelta
final_data['Shipment Days'] = (
    (final_data['ship_date'] - final_data['order_date'])
    / np.timedelta64(1, 'D')
).astype('int')

# Full correlation matrix
final_data.corr(method='pearson')

# Profit vs Discount correlation
final_data['profit'].corr(final_data['Discount_amount'])
# Output: -0.3222

Power BI Dashboard
The dashboard has three pages, each focused on a specific KPI area with a market slicer that cross-filters all visuals on that page.
Page 1 — Sale Revenue KPI covers overall revenue performance including a total sales revenue KPI card, column chart of revenue by segment and category with drill-down, bar chart by market, area chart of revenue trend by year split by return status, clustered bar of revenue by order priority, summary tables by return status, donut chart for return status split, and a market slicer.
Page 2 — Profit KPI covers profitability including a total profit KPI card, scatter chart of profit vs sales amount by market, profit by status table, profit ratio tables per category and per segment using DAX measures, binned profit distribution chart, clustered column of profit by market split by return status, profit trend line chart, and a year slicer.
Page 3 — Shipment KPI covers fulfilment performance including a total shipment count KPI card, average shipping days KPI card, filled map showing average shipping days by country, scatter chart of shipping cost versus shipment days by market, clustered column of shipping cost by ship mode, shipping cost trend line chart, order priority breakdown table, and market and category slicers.

How to Run
SQL Server:

Import the Orders and Returns data into SQL Server
Open superstore_analysis.sql in SSMS
Run sections in order — join and cleaning first, then EDA queries

Python:
bashpip install pandas numpy matplotlib openpyxl jupyter
jupyter notebook superstore_analysis.ipynb
Update the file path in pd.read_excel(r'...') to point to your local copy of superstore_sales_raw.xlsx.
Power BI:
Open Superstore_Power_BI_visual.pbix in Power BI Desktop. If the data source path has changed, update the connection under Transform Data → Data Source Settings.

Skills Demonstrated

Loading and joining multi-sheet Excel data using both SQL and Python
LEFT JOIN across two tables matching on multiple keys
Data cleaning — NULL handling, value standardisation, removing redundant columns
Feature engineering — Final Sales Amount and Shipment Days computed in both tools
30+ EDA queries covering revenue, profit, customers, products, and shipment
Correlation analysis across all numeric fields — identified discount impact on profit
Advanced SQL patterns — temp tables, stored procedures, views, CASE WHEN, HAVING
Data visualisation across 9 chart types in matplotlib
3-page Power BI dashboard with KPI cards, drill-down charts, DAX measures, scatter charts, filled map, and slicers
Cross-tool competency — same analytical pipeline built in both SQL Server and Python
