# FPR (Financial Services) dbt Models

Production-ready dbt models for Financial Services industry data from Fivetran's industries connector.

---

## 📊 Project Overview

**Industry**: Financial Services (FPR)  
**Source Data**: Fivetran industries connector - FPR_RECORDS table  
**Database**: HOL_DATABASE  
**Schema**: INDUSTRIES_FINANCIAL_SERVICES  
**Target Schema**: INDUSTRIES_FINANCIAL_SERVICES_DBT  
**Warehouse**: Snowflake

---

## 🎯 Generated Views

### 1. vw_fpr_customer_portfolio_kpi
**Purpose**: Executive dashboard for customer portfolio health and financial metrics

**Key Metrics**:
- Total customers, account balances, transaction values
- Customer counts by segment and lifecycle stage
- Average satisfaction and churn probability
- Product distribution and sales metrics

**Use Cases**:
- Executive reporting and KPI dashboards
- Portfolio health monitoring
- Strategic planning and forecasting

**Tags**: `['fpr', 'analytics', 'kpi', 'executive']`

---

### 2. vw_fpr_product_recommendation_performance
**Purpose**: Analyze product recommendation effectiveness and conversion rates

**Key Metrics**:
- Recommendation approval rates by product type
- Average recommendation scores for approved vs. declined
- Conversion metrics and sales amounts
- Time to decision (days from recommendation to status change)
- Product affinity correlation with approval rates

**Use Cases**:
- Optimize cross-sell and upsell strategies
- Identify high-performing product recommendations
- Refine recommendation algorithms
- Sales team performance analysis

**Tags**: `['fpr', 'analytics', 'recommendations', 'conversion']`

---

### 3. vw_fpr_churn_risk_analysis
**Purpose**: Identify at-risk customers and churn patterns for retention efforts

**Key Metrics**:
- Customer counts by risk category (High/Medium/Low)
- Average churn probability by segment and lifecycle stage
- Total account balance at risk
- Customer satisfaction correlation with churn
- Engagement metrics (days since lifecycle change)

**Use Cases**:
- Proactive customer retention
- Risk-based portfolio management
- Targeted retention campaigns
- Customer success interventions

**Tags**: `['fpr', 'analytics', 'churn', 'retention']`

---

### 4. vw_fpr_data_quality
**Purpose**: Monitor data completeness, freshness, and integrity

**Quality Checks**:
- **Completeness**: Missing emails, account balances, transaction counts
- **Integrity**: Duplicate customer IDs, orphaned recommendations
- **Validity**: Score ranges (0-1), negative balances
- **Freshness**: Hours since last sync, records synced today

**Use Cases**:
- Data governance and monitoring
- Pipeline health tracking
- Alerting on data quality issues
- Compliance reporting

**Tags**: `['fpr', 'data_quality', 'monitoring']`

---

### 5. vw_fpr_high_value_engagement_alerts
**Purpose**: Identify high-value customers requiring immediate attention

**Alert Types**:
1. **Critical - High Balance + High Churn**: Customers with >$75K balance and >60% churn risk
2. **High - Declined Recommendation**: Active customers with declined recommendations in last 90 days
3. **High - Stalled Lifecycle**: Engaged/Lead/Prospect customers stalled >120 days
4. **Critical - Disengaged High Spender**: High transaction value (>$8K) showing disengagement
5. **Medium - Low Satisfaction + High Affinity**: Low satisfaction (<30%) with high product interest (>80%)

**Use Cases**:
- Proactive relationship management
- Executive escalation workflow
- VIP customer retention
- Service recovery opportunities

**Tags**: `['fpr', 'alerts', 'operations', 'retention']`

---

## 🚀 Installation Instructions

### Step 1: Copy Files to Your dbt Project

Copy the FPR model files into your existing `dbt_industries_views` project:

```bash
# Navigate to your dbt project
cd ~/path/to/dbt_industries_views

# Create FPR models directory
mkdir -p models/fpr

# Copy the 7 files from Claude:
# - _fpr__sources.yml
# - schema.yml
# - vw_fpr_customer_portfolio_kpi.sql
# - vw_fpr_product_recommendation_performance.sql
# - vw_fpr_churn_risk_analysis.sql
# - vw_fpr_data_quality.sql
# - vw_fpr_high_value_engagement_alerts.sql
```

