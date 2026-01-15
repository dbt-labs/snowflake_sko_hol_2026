# CPG Models Quick Reference

## 🎯 The 5 Views at a Glance

| View Name | Purpose | Key Question Answered | Primary Tags |
|-----------|---------|----------------------|--------------|
| `vw_cpg_pricing_optimization_kpi` | Pricing strategy effectiveness | Is dynamic pricing working? | `pricing`, `kpi` |
| `vw_cpg_inventory_health_by_category` | Inventory management | Which categories need stock adjustments? | `inventory`, `operations` |
| `vw_cpg_customer_segment_performance` | Customer LTV analysis | Who are our most valuable customers? | `customer`, `segmentation` |
| `vw_cpg_demand_forecast_accuracy` | Forecasting quality | How accurate are our forecasts? | `forecasting`, `planning` |
| `vw_cpg_data_quality` | Data reliability | Is our CPG data trustworthy? | `data_quality`, `monitoring` |

---

## ⚡ Quick Commands

```bash
# Run all CPG models
dbt run --select tag:cpg

# Run only pricing view
dbt run --select vw_cpg_pricing_optimization_kpi

# Run only data quality monitoring
dbt run --select tag:data_quality

# Run analytics views (exclude data quality)
dbt run --select tag:cpg,tag:analytics

# Compile without running (check syntax)
dbt compile --select tag:cpg

# Generate docs
dbt docs generate --select tag:cpg
```

---

## 📊 Key Metrics by View

### Pricing Optimization KPI
- ✅ Optimization Success Rate %
- 💰 Revenue from Optimized Pricing
- 📈 Pricing Lift %
- 🎯 Best Performing Category
- 📉 Average Price Elasticity

### Inventory Health by Category
- 🔄 Average Inventory Turnover
- ⚠️ Stockout Risk Level
- 📦 Overstock Risk Level
- 💯 Inventory Health Score (0-100)
- 💡 Recommended Action

### Customer Segment Performance
- 💎 Average Customer LTV
- 📊 Orders per Customer
- 💵 Revenue per Customer
- ⭐ Satisfaction Rate %
- 💯 Segment Health Score (0-100)

### Demand Forecast Accuracy
- 📋 Well-Stocked %
- ✅ Fulfillment Rate %
- ❌ Cancellation Rate %
- 💯 Forecast Accuracy Score (0-100)
- 💰 Revenue per Forecast Unit

### Data Quality
- ✅ Completeness Score (0-100)
- 🕐 Hours Since Last Sync
- 🔍 Duplicate Record Count
- ⚠️ Total Validation Issues
- 💯 Overall Quality Score (0-100)

---

## 🏗️ Project Structure

```
models/cpg/
├── _cpg__sources.yml              # Source table definitions
├── schema.yml                      # Model documentation
├── vw_cpg_pricing_optimization_kpi.sql
├── vw_cpg_inventory_health_by_category.sql
├── vw_cpg_customer_segment_performance.sql
├── vw_cpg_demand_forecast_accuracy.sql
└── vw_cpg_data_quality.sql
```

---

## 🎨 dbt_project.yml Configuration

```yaml
models:
  dbt_industries_views:
    cpg:
      +schema: cpg                # Creates views in 'cpg' schema
      +materialized: view         # Default: view (change to 'table' for performance)
      +tags: ['cpg']
```

---

## 🔗 Source Configuration

**Database:** `HOL_DATABASE`  
**Schema:** `INDUSTRIES_CONSUMER_PACKAGED_GOODS`  
**Table:** `CPG_RECORDS`  
**Connector:** Fivetran Industries

All views reference: `{{ source('cpg', 'cpg_records') }}`

---

## 🎯 Tag Strategy

Use tags for selective execution:

| Tag | Models Included | Use Case |
|-----|----------------|----------|
| `cpg` | All 5 models | Run entire CPG suite |
| `analytics` | 4 models (exclude data_quality) | Business analysis only |
| `data_quality` | 1 model | Monitoring & validation |
| `pricing` | 1 model | Pricing strategy only |
| `inventory` | 1 model | Inventory management only |
| `customer` | 1 model | Customer analysis only |
| `forecasting` | 1 model | Demand planning only |

---

## 🔧 Common Customizations

### Change Schema Name
```yaml
models:
  dbt_industries_views:
    cpg:
      +schema: consumer_packaged_goods  # Custom name
```

### Materialize as Tables
```yaml
models:
  dbt_industries_views:
    cpg:
      +materialized: table  # Better performance for large datasets
```

### Add Incremental Loading
In each `.sql` file, change the config:
```sql
{{
  config(
    materialized='incremental',
    unique_key='record_id'
  )
}}
```

---

## 🎓 Score Interpretation

All analytical views include health scores (0-100):

| Score Range | Status | Action |
|-------------|--------|--------|
| 80-100 | Excellent | Maintain current approach |
| 60-79 | Good | Minor optimization opportunities |
| 40-59 | Fair | Needs attention |
| 0-39 | Poor | Immediate intervention required |

---

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Source not found" | Verify database/schema names in `_cpg__sources.yml` |
| "Column not found" | Run `SHOW COLUMNS` to verify exact column names |
| Views are empty | Check source table: `SELECT COUNT(*) FROM ... WHERE _fivetran_deleted = FALSE` |
| Slow queries | Change to `+materialized: table` in config |
| Compilation errors | Run `dbt compile --select cpg` for detailed error messages |

---

## 📁 Files Quick Links

- [View README](computer:///mnt/user-data/outputs/README.md) - Complete integration guide
- [View IMPLEMENTATION_SUMMARY](computer:///mnt/user-data/outputs/IMPLEMENTATION_SUMMARY.md) - Analysis results & insights
- [View _cpg__sources.yml](computer:///mnt/user-data/outputs/_cpg__sources.yml) - Source definitions
- [View schema.yml](computer:///mnt/user-data/outputs/schema.yml) - Model documentation
- [View vw_cpg_pricing_optimization_kpi.sql](computer:///mnt/user-data/outputs/vw_cpg_pricing_optimization_kpi.sql)
- [View vw_cpg_inventory_health_by_category.sql](computer:///mnt/user-data/outputs/vw_cpg_inventory_health_by_category.sql)
- [View vw_cpg_customer_segment_performance.sql](computer:///mnt/user-data/outputs/vw_cpg_customer_segment_performance.sql)
- [View vw_cpg_demand_forecast_accuracy.sql](computer:///mnt/user-data/outputs/vw_cpg_demand_forecast_accuracy.sql)
- [View vw_cpg_data_quality.sql](computer:///mnt/user-data/outputs/vw_cpg_data_quality.sql)

---

## ⏱️ Typical Timeline

- **5 min:** Copy files to project
- **2 min:** Update dbt_project.yml
- **3 min:** Compile and validate syntax
- **10 min:** Run models for first time
- **15 min:** Review outputs and validate results
- **30 min:** Connect to BI tool

**Total:** ~1 hour from files to dashboards

---

## 🎯 Success Criteria

✅ All 5 views compile without errors  
✅ Views return data (not empty)  
✅ Health scores calculated correctly  
✅ Recommendations appear for each view  
✅ Data freshness is recent (< 24 hours)  
✅ Views accessible in BI tool  
✅ Metrics match business expectations  

---

**Pro Tip:** Start with `vw_cpg_data_quality` first to validate your data foundation before analyzing the other views!
