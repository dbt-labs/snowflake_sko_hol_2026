# FTS Energy Models - Quick Reference

## 🎯 The 5 Views at a Glance

| View Name | Purpose | Key Question | Primary Tags |
|-----------|---------|--------------|--------------|
| `vw_fts_maintenance_efficiency_kpi` | Operations dashboard | Are maintenance operations efficient? | `maintenance`, `kpi` |
| `vw_fts_equipment_reliability_analysis` | Equipment risk tracking | Which equipment needs attention? | `reliability`, `equipment` |
| `vw_fts_maintenance_type_performance` | Strategy comparison | Which maintenance type is most effective? | `maintenance`, `strategy` |
| `vw_fts_technician_productivity` | Workforce analytics | How are technicians performing? | `technician`, `productivity` |
| `vw_fts_data_quality` | Data health monitoring | Is our FTS data reliable? | `data_quality`, `monitoring` |

---

## ⚡ Quick Commands

```bash
# Run all FTS models
dbt run --select tag:fts

# Run only KPI dashboard
dbt run --select vw_fts_maintenance_efficiency_kpi

# Run equipment analysis
dbt run --select vw_fts_equipment_reliability_analysis

# Run all except data quality
dbt run --select tag:fts,tag:analytics

# Check data quality only
dbt run --select tag:data_quality

# Compile without running
dbt compile --select tag:fts
```

---

## 📊 Key Metrics by View

### Maintenance Efficiency KPI
- ✅ Completion Rate %
- ❌ Cancellation Rate %
- ⏱️ Average Downtime Hours
- 💰 Cost per Equipment
- 💯 Overall Efficiency Score (0-100)
- 🎯 Best/Worst Maintenance Type

### Equipment Reliability Analysis
- ⚠️ Risk Level (Critical/High/Medium/Low)
- 📊 Average Failure Rate
- 💰 Total Maintenance Cost
- ⏱️ Total Downtime Hours
- 📈 Proactive Maintenance %
- 💯 Equipment Health Score (0-100)
- 🔢 Maintenance Priority (1-5)

### Maintenance Type Performance
- ✅ Completion Rate % by Type
- 💰 Average Cost by Type
- ⏱️ Average Downtime by Type
- 📉 Failure Rate Impact
- 💯 Effectiveness Score (0-100)
- 💵 ROI Indicator

### Technician Productivity
- 📊 Workload vs Average
- ✅ Completion Rate %
- 💰 Cost per Job
- ⏱️ Downtime per Job
- 📈 Proactive Work %
- 💯 Productivity Score (0-100)
- 🏆 Performance Tier

### Data Quality
- ✅ Completeness Score (0-100)
- 🔍 Duplicate Count
- ⚠️ Validation Issues
- 📅 Days Since Latest Log
- 💯 Overall Quality Score (0-100)

---

## 🏗️ Project Structure

```
models/fts/
├── _fts__sources.yml                          # Source definitions
├── schema.yml                                 # Model documentation
├── vw_fts_maintenance_efficiency_kpi.sql      # Ops dashboard
├── vw_fts_equipment_reliability_analysis.sql  # Equipment tracking
├── vw_fts_maintenance_type_performance.sql    # Strategy comparison
├── vw_fts_technician_productivity.sql         # Workforce analytics
└── vw_fts_data_quality.sql                    # Data monitoring
```

---

## 🎨 Configuration Snippets

### dbt_project.yml
```yaml
    fts:
      +tags: ['fts', 'energy']
      +schema: industries_energy
      +materialized: view
```

### Variables
```yaml
  fts_source_database: 'HOL_DATABASE'
  fts_source_schema: 'INDUSTRIES_ENERGY'
  fts_source_table: 'FTS_RECORDS'
```

---

## 🔗 Source Configuration

**Database:** `HOL_DATABASE`  
**Schema:** `INDUSTRIES_ENERGY`  
**Table:** `FTS_RECORDS`  
**Connector:** Fivetran Industries