### Step 2: Update dbt_project.yml

Add the FPR configuration to your existing `dbt_project.yml`:

```yaml
models:
  dbt_industries_views:
    # ... your existing models (cds, etc.) ...
    
    # NEW: FPR Models
    fpr:
      +tags: ['fpr', 'financial_services', 'industries']
      +schema: industries_financial_services_dbt
      +materialized: view
      +persist_docs:
        relation: true
        columns: true

vars:
  # ... your existing variables ...
  
  # NEW: FPR Source Configuration
  fpr_source_database: 'HOL_DATABASE'
  fpr_source_schema: 'INDUSTRIES_FINANCIAL_SERVICES'
  fpr_source_table: 'FPR_RECORDS'
```

See `dbt_project_yml_update.txt` for the complete configuration example.

### Step 3: Test Locally

```bash
# Verify connection
dbt debug

# Compile FPR models only
dbt compile --select "tag:fpr"

# Run FPR models
dbt run --select "tag:fpr"

# Run tests
dbt test --select "tag:fpr"
```

**Expected Output**:
```
Completed successfully

Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5
```

### Step 4: Verify in Snowflake

```sql
-- Check that views were created
SHOW VIEWS IN SCHEMA INDUSTRIES_FINANCIAL_SERVICES_DBT;

-- Query the KPI dashboard
SELECT * 
FROM INDUSTRIES_FINANCIAL_SERVICES_DBT.VW_FPR_CUSTOMER_PORTFOLIO_KPI 
LIMIT 10;

-- Check data quality
SELECT * 
FROM INDUSTRIES_FINANCIAL_SERVICES_DBT.VW_FPR_DATA_QUALITY
WHERE threshold_status IN ('Warning', 'Fail');

-- View high-priority alerts
SELECT * 
FROM INDUSTRIES_FINANCIAL_SERVICES_DBT.VW_FPR_HIGH_VALUE_ENGAGEMENT_ALERTS
WHERE alert_priority = 'Critical'
ORDER BY account_balance DESC;
```

---

## 📚 View Dependencies

```
Source Table: FPR_RECORDS
    ↓
    ├── vw_fpr_customer_portfolio_kpi (KPI metrics)
    ├── vw_fpr_product_recommendation_performance (Conversion analysis)
    ├── vw_fpr_churn_risk_analysis (Risk segmentation)
    ├── vw_fpr_data_quality (Quality monitoring)
    └── vw_fpr_high_value_engagement_alerts (Operational alerts)
```

All views are independent and can be run in any order.

---

## 🔄 Fivetran Integration

These models are designed to work with Fivetran dbt Core Transformations:

### Option A: Run After Every Sync

Configure in Fivetran to run automatically after the industries connector syncs:

1. In Fivetran: Connectors → industries → Transformations
2. Add transformation: Select your dbt project
3. Trigger: "After connector sync"

### Option B: Scheduled Runs

Set up a schedule in your orchestration tool:

```bash
# Daily run at 6 AM
dbt run --select "tag:fpr"
```

---

## 🎨 Customization Examples

### Add a New View

Create `models/fpr/vw_fpr_segment_trends.sql`:

```sql
{{
    config(
        materialized='view',
        tags=['fpr', 'analytics', 'trends']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
    WHERE _fivetran_deleted = FALSE
),

monthly_trends AS (
    SELECT
        DATE_TRUNC('month', product_sales_date) AS sales_month,
        customer_segment,
        COUNT(DISTINCT customer_id) AS customer_count,
        SUM(product_sales_amount) AS total_sales,
        AVG(customer_satisfaction_score) AS avg_satisfaction
    FROM source
    WHERE product_sales_date IS NOT NULL
    GROUP BY 
        DATE_TRUNC('month', product_sales_date),
        customer_segment
)

SELECT * FROM monthly_trends
ORDER BY sales_month DESC, customer_segment
```

### Modify Existing View

To change alert thresholds in `vw_fpr_high_value_engagement_alerts.sql`:

```sql
-- Original: account_balance > 75000
-- Modified: account_balance > 50000

WHERE account_balance > 50000  -- Lower threshold for alerts
AND customer_churn_probability > 0.6
```

