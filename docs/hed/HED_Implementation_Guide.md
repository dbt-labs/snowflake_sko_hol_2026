# Higher Education (HED) Industry Models - Implementation Guide

## 📊 Dataset Analysis Summary

**Source**: `HOL_DATABASE.INDUSTRIES_HIGHER_EDUCATION.HED_RECORDS`

**Records**: 750 student records
**Columns**: 22 fields covering academic, engagement, financial, and intervention data

**Key Findings**:
- **At-Risk Students**: 257 (34.3%)
- **GPA Range**: 1.01 - 4.00
- **Engagement Score Range**: 15.0 - 98.0
- **Financial Aid Coverage**: ~66% of students receive aid
- **Data Quality**: 100% complete (no null values detected)

**Academic Standing Distribution**:
- Satisfactory Progress: 90 students
- Various honors/warnings distributed across other 660 students
- 12 distinct academic standing categories

**Top Majors**: PHIL (36), BUSN (36), ANTH (34), THEA (32), NURS (32)

---

## 🎯 Proposed dbt Views

Based on the HED dataset analysis, I've created **5 intelligent dbt views**:

### 1. **vw_hed_student_success_kpi**
- **Purpose**: Executive dashboard with institution-wide KPIs
- **Metrics**: Enrollment, GPA, completion rates, engagement, financial aid, interventions
- **Tags**: `['hed', 'analytics', 'kpi', 'executive']`
- **Use Case**: Board presentations, executive reporting, benchmark tracking

### 2. **vw_hed_retention_risk_analysis**
- **Purpose**: Early warning system for at-risk students
- **Metrics**: Multi-dimensional risk scoring (GPA, engagement, completion, login recency)
- **Tags**: `['hed', 'analytics', 'retention', 'risk']`
- **Use Case**: Advisor dashboards, proactive student outreach, intervention planning
- **Special Feature**: Filtered to at-risk students only, ordered by urgency with recommended actions

### 3. **vw_hed_program_performance**
- **Purpose**: Academic program comparison and assessment by major
- **Metrics**: Performance by major including rankings and program health scores
- **Tags**: `['hed', 'analytics', 'program', 'segmentation']`
- **Use Case**: Program review, resource allocation, curriculum improvement

### 4. **vw_hed_engagement_analytics**
- **Purpose**: Student LMS engagement pattern analysis
- **Metrics**: Login behavior, course views, assignments, discussion participation
- **Tags**: `['hed', 'analytics', 'engagement', 'trends']`
- **Use Case**: Identify disengaged students, measure online learning effectiveness
- **Special Feature**: Engagement vs. Performance quadrant analysis

### 5. **vw_hed_data_quality**
- **Purpose**: Data quality monitoring and health checks
- **Metrics**: Completeness, validity, uniqueness, freshness, anomaly detection
- **Tags**: `['hed', 'data_quality', 'monitoring']`
- **Use Case**: Daily monitoring, integration health, data governance

---

## 📋 Required dbt_project.yml Updates

Add the following sections to your `dbt_project.yml`:

```yaml
models:
  dbt_industries_views:
    # ... existing CDS models ...
    
    # HED Higher Education Models (NEW)
    hed:
      +tags: ['hed', 'education']
      +schema: industries_education
      +materialized: view

# Source configuration variables
vars:
  # ... existing CDS variables ...
  
  # Source configuration for HED Higher Education (NEW)
  hed_source_database: 'HOL_DATABASE'
  hed_source_schema: 'INDUSTRIES_HIGHER_EDUCATION'
  hed_source_table: 'HED_RECORDS'
```

### Complete Example Section

```yaml
# Model configurations
models:
  dbt_industries_views:
    # CDS Healthcare Models (EXISTING)
    cds:
      +tags: ['cds', 'healthcare']
      +schema: industries_healthcare
      +materialized: view
    
    # HED Higher Education Models (NEW)
    hed:
      +tags: ['hed', 'education']
      +schema: industries_education
      +materialized: view

# Source configuration
vars:
  # Source configuration for CDS Healthcare (EXISTING)
  cds_source_database: 'HOL_DATABASE'
  cds_source_schema: 'INDUSTRIES_HEALTHCARE'
  cds_source_table: 'CDS_RECORDS'
  
  # Source configuration for HED Higher Education (NEW)
  hed_source_database: 'HOL_DATABASE'
  hed_source_schema: 'INDUSTRIES_HIGHER_EDUCATION'
  hed_source_table: 'HED_RECORDS'
```

