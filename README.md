# dbt Industries Views

A multi-industry dbt project designed for flexible, industry-specific analytics with Fivetran integration. This project supports multiple industry verticals with independent deployment and selective execution capabilities.

## 🎯 Project Overview

This dbt project creates analytical views from industry-specific datasets synced by Fivetran. The modular structure allows you to:

- **Add multiple industries** to the same project (Healthcare, Agriculture, Meteorology, etc.)
- **Deploy selectively** by industry using tags or folder paths
- **Share common infrastructure** while maintaining industry-specific logic
- **Scale easily** by adding new industry folders as needed

### Current Industries

#### Healthcare (CDS)
**Source:** PostgreSQL `industries` database → `CDS_RECORDS` table  
**Schema:** `INDUSTRIES_HEALTHCARE`  
**Views:** 5 analytical views covering patient outcomes, treatment effectiveness, clinical trials, data quality, and high-risk alerts

*Future industries (AGR, MET, etc.) will follow the same pattern.*

---

## 📁 Project Structure

```
dbt_industries_views/
├── dbt_project.yml              # Project configuration with industry-specific settings
├── profiles.yml                 # Snowflake connection template
├── packages.yml                 # dbt dependencies
├── .gitignore                   # Git exclusions
├── README.md                    # This file
├── models/
│   ├── cds/                     # Healthcare industry models
│   │   ├── _cds__sources.yml    # Source definitions
│   │   ├── schema.yml           # Model documentation
│   │   ├── vw_cds_patient_outcomes_kpi.sql
│   │   ├── vw_cds_treatment_effectiveness.sql
│   │   ├── vw_cds_clinical_trial_performance.sql
│   │   ├── vw_cds_data_quality.sql
│   │   └── vw_cds_high_risk_patients.sql
│   └── [future industries]/     # AGR, MET, etc.
└── macros/
    └── generate_schema_name.sql # Custom schema routing
```

---

## 🚀 Quick Start

### Prerequisites

