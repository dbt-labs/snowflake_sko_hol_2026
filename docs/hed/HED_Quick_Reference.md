# HED Industry Models - Quick Reference

## 📋 dbt_project.yml Updates Required

### Add to Models Section:
```yaml
models:
  dbt_industries_views:
    cds:
      +tags: ['cds', 'healthcare']
      +schema: industries_healthcare
      +materialized: view
    
    # HED Higher Education Models (NEW)
    hed:
      +tags: ['hed', 'education']
      +schema: industries_education
      +materialized: view
```

### Add to Vars Section:
```yaml
vars:
  # CDS Healthcare configuration
  cds_source_database: 'HOL_DATABASE'
  cds_source_schema: 'INDUSTRIES_HEALTHCARE'
  cds_source_table: 'CDS_RECORDS'
  
  # HED Higher Education configuration (NEW)
  hed_source_database: 'HOL_DATABASE'
  hed_source_schema: 'INDUSTRIES_HIGHER_EDUCATION'
  hed_source_table: 'HED_RECORDS'
```

---

## 📊 5 Views Created

| View Name | Purpose | Key Features |
|-----------|---------|--------------|
| **vw_hed_student_success_kpi** | Executive KPI dashboard | Single-row summary, all key metrics |
| **vw_hed_retention_risk_analysis** | At-risk student identification | Multi-dimensional risk scoring, recommended actions |
| **vw_hed_program_performance** | Program comparison by major | Rankings, health scores, quartile classification |
| **vw_hed_engagement_analytics** | LMS engagement patterns | Quadrant analysis, concern levels, timing recommendations |
| **vw_hed_data_quality** | Data health monitoring | Completeness, validity, freshness checks |

---

## 🚀 Quick Install

```bash
# 1. Copy models to your project
cp -r hed/ models/

# 2. Update dbt_project.yml (see above)

# 3. Test
dbt compile --select hed
dbt run --select hed
```

---

## 🎯 Key Business Value

### Retention Risk View
- **Filters to at-risk students only** (AT_RISK_FLAG = TRUE)
- **Ordered by urgency**: Critical → High → Moderate
- **Includes recommended actions**: Specific next steps for each student
- **Multi-dimensional scoring**: GPA, engagement, login recency, completion rate

### Program Performance View
- **Program health score**: Composite metric (0-100)
- **Quartile rankings**: Top/Above Avg/Below Avg/Needs Improvement
- **Side-by-side comparison**: All majors in single view
- **Resource allocation insights**: Advisor ratios, intervention frequency

### Engagement Analytics View
- **Engagement quadrants**: 
  - High Engagement/High Performance (celebrate)
  - High Engagement/Low Performance (academic support)
  - Low Engagement/High Performance (risk of disengagement)
  - Low Engagement/Low Performance (critical intervention)
- **Login recency tracking**: Days since last login with risk levels
- **Participation patterns**: Course views, assignments, discussions

---

## 📈 Sample Queries

### Daily Morning Check
```sql
-- Data quality health
SELECT * FROM VW_HED_DATA_QUALITY;

-- Critical at-risk students
SELECT * FROM VW_HED_RETENTION_RISK_ANALYSIS
WHERE OVERALL_RISK_ASSESSMENT = 'Critical - Immediate Action Required';
```

### Weekly Executive Report
```sql
-- Institution KPIs
SELECT * FROM VW_HED_STUDENT_SUCCESS_KPI;

-- Top/bottom programs
SELECT * FROM VW_HED_PROGRAM_PERFORMANCE
ORDER BY PROGRAM_HEALTH_SCORE DESC;
```

### Advisor Dashboard
```sql
-- My at-risk students
SELECT * FROM VW_HED_RETENTION_RISK_ANALYSIS
WHERE ADVISOR_ID = 'ADV_XXXX'
ORDER BY OVERALL_RISK_ASSESSMENT;

-- Low engagement alerts
SELECT * FROM VW_HED_ENGAGEMENT_ANALYTICS
WHERE DAYS_SINCE_LAST_LOGIN > 7
  AND ENGAGEMENT_SCORE < 40;
```

---

## 🏷️ Tag-Based Execution

```bash
# All HED models
dbt run --select tag:hed

# Only analytics (exclude data quality)
dbt run --select tag:hed,tag:analytics

# Data quality only
dbt run --select tag:data_quality

# Executive views across all industries
dbt run --select tag:executive
```

---

## ✅ Files Delivered

| File | Purpose |
|------|---------|
| `_hed__sources.yml` | Source table definition |
| `schema.yml` | Model documentation |
| `README.md` | Comprehensive documentation |
| `vw_hed_student_success_kpi.sql` | Executive KPI view |
| `vw_hed_retention_risk_analysis.sql` | Retention risk view |
| `vw_hed_program_performance.sql` | Program comparison view |
| `vw_hed_engagement_analytics.sql` | Engagement analysis view |
| `vw_hed_data_quality.sql` | Data quality monitor view |

---

## 🎓 Dataset Overview

- **Source**: `HOL_DATABASE.INDUSTRIES_HIGHER_EDUCATION.HED_RECORDS`
- **Records**: 750 students
- **Columns**: 22 fields (academic, engagement, financial, intervention data)
- **At-Risk**: 257 students (34.3%)
- **Data Quality**: 100% complete (no nulls)
- **Top Majors**: PHIL, BUSN, ANTH, THEA, NURS

---

## 🔗 Schema Output

All views will be created in: `HOL_DATABASE.INDUSTRIES_EDUCATION`

You can customize this by changing the `+schema` value in `dbt_project.yml`:
```yaml
hed:
  +schema: your_custom_schema_name
```

---

**Ready to Deploy!** All files are in the `hed/` folder and ready to copy to your dbt project.