---

## 📁 Project Structure After Implementation

```
dbt_industries_views/
├── dbt_project.yml              # Updated with HED configuration
├── profiles.yml
├── packages.yml
├── .gitignore
├── README.md
├── models/
│   ├── cds/                     # Healthcare (EXISTING)
│   │   ├── _cds__sources.yml
│   │   ├── schema.yml
│   │   └── [5 CDS views]
│   ├── hed/                     # Higher Education (NEW)
│   │   ├── _hed__sources.yml
│   │   ├── schema.yml
│   │   ├── README.md
│   │   ├── vw_hed_student_success_kpi.sql
│   │   ├── vw_hed_retention_risk_analysis.sql
│   │   ├── vw_hed_program_performance.sql
│   │   ├── vw_hed_engagement_analytics.sql
│   │   └── vw_hed_data_quality.sql
│   └── [future industries]/
└── macros/
    └── generate_schema_name.sql
```

---

## 🚀 Installation Steps

### Step 1: Copy Model Files
```bash
# Navigate to your dbt project
cd dbt_industries_views/

# Copy HED models to your models directory
cp -r /path/to/hed/ models/
```

### Step 2: Update dbt_project.yml
Add the HED configuration sections shown above to your `dbt_project.yml` file.

### Step 3: Validate Configuration
```bash
# Test that dbt can find the new models
dbt ls --select hed

# Expected output:
# dbt_industries_views.vw_hed_student_success_kpi
# dbt_industries_views.vw_hed_retention_risk_analysis
# dbt_industries_views.vw_hed_program_performance
# dbt_industries_views.vw_hed_engagement_analytics
# dbt_industries_views.vw_hed_data_quality
```

### Step 4: Compile and Test
```bash
# Compile models to check for syntax errors
dbt compile --select hed

# Run the models
dbt run --select hed

# Generate documentation
dbt docs generate
```

### Step 5: Verify in Snowflake
```sql
-- Check that views were created in the correct schema
SHOW VIEWS IN SCHEMA HOL_DATABASE.INDUSTRIES_EDUCATION;

-- Test a view
SELECT * FROM HOL_DATABASE.INDUSTRIES_EDUCATION.VW_HED_STUDENT_SUCCESS_KPI;
```

---

## 🏷️ Using Tags for Selective Execution

The HED models include comprehensive tags for flexible execution:

```bash
# Run all HED models
dbt run --select tag:hed

# Run only analytics views (excludes data quality)
dbt run --select tag:hed,tag:analytics

# Run only data quality checks
dbt run --select tag:data_quality

# Run executive KPI views across all industries
dbt run --select tag:executive

# Run all education-related models
dbt run --select tag:education

# Run specific retention/risk models
dbt run --select tag:retention
```

---

## 📊 View Details & Business Value

### Executive KPI Dashboard
- **Single-row summary** of all key metrics
- Perfect for embedding in executive dashboards
- Tracks institutional effectiveness metrics
- Monitors financial aid utilization

### Retention Risk Analysis
- **Filtered to at-risk students only** (AT_RISK_FLAG = TRUE)
- Multi-dimensional risk scoring
- Actionable recommendations included in view
- Ordered by urgency (Critical → High → Moderate)
- Advisor-ready with specific next steps

### Program Performance
- **Compare all majors side-by-side**
- Program health score (composite metric)
- Rankings for GPA, completion, retention
- Quartile classification (Top/Above Avg/Below Avg/Needs Improvement)
- Resource allocation insights

### Engagement Analytics
- **Engagement vs. Performance quadrant analysis**
- Identifies four student types:
  - High Engagement/High Performance (successful)
  - High Engagement/Low Performance (needs academic support)
  - Low Engagement/High Performance (natural ability, risk of boredom)
  - Low Engagement/Low Performance (critical intervention needed)
- Login recency tracking
- Evidence-based intervention timing

### Data Quality Monitor
- **Single-row health check summary**
- Composite quality score (0-100)
- Four dimensions: Completeness, Validity, Uniqueness, Freshness
- Anomaly detection (inconsistent data patterns)
- Perfect for daily monitoring and SLA tracking

---

## 🎯 Recommended Usage Patterns

