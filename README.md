
# NorthRiver Goods – SQL Warehouse Analytics

**Masterschool Data Analytics | Final Assessment: 100/100 Points**

## Project Overview

NorthRiver Goods is a data warehouse analytics project focused on transforming transactional data into reliable, business-ready insights.

The project covers dimensional modeling, data quality validation, analytical SQL, query optimization, and Power BI reporting.

## Technologies & Skills

- SQL (PostgreSQL and Databricks SQL)
- Data Warehousing and Star Schema Modeling
- Common Table Expressions (CTEs)
- Window Functions
- Data Quality Validation
- Funnel and Cohort Retention Analysis
- Query Performance Optimization
- Power BI

## Data Warehouse Architecture

The analytical model follows a star schema with one fact table and four dimensions.

**Fact table:** fact_orders

**Dimensions:**
- dim_customer
- dim_product
- dim_date
- dim_channel

**Grain:** One row per order item.

This structure supports consistent revenue, product, customer, and channel analysis.

## Analytical Use Cases

### Revenue Analysis
- Revenue by region, product category, and sales channel
- Product rankings and running totals
- Monthly revenue comparisons using window functions

### Cohort Retention
- Customer grouping by cohort month
- Monthly retention calculations
- Retention trends over time

### Funnel Analysis
- Analysis of customer progression through funnel stages
- Conversion rates between stages
- Identification of major drop-off points

The funnel analysis counts users reaching each stage but does not additionally enforce chronological event order.

## Data Quality

SQL validation checks were used to identify:

- NULL foreign keys
- Duplicate surrogate keys
- Orphan records
- Referential integrity issues

The checks support reliable analytical reporting.

## Query Optimization

Query performance was investigated using EXPLAIN ANALYZE, indexing, and comparisons of sequential and index scans.

The project demonstrates how query selectivity influences execution plans.

## Business Intelligence

A Power BI dashboard was used to present analytical results and support business decision-making.

## Assessment

**Result: 100/100 Points**

The project was completed as part of the Masterschool Data Analytics training program.

The assessment highlighted a clear understanding of warehouse architecture, data granularity, SQL joins, and data quality challenges.

## Author

Jesco-Joachim Schnebel

Data Analytics | SQL | Data Warehousing | Business Intelligence
  
