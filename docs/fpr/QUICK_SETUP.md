# FPR Models - Quick Setup Guide

## 📦 What You're Getting

**7 Files for Financial Services (FPR) Industry:**
1. `_fpr__sources.yml` - Source definitions for FPR_RECORDS table
2. `schema.yml` - Model documentation for all 5 views
3. `vw_fpr_customer_portfolio_kpi.sql` - Executive KPI dashboard
4. `vw_fpr_product_recommendation_performance.sql` - Recommendation conversion analysis
5. `vw_fpr_churn_risk_analysis.sql` - Customer churn risk segmentation
6. `vw_fpr_data_quality.sql` - Data quality monitoring
7. `vw_fpr_high_value_engagement_alerts.sql` - High-value customer alerts

**Plus Documentation:**
- `README_FPR.md` - Complete documentation for FPR models
- `dbt_project_yml_update.txt` - Configuration to add to your dbt_project.yml

---

## 🚀 5-Minute Setup

### Step 1: Download and Extract (1 min)

Download `fpr_models.zip` and extract to your dbt project:

```bash
# Navigate to your dbt project
cd ~/path/to/dbt_industries_views

# Extract files (creates models/fpr/ directory)
# Place the 7 .sql and .yml files in: models/fpr/
```

### Step 2: Update dbt_project.yml (2 min)

Open your `dbt_project.yml` and add this to your `models:` section:

```yaml
models:
  dbt_industries_views:
    # ... your existing models (cds, etc.) ...
    
    fpr:
      +tags: ['fpr', 'financial_services', 'industries']
      +schema: industries_financial_services_dbt
      +materialized: view
```

Add to your `vars:` section:

```yaml
vars:
  # ... your existing variables ...
  
  fpr_source_database: 'HOL_DATABASE'
  fpr_source_schema: 'INDUSTRIES_FINANCIAL_SERVICES'
  fpr_source_table: 'FPR_RECORDS'
```

See `dbt_project_yml_update.txt` for complete example.

### Step 3: Test Locally (2 min)

```bash
# Compile FPR models
dbt compile --select "tag:fpr"

# Run FPR models
dbt run --select "tag:fpr"
```

**Expected Output:**
```
Completed successfully

Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5
```

---

## ✅ Verify in Snowflake

```sql
-- List created views
SHOW VIEWS IN SCHEMA INDUSTRIES_FINANCIAL_SERVICES_DBT;

-- Query the KPI dashboard
SELECT * 
FROM INDUSTRIES_FINANCIAL_SERVICES_DBT.VW_FPR_CUSTOMER_PORTFOLIO_KPI 
WHERE metric_category = 'Portfolio Overview'
LIMIT 10;

-- Check for alerts
SELECT alert_priority, alert_type, COUNT(*) AS count
FROM INDUSTRIES_FINANCIAL_SERVICES_DBT.VW_FPR_HIGH_VALUE_ENGAGEMENT_ALERTS
GROUP BY alert_priority, alert_type
ORDER BY alert_priority;
```

---

## 📁 Your Project Structure (After Setup)

```
dbt_industries_views/
├── dbt_project.yml              # Updated with FPR config
├── models/
│   ├── cds/                     # Your existing Healthcare models
│   │   ├── _cds__sources.yml
│   │   ├── schema.yml
│   │   └── vw_cds_*.sql
│   └── fpr/                     # NEW: Financial Services models
│       ├── _fpr__sources.yml
│       ├── schema.yml
│       ├── vw_fpr_customer_portfolio_kpi.sql
│       ├── vw_fpr_product_recommendation_performance.sql
│       ├── vw_fpr_churn_risk_analysis.sql
│       ├── vw_fpr_data_quality.sql
│       └── vw_fpr_high_value_engagement_alerts.sql
└── macros/
    └── generate_schema_name.sql
```

---

## 🎯 What Each View Does

### vw_fpr_customer_portfolio_kpi
Executive dashboard showing total customers, account balances, transaction metrics, satisfaction scores, and churn probabilities segmented by customer segment, lifecycle stage, and product type.

### vw_fpr_product_recommendation_performance
Analyzes which product recommendations convert best, approval rates by segment, average recommendation scores, and sales amounts from approved recommendations.

### vw_fpr_churn_risk_analysis
Segments customers by churn risk (High/Medium/Low) with metrics on account balances at risk, satisfaction scores, and engagement indicators.

### vw_fpr_data_quality
Monitors data completeness (missing fields), integrity (duplicates), validity (score ranges), and freshness (hours since sync).

### vw_fpr_high_value_engagement_alerts
Identifies 5 types of at-risk situations requiring immediate attention:
- Critical: High balance + high churn risk
- High: Declined recommendations
- High: Stalled lifecycle progression
- Critical: Disengaged high spenders
- Medium: Low satisfaction + high product affinity

---

## 🔄 Running Specific Views

```bash
# Run all FPR models
dbt run --select "tag:fpr"

# Run only KPI dashboard
dbt run --select vw_fpr_customer_portfolio_kpi

# Run only data quality check
dbt run --select vw_fpr_data_quality

# Run analytics views (excluding alerts)
dbt run --select "tag:analytics,tag:fpr"

# Run data quality and alerts
dbt run --select "tag:data_quality,tag:alerts,tag:fpr"
```

---

## 🐛 Troubleshooting

### Error: "Source not found"
- Check that `FPR_RECORDS` table exists in `INDUSTRIES_FINANCIAL_SERVICES` schema
- Verify database/schema names in `dbt_project.yml` vars match your environment

### Error: "Schema does not exist"
- Your dbt role needs CREATE SCHEMA permission
- Or pre-create schema: `CREATE SCHEMA INDUSTRIES_FINANCIAL_SERVICES_DBT;`

### Views are empty
- Check source table has data: `SELECT COUNT(*) FROM FPR_RECORDS;`
- Verify `_fivetran_deleted = FALSE` filter isn't excluding all records

### "zsh: no matches found" error
Always quote selectors in zsh:
```bash
dbt run --select "tag:fpr"  # ✅ Correct
dbt run --select tag:fpr    # ❌ Fails in zsh
```

---

## 📚 Next Steps

1. **Review the README_FPR.md** for complete documentation
2. **Customize thresholds** in alert views for your business needs
3. **Add to BI tool** (Tableau, Power BI, Looker)
4. **Set up monitoring** on data quality view
5. **Create workflows** from high-value alerts view

---

## 💡 Pro Tips

- Run `vw_fpr_data_quality` first to check source data health
- Schedule `vw_fpr_high_value_engagement_alerts` to run daily
- Export alerts to your CRM via Reverse ETL (Census, Hightouch)
- Use `vw_fpr_customer_portfolio_kpi` for executive dashboards
- Monitor `vw_fpr_churn_risk_analysis` weekly for retention planning

---

**Need Help?** See README_FPR.md for detailed documentation, customization examples, and BI integration patterns.

**Generated**: November 4, 2025  
**Industry**: Financial Services (FPR)  
**Models**: 5 views across analytics, data quality, and operations