### Daily Operations
```sql
-- Morning data quality check
SELECT * FROM VW_HED_DATA_QUALITY;

-- Review critical at-risk students
SELECT * FROM VW_HED_RETENTION_RISK_ANALYSIS
WHERE OVERALL_RISK_ASSESSMENT = 'Critical - Immediate Action Required';

-- Check engagement concerns
SELECT * FROM VW_HED_ENGAGEMENT_ANALYTICS
WHERE ENGAGEMENT_CONCERN_LEVEL IN ('Immediate Concern - Student Dropout Risk', 'High Concern - Critically Disengaged');
```

### Weekly Reporting
```sql
-- Executive KPI summary
SELECT * FROM VW_HED_STUDENT_SUCCESS_KPI;

-- Program performance comparison
SELECT * FROM VW_HED_PROGRAM_PERFORMANCE
ORDER BY PROGRAM_HEALTH_SCORE DESC;
```

### Advisor Dashboards
```sql
-- At-risk students for specific advisor
SELECT * FROM VW_HED_RETENTION_RISK_ANALYSIS
WHERE ADVISOR_ID = 'ADV_1131'
ORDER BY OVERALL_RISK_ASSESSMENT;

-- Low engagement students needing outreach
SELECT * FROM VW_HED_ENGAGEMENT_ANALYTICS
WHERE ENGAGEMENT_CONCERN_LEVEL != 'No Immediate Concern'
  AND MAJOR_CODE IN ('BUSN', 'NURS', 'ENGR');
```

---

## 🔧 Customization Options

### Adjusting Risk Thresholds
Edit risk level definitions in `vw_hed_retention_risk_analysis.sql`:
```sql
-- Current GPA thresholds (lines ~40-45)
case
  when current_gpa < 2.0 then 'Critical'   -- Adjust these values
  when current_gpa < 2.5 then 'High'
  when current_gpa < 3.0 then 'Moderate'
  else 'Low'
end as gpa_risk_level
```

### Changing Schema Names
Update in `dbt_project.yml`:
```yaml
hed:
  +schema: your_custom_schema_name  # Change from industries_education
```

### Adding Additional Metrics
All views use CTEs for easy extension:
```sql
-- In vw_hed_student_success_kpi.sql, add to kpi_summary CTE:
, your_new_metric as sum(your_column) as total_your_metric
```

---

## 📈 Performance Considerations

### Current Configuration
- All models use **view materialization** (query-on-demand)
- Suitable for datasets up to ~1M records
- No additional storage cost

### Optimization for Large Datasets
If you have >1M records, consider:

```yaml
# In dbt_project.yml
hed:
  vw_hed_student_success_kpi:
    +materialized: table
    +post-hook: "CREATE INDEX IF NOT EXISTS idx_student_id ON {{ this }} (student_id)"
```

Or use incremental models:
```yaml
hed:
  vw_hed_retention_risk_analysis:
    +materialized: incremental
    +unique_key: student_id
    +incremental_strategy: merge
```

---

## ✅ Validation Checklist

After implementation, verify:

- [ ] All 5 HED views created in `INDUSTRIES_EDUCATION` schema
- [ ] `dbt_project.yml` updated with HED configuration
- [ ] `dbt compile --select hed` runs without errors
- [ ] `dbt run --select hed` completes successfully
- [ ] Views return expected data when queried
- [ ] Data quality view shows >85 composite quality score
- [ ] Documentation generated with `dbt docs generate`
- [ ] Source connection working (no permission errors)

---

## 🎓 Next Steps

1. **Review the views** in Snowflake to understand the data
2. **Build dashboards** using the KPI and program performance views
3. **Set up alerts** based on retention risk and engagement concerns
4. **Train advisors** on using the retention risk view for student outreach
5. **Schedule regular runs** (daily for data quality, weekly for analytics)
6. **Customize thresholds** based on your institution's standards

---

## 📞 Support

- **dbt Questions**: [dbt Docs](https://docs.getdbt.com/)
- **Fivetran Support**: Contact your Fivetran representative
- **Model Logic**: Review SQL comments and schema.yml documentation

---

**Implementation Date**: 2025-11-04
**Version**: 1.0.0
**Industry**: Higher Education (HED)
**Target Warehouse**: Snowflake
**dbt Version Required**: ≥1.0.0
