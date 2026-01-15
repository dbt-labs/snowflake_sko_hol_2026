# Higher Education (HED) Analytics Setup Guide

A complete guide to deploying the Higher Education student retention and success analytics views using dbt, Fivetran, and Snowflake.

## 📋 Table of Contents

- [Overview](#-overview)
- [What You'll Get](#-what-youll-get)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Setup](#-detailed-setup)
- [HED Views Reference](#-hed-views-reference)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Advanced Configuration](#-advanced-configuration)

---

## 🎯 Overview

This package provides production-ready analytical views for Higher Education institutions focused on:

- **Student Retention Risk**: Early identification of at-risk students with recommended interventions
- **Academic Performance**: Program-level and institution-wide success metrics
- **Student Engagement**: LMS activity monitoring and engagement analytics
- **Data Quality**: Automated monitoring of data completeness and validity
- **Executive KPIs**: Single-pane dashboard view of institutional health

### Architecture

```
Fivetran → Snowflake (HED_RECORDS) → dbt (5 Analytical Views) → BI Tools / Census / Alerts
```

---

## 🎁 What You'll Get

### 5 Production-Ready Views

| View Name | Purpose | Primary Users |
|-----------|---------|---------------|
| `vw_hed_student_success_kpi` | Executive dashboard with institution-wide KPIs | Leadership, Executives |
| `vw_hed_retention_risk_analysis` | Student-level retention risk with interventions | Advisors, Success Teams |
| `vw_hed_program_performance` | Program/major performance benchmarking | Academic Deans, Department Heads |
| `vw_hed_engagement_analytics` | Student engagement patterns and concerns | Advisors, Instructional Designers |
| `vw_hed_data_quality` | Data completeness and validity monitoring | Data Engineers, Analysts |

### Schema

All views are created in the Snowflake schema: **`YOUR_SCHEMA_NAME`** (default: `INDUSTRIES_HIGHER_EDUCATION_HED`)

---

## ✅ Prerequisites

Before you begin, ensure you have:

### 1. Software Requirements
- **dbt Core** 1.5+ installed ([installation guide](https://docs.getdbt.com/docs/core/installation))
- **Git** for version control
- **Python** 3.8+ (for dbt)

### 2. Snowflake Requirements
- Active Snowflake account
- Role with permissions:
  - `CREATE SCHEMA` on target database
  - `CREATE VIEW` privileges
  - `SELECT` on source HED data tables
- Warehouse for compute resources

### 3. Source Data Requirements

You need a table in Snowflake with the following structure:

**Default Location:** `YOUR_DATABASE.YOUR_SOURCE_SCHEMA.YOUR_TABLE_NAME`

**Example:** `ANALYTICS_DB.RAW_STUDENT_DATA.HED_RECORDS`

**Required Columns:**
- `record_id` - Primary key
- `student_id` - Unique student identifier
- `enrollment_date` - Student enrollment date
- `academic_standing` - Academic status (e.g., "Good Standing", "Probation")
- `current_gpa` - Current GPA
- `credit_hours_attempted` / `credit_hours_earned` - Academic progress
- `major_code` - Academic major
- `advisor_id` - Academic advisor
- `financial_aid_amount` - Financial aid received
- `last_login_date` - Most recent LMS login
- `total_course_views` - Course material views
- `assignment_submissions` - Assignments submitted
- `discussion_posts` - Discussion forum posts
- `avg_assignment_score` - Average assignment score
- `course_completion_rate` - Course completion percentage
- `engagement_score` - Composite engagement metric (0-100)
- `at_risk_flag` - Boolean retention risk indicator
- `intervention_count` - Number of interventions received
- `plagiarism_incidents` - Academic integrity violations
- `writing_quality_score` - Writing assessment score
- `last_updated` - Data refresh timestamp

> **Note:** If your source table has different column names or location, see [Advanced Configuration](#-advanced-configuration).

---

## 🚀 Quick Start

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone <repository-url>
cd dbt_industries_views

# Install dbt dependencies
dbt deps
```

### Step 2: Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your Snowflake credentials
# Use your favorite text editor
nano .env
```

Update the following values in `.env`:

```bash
export DBT_SNOWFLAKE_ACCOUNT="your-account-identifier"
export DBT_SNOWFLAKE_USER="your_username"
export DBT_SNOWFLAKE_PASSWORD="your_password_or_token"
export DBT_SNOWFLAKE_ROLE="your_role"
export DBT_SNOWFLAKE_WAREHOUSE="your_warehouse"
export DBT_SNOWFLAKE_DATABASE="your_database"
```

### Step 3: Configure dbt Profile

Create or update `~/.dbt/profiles.yml`:

```yaml
industries_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('DBT_SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('DBT_SNOWFLAKE_USER') }}"
      password: "{{ env_var('DBT_SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('DBT_SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('DBT_SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('DBT_SNOWFLAKE_DATABASE') }}"
      schema: YOUR_SCHEMA_NAME
      threads: 4
      client_session_keep_alive: False
```

### Step 4: Load Environment and Test Connection

```bash
# Load environment variables
source .env

# Test dbt connection
dbt debug

# Expected output: "All checks passed!"
```

### Step 5: Deploy HED Views

```bash
# Build only HED views
dbt build --select hed.*

# Verify views were created
dbt list --select hed.*
```

### Step 6: Verify in Snowflake

```sql
-- Check that views were created
SHOW VIEWS IN SCHEMA YOUR_SCHEMA_NAME;

-- Query the executive KPI view
SELECT * FROM YOUR_SCHEMA_NAME.VW_HED_STUDENT_SUCCESS_KPI;

-- Check for at-risk students
SELECT
  student_id,
  overall_risk_assessment,
  recommended_action
FROM YOUR_SCHEMA_NAME.VW_HED_RETENTION_RISK_ANALYSIS
LIMIT 10;
```

---

## 🔧 Detailed Setup

### Environment Configuration

#### Option 1: Using Environment Variables (Recommended)

1. Create `.env` file from template:
   ```bash
   cp .env.example .env
   ```

2. Update with your credentials (see Step 2 in Quick Start)

3. Load before running dbt:
   ```bash
   source .env
   dbt run --select hed.*
   ```

#### Option 2: Direct Profile Configuration

Edit `~/.dbt/profiles.yml` with hardcoded values:

```yaml
industries_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: abc12345.us-east-1  # Your Snowflake account locator
      user: your_username
      password: your_password
      role: ANALYST
      warehouse: COMPUTE_WH
      database: YOUR_DATABASE
      schema: YOUR_SCHEMA_NAME
      threads: 4
```

> **Security Note:** Never commit `profiles.yml` or `.env` to version control.

### Verification Steps

#### 1. Test dbt Connection

```bash
dbt debug
```

Expected output:
```
Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
 - git [OK found]

Connection:
  account: ✓
  user: ✓
  database: ✓
  schema: ✓
  warehouse: ✓
  role: ✓

All checks passed!
```

#### 2. Compile Models

```bash
# Compile HED models to check for SQL errors
dbt compile --select hed.*
```

#### 3. Run Models

```bash
# Create all HED views
dbt run --select hed.*

# Expected output:
# Running with dbt=1.5.0
# Found 5 models, 0 tests, 0 snapshots, 0 analyses, 0 macros, 0 operations, 0 seed files
#
# 14:32:15 | Concurrency: 4 threads (target='dev')
# 14:32:15 |
# 14:32:15 | 1 of 5 START sql view model YOUR_SCHEMA_NAME.vw_hed_student_success_kpi
# 14:32:15 | 2 of 5 START sql view model YOUR_SCHEMA_NAME.vw_hed_retention_risk_analysis
# 14:32:16 | 1 of 5 OK created sql view model YOUR_SCHEMA_NAME.vw_hed_student_success_kpi
# ...
# 14:32:18 | Completed successfully
```

#### 4. Generate Documentation

```bash
# Generate documentation site
dbt docs generate --select hed.*

# Serve documentation locally
dbt docs serve
```

Opens a browser with interactive documentation of all HED models, columns, and lineage.

---

## 📊 HED Views Reference

### 1. vw_hed_student_success_kpi

**Purpose:** Executive-level KPI dashboard
**Granularity:** Institution-wide summary (single row)
**Refresh:** Run on-demand or scheduled

**Key Metrics:**
- Total students and at-risk percentage
- Average GPA and completion rates
- Engagement scores and course activity
- Financial aid coverage
- Intervention statistics
- Data freshness timestamp

**Query Example:**
```sql
SELECT
  total_students,
  at_risk_students,
  at_risk_percentage,
  avg_gpa,
  avg_engagement_score,
  credit_hour_success_rate,
  financial_aid_coverage_pct
FROM YOUR_SCHEMA_NAME.VW_HED_STUDENT_SUCCESS_KPI;
```

**Use Cases:**
- Executive dashboards
- Board presentations
- Institutional effectiveness reports
- Trend monitoring

---

### 2. vw_hed_retention_risk_analysis

**Purpose:** Student-level retention risk identification
**Granularity:** One row per at-risk student
**Filters:** Shows only students with `at_risk_flag = TRUE`

**Key Metrics:**
- GPA risk level (Critical/High/Moderate/Low)
- Completion risk level
- Engagement risk level
- Login recency risk
- Overall risk assessment
- Recommended actions

**Query Example:**
```sql
SELECT
  student_id,
  major_code,
  advisor_id,
  overall_risk_assessment,
  recommended_action,
  current_gpa,
  engagement_score,
  days_since_last_login
FROM YOUR_SCHEMA_NAME.VW_HED_RETENTION_RISK_ANALYSIS
WHERE overall_risk_assessment LIKE '%Critical%'
ORDER BY current_gpa ASC, engagement_score ASC;
```

**Use Cases:**
- Early alert systems
- Advisor intervention planning
- Student success outreach campaigns
- Census reverse ETL to Slack/email alerts

**Risk Levels:**
- **Critical Risk**: GPA < 2.0 OR completion rate < 60%
- **High Risk**: GPA < 2.5 OR completion rate < 70%
- **Moderate Risk**: GPA < 3.0 OR completion rate < 80%
- **Low Risk**: All other at-risk students

---

### 3. vw_hed_program_performance

**Purpose:** Program/major performance benchmarking
**Granularity:** One row per major
**Sort:** Ranked by program health score

**Key Metrics:**
- Enrollment and advisor ratios
- Average GPA and completion rates
- At-risk student percentages
- Engagement scores by program
- Financial aid coverage
- Program health score (composite 0-100)
- Performance quartile ranking

**Query Example:**
```sql
SELECT
  major_code,
  total_students,
  avg_gpa,
  at_risk_percentage,
  program_health_score,
  performance_category,
  overall_health_rank
FROM YOUR_SCHEMA_NAME.VW_HED_PROGRAM_PERFORMANCE
ORDER BY program_health_score DESC;
```

**Use Cases:**
- Department performance reviews
- Resource allocation decisions
- Program improvement initiatives
- Accreditation reporting

**Performance Categories:**
- **Top Performer**: Top 25% (Quartile 1)
- **Above Average**: Quartile 2
- **Below Average**: Quartile 3
- **Needs Attention**: Bottom 25% (Quartile 4)

---

### 4. vw_hed_engagement_analytics

**Purpose:** Student engagement pattern analysis
**Granularity:** One row per student
**Sort:** By engagement concern level (most urgent first)

**Key Metrics:**
- Login recency and activity patterns
- Course view behavior
- Assignment submission and performance
- Discussion participation
- Engagement score and level
- Engagement-performance quadrant classification
- Recommended engagement actions

**Query Example:**
```sql
SELECT
  student_id,
  major_code,
  engagement_level,
  days_since_last_login,
  engagement_score,
  engagement_performance_quadrant,
  recommended_engagement_action
FROM YOUR_SCHEMA_NAME.VW_HED_ENGAGEMENT_ANALYTICS
WHERE engagement_concern_level IN ('Critical', 'High')
ORDER BY engagement_score ASC;
```

**Use Cases:**
- LMS activity monitoring
- Course design effectiveness
- Student outreach prioritization
- Engagement intervention campaigns

**Engagement Levels:**
- **Highly Engaged**: Score ≥ 80
- **Moderately Engaged**: Score 60-79
- **Low Engagement**: Score 40-59
- **Disengaged**: Score < 40

**Quadrant Classifications:**
- **High Performing Engaged**: High GPA + High engagement
- **High Performing Disengaged**: High GPA + Low engagement
- **Struggling Engaged**: Low GPA + High engagement
- **Struggling Disengaged**: Low GPA + Low engagement

---

### 5. vw_hed_data_quality

**Purpose:** Data quality monitoring and validation
**Granularity:** Institution-wide summary (single row)
**Refresh:** Run before critical reporting

**Key Metrics:**
- Completeness score (0-100)
- Validity score (0-100)
- Uniqueness score (0-100)
- Freshness score (0-100)
- Composite quality score
- Overall quality status
- Hours since last data update

**Query Example:**
```sql
SELECT
  composite_quality_score,
  overall_quality_status,
  completeness_score,
  validity_score,
  freshness_score,
  hours_since_last_update,
  total_records,
  unique_students
FROM YOUR_SCHEMA_NAME.VW_HED_DATA_QUALITY;
```

**Use Cases:**
- Data pipeline monitoring
- ETL validation
- Quality assurance reporting
- Alerting on data issues

**Quality Status Ratings:**
- **Excellent**: Score ≥ 90
- **Good**: Score 75-89
- **Acceptable**: Score 60-74
- **Needs Improvement**: Score < 60

---

## 💡 Usage Examples

### Example 1: Daily At-Risk Student Report

```sql
-- Export list of critical-risk students for advisor outreach
SELECT
  student_id,
  major_code,
  advisor_id,
  current_gpa,
  engagement_score,
  days_since_last_login,
  recommended_action
FROM YOUR_SCHEMA_NAME.VW_HED_RETENTION_RISK_ANALYSIS
WHERE overall_risk_assessment LIKE '%Critical%'
ORDER BY current_gpa ASC;
```

**Use this query for:**
- Morning advisor briefings
- Census sync to Slack alerts
- Email campaign targeting
- Intervention tracking dashboards

---

### Example 2: Program Performance Dashboard

```sql
-- Compare programs across key metrics
SELECT
  major_code,
  total_students,
  avg_gpa,
  credit_success_rate,
  at_risk_percentage,
  avg_engagement_score,
  program_health_score,
  performance_category
FROM YOUR_SCHEMA_NAME.VW_HED_PROGRAM_PERFORMANCE
WHERE total_students >= 20  -- Focus on larger programs
ORDER BY program_health_score DESC;
```

**Use this query for:**
- Department chair meetings
- Academic affairs presentations
- Program review cycles
- Resource allocation planning

---

### Example 3: Engagement Intervention List

```sql
-- Identify disengaged students for LMS outreach
SELECT
  student_id,
  major_code,
  days_since_last_login,
  total_course_views,
  assignment_submissions,
  engagement_score,
  recommended_engagement_action
FROM YOUR_SCHEMA_NAME.VW_HED_ENGAGEMENT_ANALYTICS
WHERE engagement_level IN ('Disengaged', 'Low Engagement')
  AND at_risk_flag = TRUE
ORDER BY days_since_last_login DESC;
```

**Use this query for:**
- LMS re-engagement campaigns
- Student success coordinator workflows
- Course design feedback
- Early warning alerts

---

### Example 4: Executive KPI Monitoring

```sql
-- Weekly KPI tracking for leadership
SELECT
  total_students,
  at_risk_students,
  ROUND(at_risk_percentage, 1) as at_risk_pct,
  ROUND(avg_gpa, 2) as avg_gpa,
  ROUND(credit_hour_success_rate, 1) as credit_success_pct,
  ROUND(avg_engagement_score, 0) as avg_engagement,
  ROUND(financial_aid_coverage_pct, 1) as fin_aid_coverage_pct,
  last_data_refresh
FROM YOUR_SCHEMA_NAME.VW_HED_STUDENT_SUCCESS_KPI;
```

**Use this query for:**
- Executive dashboards (Tableau, Power BI, Sigma)
- Weekly leadership reports
- Board presentations
- Institutional effectiveness tracking

---

### Example 5: Data Quality Alerts

```sql
-- Check data quality before running reports
SELECT
  CASE
    WHEN composite_quality_score < 60 THEN 'ALERT: Data Quality Issues'
    WHEN hours_since_last_update > 48 THEN 'WARNING: Stale Data'
    ELSE 'OK: Data Quality Acceptable'
  END as status_message,
  composite_quality_score,
  overall_quality_status,
  hours_since_last_update,
  completeness_score,
  validity_score,
  freshness_score
FROM YOUR_SCHEMA_NAME.VW_HED_DATA_QUALITY;
```

**Use this query for:**
- Pre-report validation
- Data pipeline monitoring
- Automated quality alerts
- ETL health checks

---

## 🔥 Fivetran Integration

### Deploy with Fivetran Transformations (dbt Core)

#### 1. Push to GitHub

```bash
git add .
git commit -m "Deploy HED analytics views"
git push origin main
```

#### 2. Configure Fivetran Transformation

1. Navigate to **Fivetran → Transformations → dbt Core**
2. Click **Create Transformation**
3. Connect your GitHub repository
4. Set **Git branch:** `main`
5. Set **dbt commands:**
   ```bash
   dbt deps
   dbt build --select hed.*
   ```
6. Configure **Environment Variables** (or use Fivetran-managed credentials):
   - `DBT_SNOWFLAKE_ACCOUNT`
   - `DBT_SNOWFLAKE_USER`
   - `DBT_SNOWFLAKE_PASSWORD`
   - `DBT_SNOWFLAKE_ROLE`
   - `DBT_SNOWFLAKE_WAREHOUSE`
   - `DBT_SNOWFLAKE_DATABASE`

#### 3. Test and Schedule

1. Click **Test Transformation** to validate
2. Set **Schedule:**
   - **Run after connector sync:** Automatic (recommended)
   - **Or custom schedule:** Daily at 6 AM
3. Save and activate

#### 4. Monitor Logs

Check **Transformations → Logs** for:
- dbt run status
- View creation confirmation
- Error messages (if any)

---

## 🛠️ Troubleshooting

### Issue: "Database/Schema does not exist"

**Symptom:**
```
Database 'YOUR_DATABASE' does not exist or not authorized
```

**Solution:**
1. Verify database name in Snowflake:
   ```sql
   SHOW DATABASES;
   ```
2. Update `.env` or `dbt_project.yml` with correct database name
3. Ensure your role has access:
   ```sql
   GRANT USAGE ON DATABASE YOUR_DATABASE TO ROLE your_role;
   ```

---

### Issue: "Source table not found"

**Symptom:**
```
Object 'YOUR_DATABASE.YOUR_SOURCE_SCHEMA.YOUR_TABLE_NAME' does not exist
```

**Solution:**
1. Check table exists:
   ```sql
   SHOW TABLES IN SCHEMA YOUR_SOURCE_SCHEMA;
   ```
2. Verify table name and location in `models/hed/_hed__sources.yml`
3. Update `dbt_project.yml` variables if table is in different location:
   ```yaml
   vars:
     hed_source_database: 'YOUR_DATABASE'
     hed_source_schema: 'YOUR_SCHEMA'
     hed_source_table: 'YOUR_TABLE'
   ```

---

### Issue: "Column not found in source table"

**Symptom:**
```
SQL compilation error: column 'ENGAGEMENT_SCORE' does not exist
```

**Solution:**
1. Check source table columns:
   ```sql
   DESCRIBE TABLE YOUR_DATABASE.YOUR_SOURCE_SCHEMA.YOUR_TABLE_NAME;
   ```
2. Compare with required columns in [Prerequisites](#-prerequisites)
3. Options:
   - **Option A:** Add missing columns to source table
   - **Option B:** Modify HED views to handle missing columns (add default values or remove)

---

### Issue: "dbt debug fails"

**Symptom:**
```
Connection test failed
```

**Solution:**
1. Check environment variables are loaded:
   ```bash
   echo $DBT_SNOWFLAKE_ACCOUNT
   ```
2. Re-source `.env`:
   ```bash
   source .env
   ```
3. Verify credentials in Snowflake:
   ```sql
   -- Test login manually
   SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE();
   ```
4. Check `~/.dbt/profiles.yml` syntax (use 2 spaces, not tabs)

---

### Issue: "Views created but returning no data"

**Symptom:**
```sql
SELECT * FROM VW_HED_STUDENT_SUCCESS_KPI;
-- Returns: 0 rows
```

**Solution:**
1. Check source table has data:
   ```sql
   SELECT COUNT(*) FROM YOUR_DATABASE.YOUR_SOURCE_SCHEMA.YOUR_TABLE_NAME;
   ```
2. Check view SQL for restrictive filters
3. Verify `at_risk_flag` column has TRUE values (for retention risk view)
4. Check data types match expectations (especially dates)

---

### Issue: "Permission denied"

**Symptom:**
```
Insufficient privileges to operate on schema 'YOUR_SCHEMA_NAME'
```

**Solution:**
Grant necessary permissions:
```sql
-- Grant schema creation (if creating new schema)
GRANT CREATE SCHEMA ON DATABASE YOUR_DATABASE TO ROLE your_role;

-- Grant view creation in existing schema
GRANT CREATE VIEW ON SCHEMA YOUR_SCHEMA_NAME TO ROLE your_role;

-- Grant select on source table
GRANT SELECT ON ALL TABLES IN SCHEMA YOUR_SOURCE_SCHEMA TO ROLE your_role;
```

---

## 🎨 Advanced Configuration

### Customize Source Table Location

If your HED data is in a different location, update `dbt_project.yml`:

```yaml
vars:
  # Custom source configuration
  hed_source_database: 'PRODUCTION_DB'
  hed_source_schema: 'STUDENT_DATA'
  hed_source_table: 'STUDENT_RECORDS'
```

Then rebuild:
```bash
dbt run --select hed.* --full-refresh
```

---

### Change Materialization to Table

For better query performance on large datasets, materialize as tables instead of views:

Edit `dbt_project.yml`:

```yaml
models:
  dbt_industries_views:
    hed:
      +materialized: table  # Changed from 'view'
      +tags: ['hed', 'education']
      +schema: industries_higher_education_hed
```

Or configure per-model in the SQL file:

```sql
{{
  config(
    materialized='table',
    tags=['hed', 'analytics', 'retention']
  )
}}
```

Then rebuild:
```bash
dbt run --select hed.* --full-refresh
```

---

### Add Custom Tags for Selective Execution

Add tags to group models:

```yaml
models:
  dbt_industries_views:
    hed:
      +tags: ['hed', 'education', 'student_success', 'daily']
```

Then run by tag:
```bash
# Run only daily-tagged models
dbt run --select tag:daily

# Run only retention-related models
dbt run --select tag:retention
```

---

### Configure Incremental Refresh

For large datasets, configure incremental refresh (future enhancement):

```sql
{{
  config(
    materialized='incremental',
    unique_key='student_id',
    on_schema_change='sync_all_columns'
  )
}}

SELECT *
FROM {{ source('hed', 'hed_records') }}
{% if is_incremental() %}
WHERE last_updated > (SELECT MAX(last_updated) FROM {{ this }})
{% endif %}
```

---

### Deploy Multiple Environments

Create separate targets in `~/.dbt/profiles.yml`:

```yaml
industries_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('DBT_SNOWFLAKE_ACCOUNT') }}"
      database: YOUR_DEV_DATABASE
      schema: YOUR_SCHEMA_NAME_DEV
      # ... other settings

    prod:
      type: snowflake
      account: "{{ env_var('DBT_SNOWFLAKE_ACCOUNT') }}"
      database: YOUR_PROD_DATABASE
      schema: YOUR_SCHEMA_NAME
      # ... other settings
```

Then run against specific target:
```bash
# Run in dev
dbt run --select hed.* --target dev

# Run in prod
dbt run --select hed.* --target prod
```

---

## 📚 Additional Resources

- **[Main Project README](README.md)** - Full project documentation
- **[dbt Documentation](https://docs.getdbt.com/)** - dbt Core reference
- **[Fivetran dbt Core](https://fivetran.com/docs/transformations/dbt)** - Fivetran transformation guide
- **[Snowflake Documentation](https://docs.snowflake.com/)** - Snowflake reference

---

## 🤝 Support and Questions

### Getting Help

1. **Check Troubleshooting section above**
2. **Review dbt logs:** `logs/dbt.log`
3. **Test with `dbt debug` and `dbt compile`**
4. **Check Fivetran transformation logs** (if using Fivetran)

### Common Commands Reference

```bash
# Install dependencies
dbt deps

# Test connection
dbt debug

# Compile models (check for errors)
dbt compile --select hed.*

# Run HED models
dbt run --select hed.*

# Full rebuild
dbt run --select hed.* --full-refresh

# Generate documentation
dbt docs generate --select hed.*
dbt docs serve

# List all HED models
dbt list --select hed.*
```

---

## ✅ Deployment Checklist

Use this checklist to ensure successful deployment:

- [ ] Prerequisites met (dbt installed, Snowflake access, source data available)
- [ ] Repository cloned and `dbt deps` run successfully
- [ ] `.env` file created and credentials configured
- [ ] `~/.dbt/profiles.yml` configured with correct settings
- [ ] `dbt debug` passes all checks
- [ ] Source table exists and has required columns
- [ ] `dbt compile --select hed.*` runs without errors
- [ ] `dbt run --select hed.*` creates all 5 views successfully
- [ ] Views return data (not empty)
- [ ] Data quality checks pass acceptable thresholds
- [ ] Documentation generated (`dbt docs generate`)
- [ ] (Optional) Fivetran transformation configured and tested
- [ ] (Optional) BI tool connected to views
- [ ] (Optional) Census syncs configured for alerts

---

## 📄 License

[Add your license information here]

---

**Need help?** Open an issue or contact your data engineering team.

**Want to customize?** All SQL is in `models/hed/*.sql` - feel free to modify!

---

*Last Updated: January 2026*
*Version: 1.0*
*dbt Version: 1.5+*
*Warehouse: Snowflake*
