# E-Commerce RFM, Retention & MoM Growth Analytics Dashboard

End-to-end relational SQL and Business Intelligence reporting pipeline built with **MySQL 8.0** and **Google Sheets**.

## Architecture & Tech Stack
- **Database:** MySQL 8.0 normalized 4-table schema (`customers`, `products`, `orders`, `order_items`)
- **Analytical SQL Views (`ecommerce_rfm_analytics.sql`):**
  - `v_rfm_segments`: Customer Recency, Frequency, Monetary scoring using CTEs and `NTILE(4)` window functions
  - `v_monthly_kpis`: Monthly Net Revenue, Gross Profit, Month-over-Month Growth % (`LAG()`), and Cumulative YTD Revenue (`SUM() OVER`)
  - `v_product_performance`: Product-level gross margin and return rate % breakdown
- **Executive Dashboard (`Executive_Dashboard.pdf`):** Multi-tab Google Sheets report powered by `QUERY()`, `ARRAYFORMULA()`, dual-axis combo charts, and conditional formatting

## Repository Contents
- `ecommerce_rfm_analytics.sql` — Complete database schema, sample dataset, and analytical views
- `rfm_segments.csv` — Exported customer RFM scores and segments
- `monthly_kpis.csv` — Exported monthly revenue, margin, and MoM growth metrics
- `product_performance.csv` — Exported product profitability and return rates
- `Executive_Dashboard.pdf` — Final landscape executive report
