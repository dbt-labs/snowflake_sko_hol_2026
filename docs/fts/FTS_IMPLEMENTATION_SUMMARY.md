# FTS (Energy) Models - Implementation Summary

## 📊 Dataset Analysis

**Industry:** Energy / Utilities - Field Technician Service (FTS)  
**Records:** 750 maintenance logs  
**Date Range:** June 27, 2024 - July 16, 2026  
**Focus:** Field service maintenance operations, equipment reliability, technician performance

### Key Data Characteristics:
- **Maintenance Types:** Reliability-Centered (162), Corrective (157), Condition-Based (150), Preventive (145), Predictive (136)
- **Maintenance Status:** Evenly distributed across Cancelled (165), Completed (149), In Progress (148), Scheduled (145), Delayed (143)
- **Unique Assets:** 750 technicians, 750 equipment units, 750 customers, 750 work orders
- **Average Metrics:**
  - Failure Rate: 0.49 (49% - moderate risk)
  - Maintenance Cost: $551.29 per activity
  - Downtime: 5.47 hours per activity
  - Time Saved (AI): 2.99 hours per log

---

## 🎯 5 Views Created for Energy/Utilities

### 1. **vw_fts_maintenance_efficiency_kpi**
**Purpose:** Executive dashboard for maintenance operations effectiveness

**Key Metrics:**
- Overall completion, cancellation, and delay rates
- Total maintenance costs and cost per equipment
- Total downtime and reliability metrics
- AI summarization time savings
- Best/worst performing maintenance types
- Overall efficiency score (0-100)

**Business Value:** Optimize maintenance strategies, reduce costs, minimize downtime, and track operational KPIs in real-time.

---

### 2. **vw_fts_equipment_reliability_analysis**
**Purpose:** Equipment-level failure tracking and maintenance prioritization

**Key Metrics:**
- Equipment risk level (Critical/High/Medium/Low)
- Maintenance history and completion rates
- Total costs and downtime per equipment
- Proactive vs. reactive maintenance mix
- Equipment health score (0-100)
- Maintenance priority ranking (1-5)

**Business Value:** Identify high-risk equipment requiring immediate attention, optimize preventive maintenance schedules, and reduce unplanned failures.

---

### 3. **vw_fts_maintenance_type_performance**
**Purpose:** Compare effectiveness of different maintenance strategies

**Key Metrics:**
- Completion rates by maintenance type
- Cost efficiency comparisons
- Downtime reduction effectiveness
- Equipment reliability impact
- Effectiveness score (0-100)
- ROI indicator (effectiveness / cost)

**Business Value:** Determine optimal mix of Preventive, Predictive, Corrective, Condition-Based, and Reliability-Centered maintenance strategies.

---

### 4. **vw_fts_technician_productivity**
**Purpose:** Technician performance and workload optimization

**Key Metrics:**
- Workload vs. average (Overloaded/Balanced/Underutilized)
- Completion and delay rates per technician
- Cost and time efficiency metrics
- Proactive work percentage
- Productivity score (0-100)
- Performance tier (Top/Strong/Average/Needs Development)

**Business Value:** Balance workloads, identify top performers for mentorship, and target training for underperformers to improve workforce efficiency.

---

### 5. **vw_fts_data_quality**
**Purpose:** Data completeness and freshness monitoring

**Key Metrics:**
- Completeness score for critical fields
- Duplicate detection
- Value validation (invalid failure rates, negative costs)
- Data freshness status
- Overall data quality score (0-100)

**Business Value:** Ensure reliable analytics foundation by proactively monitoring data health and detecting issues early.

---

## 🔧 dbt Configuration

### dbt_project.yml Addition:
```yaml
    # FTS Energy/Utilities Field Service Models (NEW)
    fts:
      +tags: ['fts', 'energy']
      +schema: industries_energy
      +materialized: view
```

### Variables Addition:
```yaml
  # Source configuration for FTS Energy (NEW)
  fts_source_database: 'HOL_DATABASE'
  fts_source_schema: 'INDUSTRIES_ENERGY'
  fts_source_table: 'FTS_RECORDS'
```

### Project Structure:
```
dbt_industries_views/
├── models/
│   ├── cds/     # Healthcare ✅
│   ├── cpg/     # Consumer Packaged Goods ✅
│   └── fts/     # Energy/Utilities Field Service ✅ NEW
│       ├── _fts__sources.yml
│       ├── schema.yml
│       ├── vw_fts_maintenance_efficiency_kpi.sql
│       ├── vw_fts_equipment_reliability_analysis.sql
│       ├── vw_fts_maintenance_type_performance.sql
│       ├── vw_fts_technician_productivity.sql
│       └── vw_fts_data_quality.sql
```

