-- Construction Projects KPI Summary
-- Purpose: Executive dashboard with key project performance metrics
-- Materialization: View
-- Tags: analytics, kpi, executive, construction

WITH source_data AS (
  SELECT
    *
  FROM {{ source('industries_construction', 'CON_RECORDS') }}
  WHERE TRUE  -- No _FIVETRAN_DELETED column in this schema
),

calculations AS (
  SELECT
    -- Project Counts
    COUNT(DISTINCT PROJECT_ID) AS total_projects,
    COUNT(DISTINCT TASK_ID) AS total_tasks,
    COUNT(DISTINCT RECORD_ID) AS total_records,
    
    -- Task Status Distribution
    SUM(CASE WHEN TASK_STATUS = 'Completed' THEN 1 ELSE 0 END) AS tasks_completed,
    SUM(CASE WHEN TASK_STATUS = 'In Progress' THEN 1 ELSE 0 END) AS tasks_in_progress,
    SUM(CASE WHEN TASK_STATUS = 'Delayed' THEN 1 ELSE 0 END) AS tasks_delayed,
    SUM(CASE WHEN TASK_STATUS = 'On Hold' THEN 1 ELSE 0 END) AS tasks_on_hold,
    
    -- Performance Metrics (Earned Value Management)
    AVG(SCHEDULE_PERFORMANCE_INDEX) AS avg_schedule_performance_index,
    AVG(COST_PERFORMANCE_INDEX) AS avg_cost_performance_index,
    AVG(PERCENT_COMPLETE) AS avg_percent_complete,
    
    -- Risk Analysis
    AVG(RISK_SCORE) AS avg_risk_score,
    SUM(CASE WHEN RISK_SCORE >= 70 THEN 1 ELSE 0 END) AS high_risk_tasks,
    
    -- Critical Path Analysis
    SUM(CASE WHEN CRITICAL_PATH_FLAG = true THEN 1 ELSE 0 END) AS critical_path_tasks,
    
    -- Resource Metrics
    AVG(RESOURCE_COST_PER_HOUR) AS avg_resource_cost_per_hour,
    AVG(RESOURCE_AVAILABILITY) AS avg_resource_availability,
    AVG(EQUIPMENT_UTILIZATION_RATE) AS avg_equipment_utilization,
    
    -- Material Delivery Performance
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Delivered' THEN 1 ELSE 0 END) AS materials_delivered,
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Delayed' THEN 1 ELSE 0 END) AS materials_delayed,
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Cancelled' THEN 1 ELSE 0 END) AS materials_cancelled,
    
    -- Data Freshness
    MAX(DATA_TIMESTAMP) AS last_updated
  FROM source_data
)

SELECT
  -- Project Overview
  total_projects,
  total_tasks,
  total_records,
  
  -- Task Completion Rates
  tasks_completed,
  ROUND(tasks_completed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_tasks_completed,
  tasks_in_progress,
  tasks_delayed,
  ROUND(tasks_delayed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_tasks_delayed,
  tasks_on_hold,
  
  -- EVM Performance Indices
  ROUND(avg_schedule_performance_index, 3) AS avg_spi,
  CASE
    WHEN avg_schedule_performance_index >= 1.0 THEN 'On Schedule'
    WHEN avg_schedule_performance_index >= 0.9 THEN 'Slightly Behind'
    ELSE 'Behind Schedule'
  END AS schedule_health,
  
  ROUND(avg_cost_performance_index, 3) AS avg_cpi,
  CASE
    WHEN avg_cost_performance_index >= 1.0 THEN 'Under Budget'
    WHEN avg_cost_performance_index >= 0.9 THEN 'Near Budget'
    ELSE 'Over Budget'
  END AS cost_health,
  
  ROUND(avg_percent_complete, 2) AS avg_task_completion_pct,
  
  -- Risk Profile
  ROUND(avg_risk_score, 2) AS avg_risk_score,
  high_risk_tasks,
  ROUND(high_risk_tasks * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_high_risk_tasks,
  
  -- Critical Path Analysis
  critical_path_tasks,
  ROUND(critical_path_tasks * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_critical_path_tasks,
  
  -- Resource Economics
  ROUND(avg_resource_cost_per_hour, 2) AS avg_hourly_cost,
  ROUND(avg_resource_availability, 3) AS avg_resource_availability,
  ROUND(avg_equipment_utilization, 3) AS avg_equipment_utilization,
  
  -- Material Delivery Performance
  materials_delivered,
  ROUND(materials_delivered * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_materials_delivered,
  materials_delayed,
  materials_cancelled,
  
  -- Data Freshness
  last_updated
FROM calculations
