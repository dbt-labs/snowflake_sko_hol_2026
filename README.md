# dbt Industries Views

A Snowflake dbt project for industry-specific analytical views. The current implementation focuses on **Higher Education (HED)** student success, retention risk, engagement, program performance, data quality, and semantic-layer access.

This project is structured so additional industries can be added later under their own `models/<industry>/` folders while sharing the same dbt project configuration, dependency management, and deployment patterns.

---

## Project Overview

### Current Industry: Higher Education (HED)

- **Source:** Snowflake table configured through dbt vars
- **Default source:** `RAW.INDUSTRIES_HIGHER_EDUCATION.HED_RECORDS`
- **dbt source:** `source('hed', 'hed_records')`
- **Target schema config:** `industries_higher_education`
- **Primary materialization:** views

The HED models provide analytics for:

- Executive student-success KPIs
- Student-level retention risk analysis
- Program/major performance benchmarking
- LMS and academic engagement analytics
- Data quality monitoring
- Semantic-layer exploration over engagement and at-risk-student data

---

## Project Structure

```text
dbt_industries_views/
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
├── profiles.yml                 # Local profile example; do not commit real credentials
├── HED_SETUP_GUIDE.md           # Detailed HED setup and deployment guide
├── macros/
│   └── generate_schema_name.sql
├── seeds/
│   └── hed_records.csv
└── models/
    └── hed/
        ├── _hed__sources.yml
        ├── staging/
        │   ├── _staging__schema.yml
        │   └── stg_hed__students.sql
        ├── intermediate/
        │   ├── _intermediate__schema.yml
        │   ├── int_hed__engagement_categories.sql
        │   └── int_hed__risk_levels.sql
        ├── data_quality/
        │   ├── _data_quality__schema.yml
        │   ├── dq_hed__completeness.sql
        │   ├── dq_hed__duplicates.sql
        │   ├── dq_hed__freshness.sql
        │   └── dq_hed__validity.sql
        ├── marts/
        │   ├── schema.yml
        │   ├── vw_hed_student_success_kpi.sql
        │   ├── vw_hed_retention_risk_analysis.sql
        │   ├── vw_hed_program_performance.sql
        │   ├── vw_hed_engagement_analytics.sql
        │   └── vw_hed_data_quality.sql
        └── semantic_models/
            ├── metricflow_time_spine.sql
            ├── sem_vw_hed_engagement_analytics.yml
            └── sv_hed_at_risk_students.sql
```

---

## Model Layers

### Staging

#### `stg_hed__students`

The base student-record staging model. It centralizes the HED source reference, selects and standardizes the source columns, and adds reusable calculations such as:

- `days_since_last_login`
- `days_active_since_enrollment`
- `credit_success_rate_pct`

### Intermediate

#### `int_hed__risk_levels`

Student-level risk classification model. It derives GPA, completion, engagement, login-recency, financial-aid, intervention, and overall retention-risk categories.

#### `int_hed__engagement_categories`

Student-level engagement classification model. It derives categories for login recency, course views, assignments, discussion participation, engagement level, and recommended engagement actions.

### Data Quality

The data-quality layer breaks quality checks into focused component models:

- `dq_hed__completeness`
- `dq_hed__duplicates`
- `dq_hed__freshness`
- `dq_hed__validity`

These feed the mart-level `vw_hed_data_quality` dashboard view.

### Marts

#### `vw_hed_student_success_kpi`

Executive-level single-row KPI view summarizing enrollment, retention risk, GPA, course completion, engagement, financial aid, interventions, academic integrity incidents, and data freshness.

#### `vw_hed_retention_risk_analysis`

Student-level retention-risk view identifying at-risk students, risk drivers, severity levels, and recommended interventions.

#### `vw_hed_program_performance`

Major/program-level aggregation comparing enrollment, academic outcomes, retention risk, engagement, financial aid, interventions, academic integrity incidents, and overall program health.

#### `vw_hed_engagement_analytics`

Student-level engagement analytics across LMS login recency, course views, assignments, discussion participation, engagement categories, and recommended actions.

#### `vw_hed_data_quality`

Single-row data-quality dashboard summarizing completeness, validity, uniqueness, freshness, and overall quality status.

### Semantic Layer Assets

#### `metricflow_time_spine`

Date spine table used by MetricFlow for time-based semantic-layer queries.

#### `sem_vw_hed_engagement_analytics.yml`

MetricFlow semantic model and metrics for `vw_hed_engagement_analytics`.

#### `sv_hed_at_risk_students`

Snowflake semantic view over `vw_hed_retention_risk_analysis`, exposing facts, dimensions, filters, and verified queries for at-risk-student analysis.

---

## Source Configuration

The HED source is defined in `models/hed/_hed__sources.yml` and configured with dbt vars.

Current project vars in `dbt_project.yml`:

```yaml
vars:
  hed_source_database: 'RAW'
  hed_source_schema: 'INDUSTRIES_HIGHER_EDUCATION'
  hed_source_table: 'HED_RECORDS'
```

Source definition pattern:

```yaml
sources:
  - name: hed
    database: "{{ var('hed_source_database', 'HOL_DATABASE') }}"
    schema: "{{ var('hed_source_schema', 'INDUSTRIES_HIGHER_EDUCATION') }}"
    tables:
      - name: hed_records
        identifier: "{{ var('hed_source_table', 'HED_RECORDS') }}"
```

> Note: `dbt_project.yml` currently sets `hed_source_database` to `RAW`, while the source YAML fallback is `HOL_DATABASE`. The explicit project var takes precedence. If this project is reused in a different environment, update the vars in `dbt_project.yml` or override them at runtime.

---

## Prerequisites