All views reference: `{{ source('fts', 'fts_records') }}`

---

## 🎯 Tag Strategy

| Tag | Models | Use Case |
|-----|--------|----------|
| `fts` | All 5 | Run entire FTS suite |
| `energy` | All 5 | Industry-specific runs |
| `analytics` | 4 models | Exclude data quality |
| `data_quality` | 1 model | Monitoring only |
| `maintenance` | 2 models | Maintenance focus |
| `reliability` | 1 model | Equipment focus |
| `technician` | 1 model | Workforce focus |

---

## 🔧 Common Use Cases

### Find High-Risk Equipment
```sql
SELECT * FROM industries_energy.vw_fts_equipment_reliability_analysis
WHERE risk_level IN ('Critical Risk', 'High Risk')
ORDER BY maintenance_priority DESC, equipment_health_score ASC
LIMIT 10;
```

### Identify Top Technicians
```sql
SELECT * FROM industries_energy.vw_fts_technician_productivity
WHERE performance_tier = 'Top Performer'
ORDER BY productivity_score DESC;
```

### Best Maintenance Strategy
```sql
SELECT * FROM industries_energy.vw_fts_maintenance_type_performance
ORDER BY effectiveness_score DESC, avg_cost ASC
LIMIT 1;
```

### Check Data Quality
```sql
SELECT 
  overall_data_quality_score,
  data_quality_status,
  recommended_action
FROM industries_energy.vw_fts_data_quality;
```

---

## 🎓 Score Interpretation

All analytical views include health/performance scores (0-100):

| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Excellent | Maintain approach |
| 60-79 | Good | Minor improvements |
| 40-59 | Fair | Needs attention |
| 0-39 | Poor | Immediate action |

---

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Source not found" | Verify `_fts__sources.yml` database/schema names |
| "Column not found" | Check column names match exactly (case-sensitive) |
| Empty views | Verify source table has data |
| DATE_TRUNC errors | Ensure `log_date` is converted with `TO_DATE()` |
| Slow queries | Consider `+materialized: table` for performance |

---

## 💡 Business Insights

**From Your 750 Records:**

**Maintenance Mix:**
- Balanced across 5 types (136-162 each)
- Opportunity to increase Predictive (lowest at 136)

**Performance:**
- 20% completion rate (149 completed) - major improvement needed
- 22% cancellation rate - investigate causes
- 19% delay rate - address scheduling

**Equipment:**
- 49% average failure rate - moderate risk
- High variability (0-100%) suggests mixed fleet health

**Costs:**
- $551 average per activity
- Wide range ($100-$999) - standardization opportunity

**Efficiency:**
- 5.47 hours avg downtime - room for optimization
- 3 hours saved per log via AI - good automation benefit

---

## 📁 Files

- [FTS_IMPLEMENTATION_SUMMARY.md](computer:///mnt/user-data/outputs/FTS_IMPLEMENTATION_SUMMARY.md) - Detailed analysis
- [fts_dbt_models.zip](computer:///mnt/user-data/outputs/fts_dbt_models.zip) - All model files

---

## ⏱️ Implementation Timeline

- **5 min:** Extract and copy files
- **2 min:** Update dbt_project.yml
- **3 min:** Compile and validate
- **10 min:** Run models
- **15 min:** Review outputs
- **30 min:** Connect to BI tool

**Total:** ~1 hour from files to dashboards

---

## ✅ Success Checklist

- [ ] All 5 views compile without errors
- [ ] Views return data (not empty)
- [ ] Health scores calculate correctly
- [ ] Recommendations appear in views
- [ ] Data is recent (< 7 days old)
- [ ] Views accessible in BI tool
- [ ] Metrics validated with business

---

**Pro Tip:** Start with `vw_fts_data_quality` to validate your data foundation before analyzing operational metrics!
