# MSO Industry - Deployment Guide

## Project: dbt-industries-views
## New Industry: MSO (Manufacturing MSO)

---

## 📦 What's Included

This package contains a complete **MSO** industry folder ready to add to your existing `dbt-industries-views` project:

```
mso/
├── _mso_sources.yml              # Source definition for MSO_RECORDS table
├── schema.yml                     # Full documentation for all 5 views
├── vw_mso_kpi.sql                # Executive KPI dashboard
├── vw_mso_by_cad_system.sql      # CAD platform performance analysis
├── vw_mso_optimization_trends.sql # Monthly time-series trends
├── vw_mso_designer_performance.sql # Designer effectiveness by skill level
├── vw_mso_data_quality.sql       # Data quality monitoring
└── README.md                      # MSO-specific documentation
```

---

## 🚀 Deployment Steps

### Step 1: Add MSO Folder to Project

Copy the entire `mso` folder into your existing project structure:

```bash
# Navigate to your dbt project root
cd dbt-industries-views

# Copy the mso folder to models/
cp -r /path/to/downloaded/mso ./models/
```

Your project structure should now look like:

```
dbt-industries-views/
├── models/
│   ├── cds/                    # Existing CDS industry
│   │   ├── _cds_sources.yml
│   │   ├── schema.yml
│   │   └── vw_*.sql
│   └── mso/                    # NEW MSO industry
│       ├── _mso_sources.yml
│       ├── schema.yml
│       └── vw_*.sql
├── macros/
│   └── generate_schema_name.sql  # Your existing macro for multi-industry routing
├── dbt_project.yml
└── profiles.yml (or profiles.yml.example)
```

---

### Step 2: Verify dbt_project.yml Configuration

Ensure your `dbt_project.yml` has the multi-industry structure configured:

```yaml
name: 'dbt_industries_views'
version: '1.0.0'
config-version: 2

profile: 'snowflake'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  dbt_industries_views:
    # CDS industry configuration
    cds:
      +schema: cds
      +materialized: view
      +tags: ["cds"]
    
    # MSO industry configuration (NEW)
    mso:
      +schema: mso
      +materialized: view
      +tags: ["mso"]
```

If you need to add this configuration, update your `dbt_project.yml` with the `mso:` section shown above.

---

### Step 3: Update Custom Schema Macro (if needed)

Your existing `macros/generate_schema_name.sql` should handle the MSO folder automatically. Verify it looks like this:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}
    {%- endif -%}
{%- endmacro %}
```

This macro routes each industry folder to its own schema:
- `models/cds/` → `INDUSTRIES_CDS` schema
- `models/mso/` → `INDUSTRIES_MANUFACTURING` schema

---

### Step 4: Test Locally

Before deploying to Fivetran, test the MSO models locally:

```bash
# Ensure environment variables are set (if using .env)
source .env

# Test dbt connection
dbt debug

# Compile MSO models (check for syntax errors)
dbt compile --select mso.*

# Run MSO models
dbt run --select mso.*
```

Expected output:
```
Running with dbt=1.x.x
Found 5 models, 0 tests, 0 snapshots, 0 analyses, ...

Completed successfully

Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5
```

---

### Step 5: Verify Views in Snowflake

After running locally, verify the views were created:

```sql
-- Check MSO schema exists
SHOW SCHEMAS LIKE 'INDUSTRIES_MANUFACTURING';

-- Verify all 5 views were created
SHOW VIEWS IN SCHEMA HOL_DATABASE.INDUSTRIES_MANUFACTURING;

-- Test a sample query
SELECT * FROM HOL_DATABASE.INDUSTRIES_MANUFACTURING.VW_MSO_KPI;
```

---

### Step 6: Deploy to Fivetran (if using Fivetran dbt Core)

If you're using Fivetran dbt Core Transformations, commit and push to GitHub:

```bash
# Add MSO folder
git add models/mso/

# Commit changes
git commit -m "Add MSO (Manufacturing MSO) industry to dbt project"

