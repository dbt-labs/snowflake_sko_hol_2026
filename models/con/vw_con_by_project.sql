-- Construction Projects Performance by Project
-- Purpose: Analyze performance metrics segmented by project name
-- Materialization: View
-- Tags: analytics, segmentation, construction

WITH source_data AS (
  SELECT
    *
  FROM {{ source('industries_construction', 'CON_RECORDS') }}
  WHERE TRUE  -- No _FIVETRAN_DELETED column in this schema
),

project_metrics AS (
  SELECT
    PROJECT_ID,
    PROJECT_NAME,
    
    -- Task Counts
    COUNT(DISTINCT TASK_ID) AS total_tasks,
    COUNT(DISTINCT RECORD_ID) AS total_records,
    
    -- Status Distribution
    SUM(CASE WHEN TASK_STATUS = 'Completed' THEN 1 ELSE 0 END) AS tasks_completed,
    SUM(CASE WHEN TASK_STATUS = 'In Progress' THEN 1 ELSE 0 END) AS tasks_in_progress,
    SUM(CASE WHEN TASK_STATUS = 'Delayed' THEN 1 ELSE 0 END) AS tasks_delayed,
    SUM(CASE WHEN TASK_STATUS = 'On Hold' THEN 1 ELSE 0 END) AS tasks_on_hold,
    SUM(CASE WHEN TASK_STATUS = 'Not Started' THEN 1 ELSE 0 END) AS tasks_not_started,
    SUM(CASE WHEN TASK_STATUS = 'Under Review' THEN 1 ELSE 0 END) AS tasks_under_review,
    
    -- Performance Metrics
    AVG(SCHEDULE_PERFORMANCE_INDEX) AS avg_spi,
    AVG(COST_PERFORMANCE_INDEX) AS avg_cpi,
    AVG(PERCENT_COMPLETE) AS avg_completion_pct,
    
    -- Risk Analysis
    AVG(RISK_SCORE) AS avg_risk_score,
    MAX(RISK_SCORE) AS max_risk_score,
    SUM(CASE WHEN RISK_SCORE >= 70 THEN 1 ELSE 0 END) AS high_risk_tasks,
    
    -- Critical Path
    SUM(CASE WHEN CRITICAL_PATH_FLAG = true THEN 1 ELSE 0 END) AS critical_path_tasks,
    
    -- Resource Economics
    AVG(RESOURCE_COST_PER_HOUR) AS avg_hourly_cost,
    AVG(RESOURCE_AVAILABILITY) AS avg_resource_availability,
    AVG(EQUIPMENT_UTILIZATION_RATE) AS avg_equipment_utilization,
    
    -- Material Delivery
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Delivered' THEN 1 ELSE 0 END) AS materials_delivered,
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Delayed' THEN 1 ELSE 0 END) AS materials_delayed,
    SUM(CASE WHEN MATERIAL_DELIVERY_STATUS = 'Cancelled' THEN 1 ELSE 0 END) AS materials_cancelled,
    
    -- Schedule Variance (Days)
    AVG(DATEDIFF(day, SCHEDULED_END_DATE, ACTUAL_END_DATE)) AS avg_schedule_variance_days,
    
    -- Data Freshness
    MAX(DATA_TIMESTAMP) AS last_updated
    
  FROM source_data
  GROUP BY PROJECT_ID, PROJECT_NAME
)

SELECT
  PROJECT_ID,
  PROJECT_NAME,
  total_tasks,
  total_records,
  
  -- Task Status Summary
  tasks_completed,
  ROUND(tasks_completed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_completed,
  tasks_in_progress,
  tasks_delayed,
  ROUND(tasks_delayed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_delayed,
  tasks_on_hold,
  tasks_not_started,
  tasks_under_review,
  
  -- EVM Performance
  ROUND(avg_spi, 3) AS avg_schedule_performance_index,
  CASE
    WHEN avg_spi >= 1.0 THEN 'On Schedule'
    WHEN avg_spi >= 0.9 THEN 'Slightly Behind'
    ELSE 'Behind Schedule'
  END AS schedule_health,
  
  ROUND(avg_cpi, 3) AS avg_cost_performance_index,
  CASE
    WHEN avg_cpi >= 1.0 THEN 'Under Budget'
    WHEN avg_cpi >= 0.9 THEN 'Near Budget'
    ELSE 'Over Budget'
  END AS cost_health,
  
  ROUND(avg_completion_pct, 2) AS avg_task_completion_pct,
  
  -- Risk Profile
  ROUND(avg_risk_score, 2) AS avg_risk_score,
  ROUND(max_risk_score, 2) AS max_risk_score,
  high_risk_tasks,
  ROUND(high_risk_tasks * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_high_risk,
  
  -- Critical Path
  critical_path_tasks,
  ROUND(critical_path_tasks * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_critical_path,
  
  -- Resource Metrics
  ROUND(avg_hourly_cost, 2) AS avg_resource_cost_per_hour,
  ROUND(avg_resource_availability, 3) AS avg_resource_availability,
  ROUND(avg_equipment_utilization, 3) AS avg_equipment_utilization,
  
  -- Material Performance
  materials_delivered,
  ROUND(materials_delivered * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_materials_delivered,
  materials_delayed,
  materials_cancelled,
  
  -- Schedule Analysis
  ROUND(avg_schedule_variance_days, 2) AS avg_days_behind_schedule,
  
  -- Overall Project Health Score (0-100)
  ROUND(
    (LEAST(avg_cpi, 1.0) * 30) +  -- Cost performance: 30 points max
    (LEAST(avg_spi, 1.0) * 30) +  -- Schedule performance: 30 points max
    ((100 - avg_risk_score) / 100 * 20) +  -- Risk (inverse): 20 points max
    ((tasks_completed * 100.0 / NULLIF(total_tasks, 0)) / 100 * 20)  -- Completion: 20 points max
  * 100, 2) AS project_health_score,
  
  last_updated
  
FROM project_metrics
ORDER BY project_health_score DESC, total_tasks DESC