- dbt with Snowflake adapter support
- Snowflake account and role with permissions to read the HED source table and create models in the target database/schema
- Access to the configured HED source table
- Installed dbt packages from `packages.yml`

Install package dependencies:

```bash
dbt deps
```

Packages used by this project:

- `dbt-labs/dbt_utils` `1.1.1`
- `Snowflake-Labs/dbt_semantic_view` `1.0.3`

---

## Quick Start

Validate the local dbt configuration:

```bash
dbt debug
```

Install dependencies:

```bash
dbt deps
```

Compile the project:

```bash
dbt compile
```

Build the HED models and tests:

```bash
dbt build --select hed.*
```

Run only HED models:

```bash
dbt run --select hed.*
```

Run only HED tests:

```bash
dbt test --select hed.*
```

Run by tag:

```bash
dbt run --select tag:hed
dbt run --select tag:education
```

Run a specific mart:

```bash
dbt run --select vw_hed_student_success_kpi
```

---

## Example Queries

### Executive KPI summary

```sql
select *
from INDUSTRIES_HIGHER_EDUCATION.VW_HED_STUDENT_SUCCESS_KPI;
```

### At-risk students needing intervention

```sql
select
  student_id,
  major_code,
  advisor_id,
  current_gpa,
  engagement_score,
  overall_risk_assessment,
  recommended_action
from INDUSTRIES_HIGHER_EDUCATION.VW_HED_RETENTION_RISK_ANALYSIS
order by current_gpa asc;
```

### Program performance

```sql
select
  major_code,
  total_students,
  avg_gpa,
  at_risk_percentage,
  program_health_score,
  performance_category
from INDUSTRIES_HIGHER_EDUCATION.VW_HED_PROGRAM_PERFORMANCE
order by program_health_score desc;
```

### Engagement concerns

```sql
select
  student_id,
  major_code,
  days_since_last_login,
  engagement_level,
  engagement_concern_level,
  recommended_engagement_action
from INDUSTRIES_HIGHER_EDUCATION.VW_HED_ENGAGEMENT_ANALYTICS
order by days_since_last_login desc;
```

### Data quality dashboard

```sql
select *
from INDUSTRIES_HIGHER_EDUCATION.VW_HED_DATA_QUALITY;
```

Adjust database and schema names as needed for the active dbt target and schema-generation behavior.

---

## Testing and Documentation

Run tests for HED models:

```bash
dbt test --select hed.*
```

Test the HED source:

```bash
dbt test --select source:hed
```

Generate docs:

```bash
dbt docs generate
```

Serve docs locally:

```bash
dbt docs serve
```

---

## Deployment

This project can be run from dbt Core, dbt Cloud, or another orchestrator.

A typical deployment command for the current HED implementation is:

```bash
dbt build --select hed.*
```

For narrower deployments, select by folder, model, or tag:

```bash
dbt build --select hed.marts.*
dbt build --select tag:data_quality
dbt build --select vw_hed_retention_risk_analysis
```

The project includes a `dbt-cloud` project id in `dbt_project.yml`, but credentials and environment configuration should be managed outside the repository.

---

## Adding a New Industry

To add another industry, follow the same folder-based pattern used by HED.

### 1. Add project configuration

Example for agriculture:

```yaml
models:
  dbt_industries_views:
    agr:
      +tags: ['agr', 'agriculture']
      +schema: industries_agriculture
      +materialized: view

vars:
  agr_source_database: 'RAW'
  agr_source_schema: 'INDUSTRIES_AGRICULTURE'
  agr_source_table: 'AGR_RECORDS'
```

### 2. Add a source definition

Create `models/agr/_agr__sources.yml`:

```yaml
version: 2

sources:
  - name: agr
    database: "{{ var('agr_source_database') }}"
    schema: "{{ var('agr_source_schema') }}"
    tables:
      - name: agr_records
        identifier: "{{ var('agr_source_table') }}"
```

### 3. Add models by layer

Recommended structure:

```text
models/agr/
├── _agr__sources.yml
├── staging/
├── intermediate/
├── data_quality/
├── marts/
└── semantic_models/        # Optional
```

### 4. Document and test

Add schema YAML files for model descriptions, column descriptions, and data tests. Follow the HED directory as the current convention.

### 5. Deploy selectively

```bash
dbt build --select agr.*
```

---

## Troubleshooting

### dbt cannot find the source table

Check the HED source vars:

```yaml
hed_source_database
hed_source_schema
hed_source_table
```

Then confirm the active dbt target has permission to read the resolved Snowflake object.

### Compilation fails

Run:

```bash
dbt compile --select hed.*
```

Review the failing model and any referenced YAML files for Jinja, YAML, or dependency errors.

### Tests fail

Run a narrower test selection to isolate the issue:

```bash
dbt test --select stg_hed__students
dbt test --select vw_hed_data_quality
```

Do not loosen or remove tests without first confirming whether the failure is caused by source data quality, model logic, or an outdated test assumption.

### Views are empty

Check that the source table has rows and that the model's filters are not excluding expected records. Start with the staging model and work downstream through intermediate and mart models.

### Semantic-layer assets fail

Check package installation and Snowflake support for the configured semantic view materialization. Re-run:

```bash
dbt deps
dbt compile --select hed.semantic_models.*
```

---

## Additional Guide

For detailed setup and deployment instructions specific to the Higher Education analytics package, see [`HED_SETUP_GUIDE.md`](HED_SETUP_GUIDE.md).

---

## Project Metadata

- **Project name:** `dbt_industries_views`
- **Version:** `1.0.0`
- **Warehouse adapter:** Snowflake
- **Current industry:** Higher Education (HED)
- **Current source:** `hed.hed_records`
- **Primary target schema config:** `industries_higher_education`
- **Primary materialization:** views
