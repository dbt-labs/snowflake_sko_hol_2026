# Adding Construction (CON) to Your Multi-Industry dbt Project

## 📋 Quick Integration

Copy the `con/` folder into your existing `DBT-INDUSTRIES-VIEWS/models/` directory alongside your `cds/` and `mso/` folders.

### Before:
```
DBT-INDUSTRIES-VIEWS/
└── models/
    ├── cds/
    └── mso/
```

### After:
```
DBT-INDUSTRIES-VIEWS/
└── models/
    ├── cds/
    ├── mso/
    └── con/              # NEW ✨
        ├── _con_sources.yml
        ├── schema.yml
        ├── vw_con_kpi.sql
        ├── vw_con_by_project.sql
        ├── vw_con_weather_impact.sql
        ├── vw_con_data_quality.sql
        ├── vw_con_critical_alerts.sql
        └── README.md
```

## ✅ Integration Steps

### Step 1: Copy the CON Folder
```bash
# From your project root
cp -r con/ models/
```

### Step 2: Update dbt_project.yml
Add CON configuration to your existing project config:

```yaml
models:
  dbt_industries_views:  # Your existing project name
    +materialized: view
    +schema: views
    +database: HOL_DATABASE
    
    cds:
      # Your existing CDS config
      
    mso:
      # Your existing MSO config
      
    con:  # NEW
      +tags: ['construction', 'con']
      +materialized: view
```

### Step 3: Test Compilation
```bash
# Compile just CON models
dbt compile --select con

# Run CON models
dbt run --select con
```

### Step 4: Verify Views Created
```sql
-- Check views exist
SHOW VIEWS IN SCHEMA HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS;

-- Test a query
SELECT * FROM HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS.vw_con_kpi;
```

## 🎯 What You're Getting

### 5 Production-Ready Views:

1. **vw_con_kpi** - Executive KPI dashboard
   - Portfolio-wide metrics
   - EVM performance indices (SPI, CPI)
   - Risk profile and critical path analysis

2. **vw_con_by_project** - Project performance analysis
   - Metrics segmented by project
   - Project health score (0-100)
   - Task status breakdowns

3. **vw_con_weather_impact** - Weather impact analysis
   - Delay rates by weather condition
   - Weather severity score (0-100)
   - Equipment breakdown correlations

4. **vw_con_data_quality** - Data quality monitoring
   - Field completeness checks
   - Logical consistency validation
   - Overall quality score (0-100)

5. **vw_con_critical_alerts** - Critical alerts
   - High-priority tasks requiring attention
   - Alert priority score (0-100)
   - Recommended actions

## 🏷️ Tag-Based Execution

Run views selectively across all industries:

```bash
# All construction views
dbt run --select tag:construction

# All analytics across all industries
dbt run --select tag:analytics

# All data quality views
dbt run --select tag:data_quality

# All alerts
dbt run --select tag:alerts
```

## 🔧 Target Schema

Views will be created in:
- **Schema:** `HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS`

This matches your pattern where each industry has views in a `VIEWS` subfolder under their source schema.

## 📊 Key Metrics

### EVM Performance Indices
- **SPI (Schedule Performance Index):** >1.0 = ahead, <1.0 = behind
- **CPI (Cost Performance Index):** >1.0 = under budget, <1.0 = over budget

### Composite Scores
- **Project Health Score (0-100):** Cost (30%) + Schedule (30%) + Risk inverse (20%) + Completion (20%)
- **Weather Severity Score (0-100):** Delay rate (40%) + Schedule variance (30%) + Equipment issues (30%)
- **Alert Priority Score (0-100):** Weighted sum of alert categories

## 🚀 Next Steps

1. **Run the views:** `dbt run --select con`
2. **Update documentation:** `dbt docs generate && dbt docs serve`
3. **Create dashboards:** Use views in your BI tool
4. **Set up monitoring:** Schedule queries on critical alerts view
5. **Track quality:** Monitor data quality score over time

## 📞 Support

If you encounter issues:
- **Compilation errors:** Check column names match exactly (case-sensitive)
- **Permission errors:** Ensure user can CREATE VIEW in INDUSTRIES_CONSTRUCTION.VIEWS
- **Empty views:** Verify CON_RECORDS table has data
- **Schema not found:** Confirm Fivetran connector syncing to INDUSTRIES_CONSTRUCTION

---

**Ready to integrate!** Just copy the `con/` folder into `models/` and update your `dbt_project.yml`. 🎯
