Project Overview

This project delivers a comprehensive end-to-end sales analysis on a global retail superstore dataset, transforming raw transactional data into actionable business insights. The workflow spans data integration, cleaning, transformation, exploratory data analysis (EDA), and business intelligence reporting.

A defining feature of this project is the dual implementation of the entire analytical pipeline using both SQL Server (T-SQL) and Python (pandas, NumPy, matplotlib). The same dataset, transformations, and business questions are consistently handled across both environments, demonstrating strong cross-platform analytical capability.

The final insights are presented through a three-page interactive Power BI dashboard, structured around three core business pillars: Revenue, Profit, and Shipment Performance.

Business Problem

The superstore operates across multiple markets, countries, and customer segments, generating large volumes of transactional data. However, without structured analysis, it is difficult to evaluate performance, identify inefficiencies, and support decision-making.

This project addresses three critical business areas:

Revenue
Which markets and customer segments drive the most revenue?
How does revenue evolve over time?
What proportion of revenue is lost due to returned orders?
Profit
Which segments and product categories are truly profitable?
How does discounting impact profitability?
What are the trends in profit over time?
Shipment
How long does delivery take across different markets and countries?
What are the cost implications of different shipping modes?
Which order priorities are fulfilled most efficiently?
Dataset Description
Source: Global Superstore Dataset (Excel)
Tables Used: Orders and Returns
Orders Rows: 51,290
Returns Rows: 1,173
Final Dataset: 51,290 rows (LEFT JOIN applied)
Date Range: 2011 – 2014
Key Dimensions
Market, Country
Segment (Consumer, Corporate, Home Office)
Category and Sub-category
Ship Mode, Order Priority
Key Metrics
Sales, Profit, Discount
Shipping Cost, Quantity
Final Sales Amount (engineered)
Shipment Days (engineered)
Data Integration and Preparation
SQL Server Implementation

The Orders and Returns tables were integrated using a Common Table Expression (CTE) with a LEFT JOIN on order_id and market, ensuring all orders were retained regardless of return status.

A working table was created for downstream analysis, followed by feature engineering:

Final Sales Amount: revenue after discount
Shipment Days: delivery time using DATEDIFF

Return status was standardised into:

Complete Sales (non-returned)
Returned

Data validation confirmed no duplicate records, ensuring dataset integrity.

Python Implementation

The same pipeline was replicated in Python:

Multi-sheet Excel ingestion using pd.read_excel()
LEFT JOIN using .merge() on multiple keys
Handling missing return values using .fillna()
Standardising categorical values with .replace()
Feature engineering:
Final Sales Amount
Shipment Days using NumPy timedelta

After processing, the dataset contained 51,290 clean records with no missing values in critical fields.

Exploratory Data Analysis (EDA)

EDA was conducted using both SQL queries and Python analysis to uncover patterns across revenue, profitability, customer behaviour, and logistics performance.

Key Findings
1. Revenue Performance

Revenue showed consistent year-over-year growth, increasing from $2.2M in 2011 to $4.26M in 2014, indicating strong business expansion.

Standard Class shipping contributed the highest revenue, reflecting customer preference for cost-effective delivery.
Returned orders accounted for approximately 5% of total revenue, representing a measurable but controlled loss.
2. Customer Segmentation
Consumer segment dominates with over 50% of total orders
Corporate and Home Office segments contribute significantly but at lower volumes

This suggests a strong B2C focus with opportunities for B2B growth.

3. Profitability Insights
Total profit from completed sales: $1.37M
Profit loss from returned orders: ~$96K

Profit distribution by market shows:

APAC and EU as top contributors
Emerging markets like LATAM also showing strong performance
4. Impact of Discounts
Correlation between discount and profit: r = -0.322

This indicates a meaningful negative relationship, confirming that higher discounting strategies directly erode profit margins. This is one of the most important business insights from the analysis.

5. Product-Level Insights
High-performing sub-categories: Phones, Copiers, Chairs
Low-performing sub-categories: Labels, Fasteners

Technology-related products drive the majority of revenue and profit.

6. Shipment Performance
Shipping cost varies significantly across markets, with APAC being the highest
Shipment time shows no meaningful correlation with profit or sales, indicating operational independence

Example:

Average shipment time in India: ~4 days
7. Customer Value Analysis

Top customers contributed disproportionately high revenue, with individuals like Tom Ashbrook and Tamara Chand leading total sales.

This highlights the importance of customer retention and targeted marketing strategies.

Correlation Analysis

Key statistical relationships identified:

Sales vs Final Sales Amount: 0.978 (very strong positive)
Shipping Cost vs Sales: 0.810 (strong positive)
Profit vs Discount: -0.322 (negative impact)
Shipment Days vs Metrics: ~0 (no relationship)

The analysis confirms that pricing strategy (discounting) has a significantly greater impact on profitability than logistics performance.

Power BI Dashboard

The final insights are presented in a three-page interactive dashboard, designed for business users.

Page 1 — Revenue KPI
Total revenue overview
Revenue by segment, category, and market
Yearly revenue trends
Return impact analysis
Page 2 — Profit KPI
Profit performance and trends
Profit distribution across categories and segments
Discount impact visualised
Scatter plots for deeper analysis
Page 3 — Shipment KPI
Delivery performance metrics
Shipping cost analysis by mode
Geographic shipping insights (map visual)
Order priority efficiency

All pages include interactive slicers for dynamic filtering by market, category, and year.

Project Workflow

Raw Data (Excel) → Data Integration → Cleaning & Transformation → Feature Engineering → EDA → Power BI Dashboard → Business Insights

Tools and Technologies
SQL Server (T-SQL): Data integration, cleaning, and querying
Python: Parallel analysis and visualisation
pandas & NumPy: Data manipulation and statistics
matplotlib: Visualisation
Power BI: Interactive dashboard and reporting
Skills Demonstrated

This project highlights:

Multi-source data integration using SQL and Python
Advanced data cleaning and transformation techniques
Feature engineering for business metrics
Strong SQL skills (CTEs, window functions, temp tables, stored procedures)
Statistical analysis including correlation
Data visualisation and storytelling
Business intelligence dashboard design in Power BI
Cross-tool competency (SQL + Python + Power BI)
Conclusion

This project demonstrates the ability to translate raw, multi-source data into meaningful business insights through a structured analytical pipeline. The consistent implementation across SQL and Python showcases strong technical versatility, while the Power BI dashboard bridges the gap between data analysis and business decision-making.

The findings highlight key strategic insights, particularly the impact of discounting on profitability and the dominance of specific markets and product categories in revenue generation.