- **dbt Core** 1.5+ installed ([installation guide](https://docs.getdbt.com/docs/core/installation))
- **Snowflake** account with appropriate permissions
- **Fivetran** connector syncing data to Snowflake
- **Git** for version control

### 1. Clone and Setup

```bash
# Clone the repository (or download the project files)
git clone <your-repo-url>
cd dbt_industries_views

# Install dbt dependencies
dbt deps
```

### 2. Configure Connection

Copy the `profiles.yml` template to `~/.dbt/profiles.yml` and update with your Snowflake credentials:

```yaml
industries_snowflake:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_SNOWFLAKE_ACCOUNT
      user: YOUR_USERNAME
      password: YOUR_PASSWORD
      role: YOUR_ROLE
      database: HOL_DATABASE
      warehouse: YOUR_WAREHOUSE
      schema: INDUSTRIES_HEALTHCARE
      threads: 4
```

### 3. Test Connection

```bash
# Verify connection
dbt debug

# Compile models to check for errors
dbt compile
```

### 4. Run Models

```bash
# Run all models
dbt run

# Run only CDS healthcare models
dbt run --select cds.*

# Run models with specific tag
dbt run --select tag:healthcare
```

---

## 📊 CDS Healthcare Views

### 1. vw_cds_patient_outcomes_kpi
**Purpose:** Executive KPI dashboard  
**Metrics:** Patient volume, outcome scores, treatment success, costs, satisfaction, risk indicators  
**Audience:** Healthcare executives, clinical leadership  
**Query Example:**
```sql
SELECT * FROM INDUSTRIES_HEALTHCARE.VW_CDS_PATIENT_OUTCOMES_KPI;
```

### 2. vw_cds_treatment_effectiveness
**Purpose:** Treatment outcome analysis by diagnosis and plan  
**Dimensions:** Diagnosis, Treatment Plan  
**Metrics:** Success rates, cost per outcome, adherence impact  
**Audience:** Clinical teams, treatment coordinators  
**Query Example:**
```sql
SELECT 
  DIAGNOSIS,
  TREATMENT_PLAN,
  success_rate,
  cost_per_successful_outcome
FROM INDUSTRIES_HEALTHCARE.VW_CDS_TREATMENT_EFFECTIVENESS
ORDER BY success_rate DESC;
```

### 3. vw_cds_clinical_trial_performance
**Purpose:** Clinical trial monitoring and effectiveness  
**Dimensions:** Trial Name, Trial Status  
**Metrics:** Enrollment, outcomes, safety, costs, publications  
**Audience:** Research teams, trial coordinators  
**Query Example:**
```sql
SELECT 
  TRIAL_NAME,
  TRIAL_STATUS,
  enrolled_patients,
  success_rate,
  efficiency_score
FROM INDUSTRIES_HEALTHCARE.VW_CDS_CLINICAL_TRIAL_PERFORMANCE
WHERE TRIAL_STATUS = 'Active';
```

### 4. vw_cds_data_quality
**Purpose:** Data completeness and integrity monitoring  
**Checks:** Null percentages, duplicates, validity, freshness  
**Audience:** Data engineers, quality assurance  
**Query Example:**
```sql
SELECT 
  overall_quality_score,
  quality_rating,
  completeness_score,
  validity_score,
  freshness_score
FROM INDUSTRIES_HEALTHCARE.VW_CDS_DATA_QUALITY;
```

### 5. vw_cds_high_risk_patients
**Purpose:** Patient alerts requiring immediate attention  
**Filters:** High readmission risk, critical vitals, poor outcomes  
**Audience:** Clinical teams, care coordinators  
**Query Example:**
```sql
SELECT 
  PATIENT_ID,
  priority_level,
  risk_score,
  alert_message,
  recommended_actions
FROM INDUSTRIES_HEALTHCARE.VW_CDS_HIGH_RISK_PATIENTS
WHERE priority_level IN ('Critical', 'High')
ORDER BY risk_score DESC;
```

---

## 🔄 Fivetran dbt Core Integration

### Setup Instructions

1. **Push to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial dbt industries project"
   git remote add origin <your-github-repo>
   git push -u origin main
   ```

2. **Configure in Fivetran:**
   - Navigate to **Transformations** → **dbt Core**
   - Connect your GitHub repository
   - Set **Target:** `prod`
   - Configure credentials in Fivetran UI (not in `profiles.yml`)

3. **Selective Execution:**
   Configure dbt command based on your needs:

   **Run all CDS models:**
   ```bash
   dbt run --select cds.*
   ```

   **Run only KPI views:**
   ```bash
   dbt run --select tag:kpi
   ```

   **Run specific model:**
   ```bash
   dbt run --select vw_cds_patient_outcomes_kpi
   ```

4. **Schedule:**
   - Fivetran runs dbt automatically after connector syncs
   - No additional scheduling needed

---

## 🏗️ Adding New Industries

To add a new industry (e.g., Agriculture):

### 1. Create Industry Folder

```bash
mkdir -p models/agr
```

### 2. Update dbt_project.yml

```yaml
models:
  dbt_industries_views:
    agr:
      +tags: ['agr', 'agriculture']
      +schema: industries_agriculture
      +materialized: view

vars:
  agr_source_database: 'HOL_DATABASE'
  agr_source_schema: 'INDUSTRIES_AGRICULTURE'
  agr_source_table: 'AGR_RECORDS'
```

### 3. Create Source Definition

Create `models/agr/_agr__sources.yml`:
```yaml
version: 2

sources:
  - name: industries_agriculture
    database: "{{ var('agr_source_database') }}"
    schema: "{{ var('agr_source_schema') }}"
    tables:
      - name: agr_records
        identifier: "{{ var('agr_source_table') }}"
```

### 4. Create Views

Add SQL files in `models/agr/`:
- `vw_agr_crop_yields_kpi.sql`
- `vw_agr_weather_impact.sql`
- etc.

### 5. Document Models

Create `models/agr/schema.yml` with model documentation.

### 6. Deploy

```bash
# Test locally
dbt run --select agr.*

# Push to GitHub
git add models/agr/
git commit -m "Add agriculture industry models"
git push

# Configure in Fivetran with: dbt run --select agr.*
```

---

## 🎨 Customization

### Modify Source Tables

Update variables in `dbt_project.yml`:

```yaml
vars:
  cds_source_database: 'YOUR_DATABASE'
  cds_source_schema: 'YOUR_SCHEMA'
  cds_source_table: 'YOUR_TABLE'
```

### Change Materialization

Update model config in SQL file:

```sql
{{
  config(
    materialized='table',  -- Change from 'view' to 'table'
    tags=['cds', 'healthcare', 'kpi']
  )
}}
```

### Add Custom Tags

Add tags for selective execution:

```sql
{{
  config(
    tags=['cds', 'healthcare', 'executive', 'weekly_report']
  )
}}
```

Then run: `dbt run --select tag:weekly_report`

---

## 🧪 Testing

```bash
# Compile all models
dbt compile

# Run all models
dbt run

# Test source data
dbt test --select source:*

# Test specific model
dbt test --select vw_cds_patient_outcomes_kpi

# Generate documentation
dbt docs generate
dbt docs serve  # Opens in browser
```

---

## 📋 Development Workflow

### Local Development

```bash
# Create feature branch
git checkout -b feature/new-industry-views

# Develop and test
dbt run --select <your_models>
dbt test

# Commit changes
git add .
git commit -m "Add new industry views"
git push origin feature/new-industry-views
```

### Deployment

1. Create Pull Request in GitHub
2. Review and merge to main branch
3. Fivetran automatically deploys on next connector sync

---

## 🔍 Monitoring

### Data Quality

Check data quality regularly:
```sql
SELECT * FROM INDUSTRIES_HEALTHCARE.VW_CDS_DATA_QUALITY;
```

### Fivetran Logs

Monitor in Fivetran UI:
- **Transformations** → **Logs** for dbt run history
- **Connectors** → **Logs** for sync status

### Alert Integration

Query high-risk patients for alerting:
```sql
SELECT 
  PATIENT_ID,
  priority_level,
  alert_message
FROM INDUSTRIES_HEALTHCARE.VW_CDS_HIGH_RISK_PATIENTS
WHERE priority_level = 'Critical';
```

---

## 🛠️ Troubleshooting

### Common Issues

**"Column not found" errors:**
- Verify column names match exactly (case-sensitive in Snowflake)
- Check source table with: `SHOW COLUMNS IN TABLE <table>`

**dbt compilation fails:**
- Check YAML syntax (use 2 spaces, no tabs)
- Validate with: `dbt compile`

**Views empty after creation:**
- Verify source table has data
- Check WHERE clause filters aren't too restrictive

**Fivetran transformation fails:**
- Review Fivetran logs for specific error
- Test locally first: `dbt run --select <model>`
- Verify credentials are configured in Fivetran

---

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Fivetran dbt Core Guide](https://fivetran.com/docs/transformations/dbt)
- [Snowflake Documentation](https://docs.snowflake.com/)

---

## 🤝 Contributing

To contribute new industries or views:

1. Follow the structure in `models/cds/` as a template
2. Document all models in `schema.yml`
3. Add tests for critical fields
4. Update this README with new industry documentation
5. Submit Pull Request with clear description

---

## 📄 License

[Add your license information here]

---

## ✨ Project Metadata

- **Project Name:** dbt_industries_views
- **Version:** 1.0.0
- **dbt Version:** 1.5+
- **Warehouse:** Snowflake
- **Connector:** Fivetran
- **Industries:** Healthcare (CDS) - *More to come*

---

**Questions or Issues?** [Create an issue in GitHub]
