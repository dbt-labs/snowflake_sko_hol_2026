-- Construction Weather Impact Analysis
-- Purpose: Analyze correlation between weather conditions and project delays
-- Materialization: View
-- Tags: analytics, weather, construction, operations

WITH source_data AS (
  SELECT
    *
  FROM {{ source('industries_construction', 'CON_RECORDS') }}
  WHERE TRUE  -- No _FIVETRAN_DELETED column in this schema
),

weather_metrics AS (
  SELECT
    WEATHER_CONDITION,
    
    -- Task Counts
    COUNT(DISTINCT TASK_ID) AS total_tasks,
    
    -- Status Distribution
    SUM(CASE WHEN TASK_STATUS = 'Delayed' THEN 1 ELSE 0 END) AS tasks_delayed,
    SUM(CASE WHEN TASK_STATUS = 'Completed' THEN 1 ELSE 0 END) AS tasks_completed,
    SUM(CASE WHEN TASK_STATUS = 'On Hold' THEN 1 ELSE 0 END) AS tasks_on_hold,
    
    -- Performance Impact
    AVG(SCHEDULE_PERFORMANCE_INDEX) AS avg_spi,
    AVG(PERCENT_COMPLETE) AS avg_completion_pct,
    
    -- Weather Metrics
    AVG(TEMPERATURE_FAHRENHEIT) AS avg_temperature,
    MIN(TEMPERATURE_FAHRENHEIT) AS min_temperature,
    MAX(TEMPERATURE_FAHRENHEIT) AS max_temperature,
    AVG(PRECIPITATION_PROBABILITY) AS avg_precipitation_prob,
    AVG(WIND_SPEED_MPH) AS avg_wind_speed,
    
    -- Schedule Impact
    AVG(DATEDIFF(day, SCHEDULED_END_DATE, ACTUAL_END_DATE)) AS avg_schedule_variance_days,
    
    -- Risk
    AVG(RISK_SCORE) AS avg_risk_score,
    
    -- Equipment Impact
    SUM(CASE WHEN EQUIPMENT_STATUS = 'Breakdown' THEN 1 ELSE 0 END) AS equipment_breakdowns,
    SUM(CASE WHEN EQUIPMENT_STATUS = 'Repair' THEN 1 ELSE 0 END) AS equipment_repairs,
    AVG(EQUIPMENT_UTILIZATION_RATE) AS avg_equipment_utilization
    
  FROM source_data
  GROUP BY WEATHER_CONDITION
)

SELECT
  WEATHER_CONDITION,
  total_tasks,
  
  -- Delay Analysis
  tasks_delayed,
  ROUND(tasks_delayed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_tasks_delayed,
  tasks_completed,
  ROUND(tasks_completed * 100.0 / NULLIF(total_tasks, 0), 2) AS pct_tasks_completed,
  tasks_on_hold,
  
  -- Performance Impact
  ROUND(avg_spi, 3) AS avg_schedule_performance_index,
  CASE
    WHEN avg_spi >= 1.0 THEN 'On Schedule'
    WHEN avg_spi >= 0.9 THEN 'Slightly Behind'
    ELSE 'Behind Schedule'
  END AS schedule_health,
  ROUND(avg_completion_pct, 2) AS avg_percent_complete,
  
  -- Weather Conditions
  ROUND(avg_temperature, 1) AS avg_temp_f,
  ROUND(min_temperature, 1) AS min_temp_f,
  ROUND(max_temperature, 1) AS max_temp_f,
  ROUND(avg_precipitation_prob, 1) AS avg_precip_probability_pct,
  ROUND(avg_wind_speed, 1) AS avg_wind_speed_mph,
  
  -- Schedule Variance
  ROUND(avg_schedule_variance_days, 2) AS avg_days_behind_schedule,
  
  -- Risk Analysis
  ROUND(avg_risk_score, 2) AS avg_risk_score,
  
  -- Equipment Impact
  equipment_breakdowns,
  equipment_repairs,
  ROUND(avg_equipment_utilization, 3) AS avg_equipment_utilization,
  
  -- Weather Severity Score (0-100, higher = more severe impact)
  ROUND(
    (tasks_delayed * 100.0 / NULLIF(total_tasks, 0) * 0.4) +  -- Delay rate: 40%
    (CASE WHEN avg_schedule_variance_days > 0 THEN LEAST(avg_schedule_variance_days * 2, 30) ELSE 0 END) +  -- Schedule variance: up to 30 points
    ((equipment_breakdowns + equipment_repairs) * 100.0 / NULLIF(total_tasks, 0) * 0.3)  -- Equipment issues: 30%
  , 2) AS weather_severity_score
  
FROM weather_metrics
ORDER BY weather_severity_score DESC, pct_tasks_delayed DESC