### Add dbt Tests

Create `models/fpr/fpr_tests.yml`:

```yaml
version: 2

models:
  - name: vw_fpr_customer_portfolio_kpi
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - metric_category
            - metric_name
            - segment_detail
```

---

## 🧪 Testing

### Run All FPR Tests

```bash
# Run all tests for FPR models
dbt test --select "tag:fpr"

# Test specific model
dbt test --select vw_fpr_customer_portfolio_kpi

# Test source freshness
dbt source freshness --select source:fpr
```

### Sample Test Queries

```sql
-- Verify KPI totals match source
SELECT 
    (SELECT metric_value FROM vw_fpr_customer_portfolio_kpi 
     WHERE metric_name = 'Total Customers') AS kpi_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM fpr_records 
     WHERE _fivetran_deleted = FALSE) AS source_customers;

-- Check data quality view returns results
SELECT COUNT(*) 
FROM vw_fpr_data_quality
WHERE threshold_status IN ('Warning', 'Fail');

-- Verify alerts are actionable
SELECT alert_priority, COUNT(*) AS alert_count
FROM vw_fpr_high_value_engagement_alerts
GROUP BY alert_priority;
```

---

## 📊 Business Intelligence Integration

### Tableau / Power BI

Connect to views in the `INDUSTRIES_FINANCIAL_SERVICES_DBT` schema:

**Recommended Dashboards**:
1. **Executive Dashboard**: Use `vw_fpr_customer_portfolio_kpi`
2. **Retention Dashboard**: Use `vw_fpr_churn_risk_analysis` + `vw_fpr_high_value_engagement_alerts`
3. **Sales Performance**: Use `vw_fpr_product_recommendation_performance`
4. **Data Quality Monitor**: Use `vw_fpr_data_quality`

### Reverse ETL (Census, Hightouch)

Sync alerts to CRM/Support tools:

```sql
-- Sync critical alerts to Salesforce
SELECT 
    customer_id,
    customer_email,
    alert_type,
    alert_reason,
    recommended_action
FROM vw_fpr_high_value_engagement_alerts
WHERE alert_priority = 'Critical'
```

---

## 🔧 Troubleshooting

### Views Not Creating

**Check source table exists**:
```sql
SELECT COUNT(*) FROM HOL_DATABASE.INDUSTRIES_FINANCIAL_SERVICES.FPR_RECORDS;
```

**Check schema permissions**:
```sql
SHOW GRANTS ON SCHEMA INDUSTRIES_FINANCIAL_SERVICES_DBT;
```

**Review dbt logs**:
```bash
cat logs/dbt.log
```

### Data Quality Issues

**High null percentages**:
- Review data pipeline configuration
- Check Fivetran connector sync settings
- Validate source data completeness

**Freshness failures**:
- Check Fivetran sync schedule
- Review connector status in Fivetran UI
- Verify network connectivity

### Performance Issues

**Views slow to query**:
- Consider materializing as tables instead of views
- Add incremental materialization for large datasets
- Create aggregated summary tables

```yaml
# Change materialization to table
models:
  fpr:
    vw_fpr_customer_portfolio_kpi:
      +materialized: table
```

---

## 📖 Documentation

### Generate dbt Docs

```bash
# Generate documentation
dbt docs generate

# Serve documentation site
dbt docs serve
```

View at: http://localhost:8080

### Update Documentation

Edit column descriptions in `schema.yml`:

```yaml
models:
  - name: vw_fpr_customer_portfolio_kpi
    description: "Your updated description here"
    columns:
      - name: metric_name
        description: "Your column description"
```

---

## 🆘 Support Resources

- **dbt Documentation**: https://docs.getdbt.com
- **Fivetran dbt Integration**: https://fivetran.com/docs/transformations/dbt
- **Snowflake dbt Adapter**: https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup

---

## 📝 Version History

**Version 1.0.0** (Initial Release)
- 5 analytical views for Financial Services industry
- Complete documentation and tests
- Fivetran integration ready
- Source: Fivetran PSE dbt Project Builder Skill

---

**Generated by**: Fivetran PSE dbt Project Builder Skill  
**Date**: November 4, 2025  
**Industry**: Financial Services (FPR)  
**Connector**: industries (Fivetran)