---

## 🚀 Quick Start Commands

```bash
# Copy files to your project
mkdir -p models/fts/
cp /downloads/fts/* models/fts/

# Compile to check syntax
dbt compile --select fts

# Run all FTS models
dbt run --select fts

# Run specific models
dbt run --select vw_fts_maintenance_efficiency_kpi
dbt run --select tag:reliability

# Test data quality
dbt run --select tag:data_quality
```

---

## 💡 Key Insights from Dataset

**Maintenance Strategy Distribution:**
- Fairly balanced across all 5 maintenance types
- Reliability-Centered and Corrective are most common (162, 157 activities)
- Opportunity to shift more work to Predictive (136 activities)

**Operational Challenges:**
- 22% cancellation rate (165 out of 750) - investigate root causes
- 19% delay rate (143 out of 750) - address scheduling/resource issues
- 20% completion rate (only 149 completed) - significant improvement opportunity

**Equipment Risk:**
- Average failure rate of 49% indicates moderate reliability concerns
- High variability (0% to 100% failure rates) suggests mixed equipment health
- Prioritize equipment with failure rates > 70% for immediate maintenance

**Cost & Downtime:**
- Wide cost range ($100-$999 per activity) - standardization opportunity
- Average 5.47 hours downtime - room for efficiency improvements
- AI summarization saving 3 hours per log - good efficiency gain

**Workforce:**
- 750 unique technicians suggests either:
  - One log per technician (training/onboarding scenario), or
  - Data quality issue (should be fewer technicians with multiple logs each)

---

## 📊 Expected View Outputs

### Maintenance Efficiency KPI View:
- Overall efficiency score (based on completion, delays, failures)
- Best performing maintenance type recommendation
- Cost per equipment benchmarks
- Time savings from AI summarization

### Equipment Reliability View:
- Priority list of equipment needing attention (Priority 5 = urgent)
- Equipment health scores
- Maintenance frequency recommendations
- Proactive vs. reactive maintenance ratios

### Maintenance Type Performance View:
- Effectiveness scores for each strategy
- ROI indicators showing which strategies provide best value
- Strategic recommendations for optimizing maintenance mix

### Technician Productivity View:
- Performance tiers (Top/Strong/Average/Needs Development)
- Workload balance analysis
- Training and development recommendations
- Top performers for best practice sharing

### Data Quality View:
- Data quality score (should be 95+ for reliable analytics)
- Validation issues requiring attention
- Freshness status

---

## 🎯 Business Outcomes

**Cost Reduction:**
- Identify inefficient maintenance types and optimize mix
- Reduce reactive maintenance through better predictive strategies
- Optimize technician utilization and reduce overtime

**Reliability Improvement:**
- Prioritize high-risk equipment for preventive maintenance
- Shift from reactive to proactive maintenance strategies
- Reduce unplanned downtime through better forecasting

**Workforce Optimization:**
- Balance workloads across technicians
- Identify training needs for underperformers
- Recognize and leverage top performers as mentors

**Data-Driven Decision Making:**
- Real-time operational KPIs for executives
- Equipment-level insights for maintenance planning
- Strategy-level analytics for continuous improvement

---

## 📁 Package Contents

**Files in fts_dbt_models.zip:**
1. `_fts__sources.yml` - Source definitions with full column documentation
2. `schema.yml` - Model documentation for all 5 views
3. `vw_fts_maintenance_efficiency_kpi.sql` - Executive KPI dashboard
4. `vw_fts_equipment_reliability_analysis.sql` - Equipment risk tracking
5. `vw_fts_maintenance_type_performance.sql` - Strategy comparison
6. `vw_fts_technician_productivity.sql` - Workforce analytics
7. `vw_fts_data_quality.sql` - Data quality monitoring

---

## 🔍 Next Steps

1. **Deploy:** Copy files to `models/fts/` and run `dbt compile`
2. **Validate:** Review view outputs and confirm metrics align with business expectations
3. **Dashboard:** Connect views to BI tool (Tableau, Looker, Power BI)
4. **Iterate:** Gather stakeholder feedback and refine models as needed
5. **Expand:** Add more industries following the same pattern

---

**Generated:** November 4, 2025  
**Analyst:** Claude (Anthropic)  
**dbt Skill:** building-dbt-projects-with-fivetran-integration  
**Industry:** Energy / Utilities (Field Technician Service)
