# CPG Industry Models - Integration Guide

## Overview

This package contains 5 CPG-specific analytical views designed to integrate into your existing `dbt_industries_views` project. These models follow your established naming conventions and project structure.

**Generated Models:**
1. `vw_cpg_pricing_optimization_kpi` - Pricing strategy effectiveness dashboard
2. `vw_cpg_inventory_health_by_category` - Inventory management by category
3. `vw_cpg_customer_segment_performance` - Customer LTV and behavior analysis
4. `vw_cpg_demand_forecast_accuracy` - Demand planning quality metrics
5. `vw_cpg_data_quality` - Data quality monitoring and freshness

## Integration Steps

### Step 1: Copy Files to Your Project

Copy the CPG models into your existing project structure:

```bash
# Navigate to your dbt project root
cd dbt_industries_views/

# Create the CPG directory
mkdir -p models/cpg/

# Copy all files from this package
cp _cpg__sources.yml models/cpg/
cp schema.yml models/cpg/
cp vw_cpg_*.sql models/cpg/
```

Your project structure should now look like:

```
dbt_industries_views/
├── models/
│   ├── cds/                          # Healthcare industry models
│   │   ├── _cds__sources.yml
│   │   ├── schema.yml
│   │   └── vw_cds_*.sql
│   └── cpg/                          # ⭐ NEW: CPG industry models
│       ├── _cpg__sources.yml         # ⭐ Source definitions
│       ├── schema.yml                # ⭐ Model documentation
│       ├── vw_cpg_pricing_optimization_kpi.sql
│       ├── vw_cpg_inventory_health_by_category.sql
│       ├── vw_cpg_customer_segment_performance.sql
│       ├── vw_cpg_demand_forecast_accuracy.sql
│       └── vw_cpg_data_quality.sql
```

### Step 2: Update dbt_project.yml

Add the CPG models configuration to your `dbt_project.yml`:

```yaml
models:
  dbt_industries_views:
    cds:
      +schema: cds
      +materialized: view
      +tags: ['healthcare', 'cds']
    
    cpg:                              # ⭐ ADD THIS SECTION
      +schema: cpg                    # Creates views in CPG schema
      +materialized: view
      +tags: ['cpg', 'consumer_packaged_goods']
```

This configuration ensures CPG views are created in a `cpg` schema (following your existing pattern with `cds` schema).

### Step 3: Verify Source Configuration

Confirm your Snowflake connection has access to the CPG data:

**Database:** `HOL_DATABASE`  
**Schema:** `INDUSTRIES_CONSUMER_PACKAGED_GOODS`  
**Table:** `CPG_RECORDS`

The source is already configured in `_cpg__sources.yml` to match these values.

### Step 4: Test the Models Locally

```bash
# Compile the models (check for syntax errors)
dbt compile --select cpg

# Run the CPG models
dbt run --select cpg

# Run tests (if any)
dbt test --select cpg

# Generate documentation
dbt docs generate
dbt docs serve
```

### Step 5: Selective Model Execution

Run specific CPG models using tags or model names:

```bash
# Run all CPG models
dbt run --select tag:cpg

# Run only pricing optimization view
dbt run --select vw_cpg_pricing_optimization_kpi

# Run only data quality view
dbt run --select tag:data_quality

# Run analytics views (exclude data quality)
dbt run --select tag:cpg,tag:analytics
```

## Model Details

### 1. Pricing Optimization KPI (`vw_cpg_pricing_optimization_kpi`)

**Purpose:** Executive dashboard for dynamic pricing effectiveness

**Key Metrics:**
- Optimization success rate: % of successful price changes
- Pricing lift: Revenue impact of optimization vs. standard pricing
- Category performance: Which categories respond best to pricing strategies
- Elasticity insights: Price sensitivity analysis

**Business Questions Answered:**
- Is our dynamic pricing strategy working?
- Which product categories benefit most from price optimization?
- What's the ROI of our pricing optimization initiatives?

**Use Cases:**
- Executive KPI reporting
- Pricing strategy evaluation
- Category-specific pricing decisions

---

### 2. Inventory Health by Category (`vw_cpg_inventory_health_by_category`)

**Purpose:** Inventory management dashboard with health scoring

**Key Metrics:**
- Inventory turnover: How quickly inventory moves
- Stockout risk: Products at risk of running out
- Overstock risk: Products with excess inventory
- Health score: 0-100 score for each category

**Business Questions Answered:**
- Which categories have inventory issues?
- Where should we increase/decrease stock levels?
- What's our working capital efficiency by category?

**Use Cases:**
- Supply chain planning
- Working capital optimization
- Stockout prevention

---

### 3. Customer Segment Performance (`vw_cpg_customer_segment_performance`)

**Purpose:** Customer LTV and behavior analysis by segment

**Key Metrics:**
- Average LTV by High/Medium/Low value segments
- Order frequency and AOV patterns
- Customer satisfaction rates
- Product category preferences

