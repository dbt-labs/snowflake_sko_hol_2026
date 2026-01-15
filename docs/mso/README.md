# MSO (Manufacturing MSO) Industry

## Overview

This folder contains dbt models for the **Manufacturing MSO (Material Selection Optimization)** industry, analyzing material selection and optimization data from CAD-based product design workflows.

## Source Data

- **Connector:** Fivetran Industries connector
- **Database:** HOL_DATABASE
- **Schema:** INDUSTRIES_MANUFACTURING
- **Table:** MSO_RECORDS
- **Records:** 750+ manufacturing material optimization records

## Data Domain

The MSO dataset tracks material selection and optimization decisions in manufacturing product design, including:

- **Material Properties:** Density, Young's Modulus, Poisson's Ratio
- **Design Tools:** CAD systems (SolidWorks, Autodesk Inventor, Siemens NX)
- **Optimization Metrics:** Cost savings, weight reduction, performance improvement, waste reduction
- **Designer Information:** Experience levels, skill levels (Beginner, Intermediate, Advanced)
- **Product Lifecycle:** Design, Development, Testing, Production stages
- **Recommendations:** Material selection and optimization recommendation flags

## Views

### 1. `vw_mso_kpi`
**Purpose:** Executive KPI dashboard  
**Key Metrics:**
- Total cost savings and ROI
- Average optimization metrics (weight, performance, waste reduction)
- Recommendation success rates
- Data freshness indicators

**Use Case:** Quick snapshot of overall material optimization program effectiveness

---

### 2. `vw_mso_by_cad_system`
**Purpose:** CAD platform performance comparison  
**Segments:** SolidWorks, Autodesk Inventor, Siemens NX  
**Key Metrics:**
- Cost savings by CAD system
- Optimization performance metrics
- Designer experience levels
- Product lifecycle distribution

**Use Case:** Identify which CAD tools yield the best optimization results

---

### 3. `vw_mso_optimization_trends`
**Purpose:** Time-series analysis of optimization progress  
**Granularity:** Monthly aggregations  
**Key Metrics:**
- Trending cost savings over time
- Monthly optimization volumes
- CAD system usage distribution
- Lifecycle stage distribution by month

**Use Case:** Track improvement trends and identify seasonal patterns

---

### 4. `vw_mso_designer_performance`
**Purpose:** Designer effectiveness analysis  
**Segments:** Beginner, Intermediate, Advanced skill levels  
**Key Metrics:**
- Cost savings by skill level
- Recommendation acceptance rates
- CAD system preferences
- Material efficiency metrics

**Use Case:** Identify training opportunities and best practices from experienced designers

---

### 5. `vw_mso_data_quality`
**Purpose:** Data quality monitoring  
**Checks:**
- Completeness percentages for all key fields
- Data validity checks (negative values, invalid scores)
- Date logic validation
- Recommendation consistency checks
- Overall data quality score

**Use Case:** Ensure data reliability for decision-making

## Running MSO Models

### Run all MSO models:
```bash
dbt run --select mso.*
```

### Run specific MSO view:
```bash
dbt run --select vw_mso_kpi
```

### Run by tag:
```bash
# Run all KPI views across all industries
dbt run --select tag:kpi

# Run only MSO analytics
dbt run --select tag:mso
```

## Business Value

The MSO views enable:

1. **Cost Optimization:** Track $480K+ average cost savings across optimization initiatives
2. **Tool Selection:** Compare CAD platform effectiveness for material optimization
3. **Talent Development:** Identify skill gaps and training needs across designer levels
4. **Process Improvement:** Monitor optimization trends to improve material selection workflows
5. **Quality Assurance:** Ensure data integrity for reliable decision-making

## Key Insights from Sample Data

- **60.3%** material selection recommendation rate
- **59.7%** material optimization recommendation rate
- **3 CAD systems** in use: Siemens NX (35%), Autodesk Inventor (33%), SolidWorks (32%)
- **4 lifecycle stages** tracked: Testing, Design, Development, Production
- **Designer distribution:** Intermediate (36%), Beginner (32%), Advanced (32%)

## Dependencies

- **Source:** `industries_mso.MSO_RECORDS` (defined in `_mso_sources.yml`)
- **dbt Core:** 1.0.0+
- **Snowflake:** Warehouse-specific SQL syntax used

## Tags

All MSO models are tagged with `mso` for selective execution. Additional tags include:
- `analytics` - Analytical views
- `kpi` - Executive KPI dashboards
- `trends` - Time-series analysis
- `designer` - Designer-focused views
- `data_quality` - Data quality monitoring

## Documentation

Full column-level documentation is available in `schema.yml`. To generate and view documentation:

```bash
dbt docs generate
dbt docs serve
```

## Notes

- All views filter out soft-deleted records using `WHERE _FIVETRAN_DELETED = FALSE`
- ROI calculated as: `(Total Cost Savings / Total Material Cost) × 100`
- Data quality score averages 5 key completeness metrics
- Optimization dates should always be after selection dates (validated in data quality view)