# Push to GitHub
git push origin main
```

Then in Fivetran:

1. Navigate to your dbt Core Transformation
2. Trigger a manual sync or wait for scheduled sync
3. Review execution logs
4. Verify views appear in destination

---

## 🎯 Selective Execution

Run MSO models independently from other industries:

```bash
# Run only MSO models
dbt run --select mso.*

# Run only KPI views across all industries
dbt run --select tag:kpi

# Run CDS and MSO together
dbt run --select cds.* mso.*

# Run everything
dbt run
```

---

## 📊 View Descriptions

| View | Purpose | Key Metrics |
|------|---------|-------------|
| **vw_mso_kpi** | Executive dashboard | Total cost savings, ROI, recommendation rates |
| **vw_mso_by_cad_system** | CAD platform analysis | Performance by SolidWorks, Inventor, Siemens NX |
| **vw_mso_optimization_trends** | Monthly trends | Time-series cost savings, optimization volumes |
| **vw_mso_designer_performance** | Designer effectiveness | Metrics by skill level (Beginner/Intermediate/Advanced) |
| **vw_mso_data_quality** | Data monitoring | Completeness, validity, freshness scores |

---

## 🔧 Configuration Details

### Source Configuration
- **Database:** HOL_DATABASE
- **Schema:** INDUSTRIES_MANUFACTURING
- **Table:** MSO_RECORDS
- **Filtering:** All views exclude soft-deleted records (`WHERE _FIVETRAN_DELETED = FALSE`)

### Target Schema
- **Target:** `INDUSTRIES_MANUFACTURING` (configured via `+schema: mso` in dbt_project.yml)
- **Materialization:** Views (lightweight, always up-to-date)

### Tags
All MSO models include:
- `mso` - Industry-specific tag
- Additional tags per view: `analytics`, `kpi`, `trends`, `designer`, `data_quality`

---

## ✅ Validation Checklist

Before considering deployment complete:

- [ ] MSO folder copied to `models/mso/`
- [ ] `dbt_project.yml` includes MSO configuration
- [ ] `dbt compile --select mso.*` passes without errors
- [ ] `dbt run --select mso.*` creates all 5 views
- [ ] Views visible in `INDUSTRIES_MANUFACTURING` schema in Snowflake
- [ ] Sample queries return data (test `SELECT * FROM vw_mso_kpi`)
- [ ] (If using Fivetran) Changes pushed to GitHub
- [ ] (If using Fivetran) Transformation executes successfully

---

## 🚨 Troubleshooting

### Issue: "Compilation Error - source not found"
**Solution:** Verify `_mso_sources.yml` is in the `mso/` folder and database/schema names match your environment

### Issue: "Schema does not exist"
**Solution:** Ensure `+schema: mso` is in `dbt_project.yml` and `macros/generate_schema_name.sql` exists

### Issue: Views created in wrong schema
**Solution:** Check that `generate_schema_name` macro is properly routing to custom schema names

### Issue: "Column not found" errors
**Solution:** Verify source table column names match exactly (case-sensitive in Snowflake)

---

## 📚 Documentation

Generate and view full documentation:

```bash
dbt docs generate
dbt docs serve
```

Navigate to the MSO models in the documentation site to see:
- Full column descriptions
- Data lineage diagrams
- Source-to-view relationships

---

## 🎓 Next Steps

After deploying MSO:

1. **Share with stakeholders:** Provide access to the INDUSTRIES_MANUFACTURING schema
2. **Create dashboards:** Build Tableau/PowerBI dashboards using the 5 MSO views
3. **Set up alerts:** Monitor `vw_mso_data_quality` for data quality issues
4. **Schedule refreshes:** Configure Fivetran to trigger dbt runs after source syncs
5. **Add more industries:** Follow this same pattern to add additional industries

---

## 📞 Support

For questions or issues:
- Review MSO-specific README in `models/mso/README.md`
- Check dbt documentation: https://docs.getdbt.com
- Review Fivetran dbt Core guide: https://fivetran.com/docs/transformations/dbt

---

**Deployment Date:** 2025-11-03  
**Industry:** MSO (Manufacturing MSO)  
**Views Created:** 5  
**Status:** ✅ Ready for Production