**Business Questions Answered:**
- Who are our most valuable customers?
- How do customer segments behave differently?
- Where should we focus acquisition/retention efforts?

**Use Cases:**
- Customer acquisition strategy
- Retention program design
- Segment-specific marketing campaigns

---

### 4. Demand Forecast Accuracy (`vw_cpg_demand_forecast_accuracy`)

**Purpose:** Demand planning quality assessment

**Key Metrics:**
- Forecast accuracy by demand tier
- Inventory positioning (over/under stocked)
- Order fulfillment rates
- Cancellation patterns

**Business Questions Answered:**
- How accurate are our demand forecasts?
- Which demand tiers have inventory imbalances?
- Where should we improve forecasting?

**Use Cases:**
- Demand planning optimization
- Inventory investment decisions
- Forecast model validation

---

### 5. Data Quality Monitoring (`vw_cpg_data_quality`)

**Purpose:** Data health monitoring and anomaly detection

**Key Metrics:**
- Completeness: % of critical fields populated
- Freshness: Time since last Fivetran sync
- Duplicate detection: Duplicate record counts
- Value validation: Out-of-range or invalid values

**Business Questions Answered:**
- Is our CPG data reliable?
- When was data last refreshed?
- What data quality issues need attention?

**Use Cases:**
- Analytics reliability monitoring
- Data pipeline health checks
- Proactive issue detection

## Customization Options

### Adjust Schema Names

If you want to use different schema naming, update `dbt_project.yml`:

```yaml
models:
  dbt_industries_views:
    cpg:
      +schema: consumer_packaged_goods  # Custom schema name
```

### Change Materialization

For larger datasets, consider materializing as tables:

```yaml
models:
  dbt_industries_views:
    cpg:
      +materialized: table              # Materialize as tables
      +tags: ['cpg', 'daily_refresh']
```

### Add Incremental Models

For very large tables, convert to incremental models by modifying the config block:

```sql
{{
  config(
    materialized='incremental',
    unique_key='record_id',
    tags=['cpg', 'analytics']
  )
}}
```

### Apply Row-Level Security

Add where clauses for user-specific filtering:

```sql
WHERE _fivetran_deleted = FALSE
  {% if var('user_segment', none) %}
  AND customer_segment = '{{ var("user_segment") }}'
  {% endif %}
```

## Fivetran Integration

These models are designed to work with **Fivetran dbt Core Transformations**:

1. Commit CPG models to your Git repository
2. Connect Fivetran to your Git repo
3. Configure dbt Core transformation in Fivetran
4. Models run automatically after connector syncs

**Fivetran Configuration:**
- **Git Repository:** Your existing repo for `dbt_industries_views`
- **Git Branch:** `main` (or your deployment branch)
- **Project Subdirectory:** (root) or `/dbt_industries_views/` if nested
- **Run Mode:** After connector sync

## Troubleshooting

### "Source not found" error

**Problem:** dbt can't find the CPG source table

**Solution:** Verify database and schema names in `_cpg__sources.yml` match your Snowflake configuration:

```yaml
sources:
  - name: cpg
    database: HOL_DATABASE                        # ← Confirm this matches
    schema: INDUSTRIES_CONSUMER_PACKAGED_GOODS    # ← Confirm this matches
```

### "Column not found" error

**Problem:** Column name mismatch

**Solution:** Run `SHOW COLUMNS IN TABLE HOL_DATABASE.INDUSTRIES_CONSUMER_PACKAGED_GOODS.CPG_RECORDS;` and verify column names match exactly (case-sensitive on Snowflake).

### Views are empty

**Problem:** No data in views after creation

**Solution:**
1. Check source table has data: `SELECT COUNT(*) FROM HOL_DATABASE.INDUSTRIES_CONSUMER_PACKAGED_GOODS.CPG_RECORDS WHERE _FIVETRAN_DELETED = FALSE;`
2. Verify Fivetran connector is syncing successfully
3. Check for overly restrictive filters in views

### Performance issues

**Problem:** Queries are slow

**Solution:**
1. Materialize views as tables: `+materialized: table`
2. Add clustering keys in Snowflake on commonly filtered columns
3. Consider incremental models for very large tables

## Next Steps

Once CPG models are integrated:

1. **Add more industries:** Follow the same pattern for AGR, MET, etc.
2. **Create cross-industry dashboards:** Build views that compare metrics across industries
3. **Add dbt tests:** Implement data quality tests in `schema.yml`
4. **Build metrics:** Define metrics using dbt metrics for BI tool integration
5. **Create exposures:** Document how these views are used in downstream tools

## Support

For questions about:
- **dbt modeling:** Refer to [dbt documentation](https://docs.getdbt.com/)
- **Fivetran integration:** Check [Fivetran dbt Core docs](https://fivetran.com/docs/transformations/dbt)
- **CPG model logic:** Review inline comments in each `.sql` file

---

**Models Generated:** November 2025  
**dbt Version:** dbt Core 1.6+  
**Warehouse:** Snowflake  
**Source:** Fivetran Industries Connector
