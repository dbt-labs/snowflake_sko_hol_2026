# Construction (CON) Industry Views

Production-ready dbt views for construction project management analytics with Earned Value Management (EVM) metrics, weather impact analysis, and critical path monitoring.

## 📊 Views

### Analytics Views

#### 1. vw_con_kpi
Executive KPI dashboard with portfolio-wide construction metrics.
- Task completion and delay rates
- EVM performance indices (SPI, CPI) with health status
- Risk profile and critical path analysis
- Resource utilization and economics
- Material delivery performance

#### 2. vw_con_by_project
Project-level performance analysis with comprehensive metrics.
- Task status breakdown by project
- EVM performance indices
- Risk analysis and critical path tracking
- **Project Health Score (0-100)** - Composite score
- Average days behind schedule
- Sort: By project_health_score DESC

#### 3. vw_con_weather_impact
Weather correlation with delays and performance.
- Task delay rates by weather condition
- Schedule performance impact
- Weather characteristics (temp, precipitation, wind)
- Equipment breakdown rates
- **Weather Severity Score (0-100)**
- Sort: By weather_severity_score DESC

### Data Quality Views

#### 4. vw_con_data_quality
Comprehensive data quality monitoring.
- Field completeness percentages
- Logical consistency checks
- Business logic validation
- EVM index reasonability checks
- **Overall Quality Score (0-100)**
- Data freshness tracking

### Alert Views

#### 5. vw_con_critical_alerts
High-priority tasks requiring immediate attention.
- Alert categories: high risk, critical path delayed, behind schedule, over budget, blocked, material/equipment/weather issues
- **Alert Priority Score (0-100)**
- Alert severity (CRITICAL, HIGH, MEDIUM, LOW)
- Recommended actions
- Filter: Priority >= 10, not completed
- Sort: By priority DESC, risk DESC, days_delayed DESC

## 🎯 Understanding EVM Metrics

### Schedule Performance Index (SPI)
- **Formula:** Earned Value / Planned Value
- **SPI > 1.0** → Ahead of schedule ✅
- **SPI < 1.0** → Behind schedule ⚠️

### Cost Performance Index (CPI)
- **Formula:** Earned Value / Actual Cost
- **CPI > 1.0** → Under budget ✅
- **CPI < 1.0** → Over budget ⚠️

### Project Health Score
Composite score (0-100):
- Cost Performance (30%)
- Schedule Performance (30%)
- Risk Level inverse (20%)
- Completion (20%)

## 📁 Files

```
con/
├── _con_sources.yml           # Source definition for CON_RECORDS
├── schema.yml                 # Full documentation for all 5 views
├── vw_con_kpi.sql            # Executive KPI dashboard
├── vw_con_by_project.sql     # Project performance analysis
├── vw_con_weather_impact.sql # Weather impact analysis
├── vw_con_data_quality.sql   # Data quality monitoring
├── vw_con_critical_alerts.sql # Critical alerts
└── README.md                  # This file
```

## 🚀 Usage

### Run all CON views
```bash
dbt run --select con
```

### Run by tag
```bash
dbt run --select tag:construction
dbt run --select tag:analytics
dbt run --select tag:data_quality
dbt run --select tag:alerts
```

### Query examples
```sql
-- Get portfolio KPIs
SELECT * FROM HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS.vw_con_kpi;

-- Get projects ranked by health
SELECT 
  PROJECT_NAME,
  project_health_score,
  pct_completed,
  avg_schedule_performance_index
FROM HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS.vw_con_by_project
ORDER BY project_health_score DESC;

-- Get critical alerts
SELECT 
  PROJECT_NAME,
  TASK_NAME,
  alert_severity,
  alert_description,
  recommended_action
FROM HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS.vw_con_critical_alerts
WHERE alert_severity IN ('CRITICAL', 'HIGH')
LIMIT 20;
```

## 🔧 Configuration

**Source:**
- Database: `HOL_DATABASE`
- Schema: `INDUSTRIES_CONSTRUCTION`
- Table: `CON_RECORDS`

**Target:**
- Schema: `HOL_DATABASE.INDUSTRIES_CONSTRUCTION.VIEWS`
- Materialization: View

**Tags:**
- `construction` - All CON models
- `analytics` - Business intelligence views
- `data_quality` - Monitoring views
- `alerts` - Operational alerts

---

**Generated:** November 2025  
**Version:** 1.0.0
