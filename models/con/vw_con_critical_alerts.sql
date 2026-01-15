-- Construction Critical Alerts
-- Purpose: Identify high-risk tasks, critical path delays, and actionable items requiring immediate attention
-- Materialization: View
-- Tags: alerts, operations, construction, monitoring

WITH source_data AS (
  SELECT
    *
  FROM {{ source('industries_construction', 'CON_RECORDS') }}
  WHERE TRUE  -- No _FIVETRAN_DELETED column in this schema
),

alert_conditions AS (
  SELECT
    RECORD_ID,
    PROJECT_ID,
    PROJECT_NAME,
    TASK_ID,
    TASK_NAME,
    TASK_STATUS,
    PERCENT_COMPLETE,
    CRITICAL_PATH_FLAG,
    SCHEDULE_PERFORMANCE_INDEX,
    COST_PERFORMANCE_INDEX,
    RISK_SCORE,
    SCHEDULED_START_DATE,
    SCHEDULED_END_DATE,
    ACTUAL_START_DATE,
    ACTUAL_END_DATE,
    RESOURCE_TYPE,
    RESOURCE_COST_PER_HOUR,
    WEATHER_CONDITION,
    MATERIAL_DELIVERY_STATUS,
    MATERIAL_DELIVERY_DATE,
    EQUIPMENT_STATUS,
    EQUIPMENT_UTILIZATION_RATE,
    DATA_TIMESTAMP,
    
    -- Calculate days delayed
    DATEDIFF(day, SCHEDULED_END_DATE, COALESCE(ACTUAL_END_DATE, CURRENT_DATE())) AS days_delayed,
    
    -- Determine alert categories (task can have multiple alerts)
    CASE WHEN RISK_SCORE >= 70 THEN 1 ELSE 0 END AS is_high_risk,
    CASE WHEN CRITICAL_PATH_FLAG = true AND TASK_STATUS = 'Delayed' THEN 1 ELSE 0 END AS is_critical_path_delayed,
    CASE WHEN SCHEDULE_PERFORMANCE_INDEX < 0.8 THEN 1 ELSE 0 END AS is_behind_schedule,
    CASE WHEN COST_PERFORMANCE_INDEX < 0.8 THEN 1 ELSE 0 END AS is_over_budget,
    CASE WHEN TASK_STATUS IN ('Delayed', 'On Hold') AND CRITICAL_PATH_FLAG = true THEN 1 ELSE 0 END AS is_critical_blocked,
    CASE WHEN MATERIAL_DELIVERY_STATUS IN ('Delayed', 'Cancelled') THEN 1 ELSE 0 END AS has_material_issue,
    CASE WHEN EQUIPMENT_STATUS IN ('Breakdown', 'Repair') THEN 1 ELSE 0 END AS has_equipment_issue,
    CASE WHEN WEATHER_CONDITION IN ('Heavy Rain', 'Thunderstorms', 'Snow') AND TASK_STATUS IN ('In Progress', 'Delayed') THEN 1 ELSE 0 END AS has_weather_risk
    
  FROM source_data
  WHERE
    -- Only include tasks that require attention
    (
      RISK_SCORE >= 70  -- High risk
      OR (CRITICAL_PATH_FLAG = true AND TASK_STATUS IN ('Delayed', 'On Hold'))  -- Critical path issues
      OR SCHEDULE_PERFORMANCE_INDEX < 0.8  -- Significantly behind schedule
      OR COST_PERFORMANCE_INDEX < 0.8  -- Significantly over budget
      OR MATERIAL_DELIVERY_STATUS IN ('Delayed', 'Cancelled')  -- Material issues
      OR EQUIPMENT_STATUS IN ('Breakdown', 'Repair')  -- Equipment issues
      OR (WEATHER_CONDITION IN ('Heavy Rain', 'Thunderstorms', 'Snow') AND TASK_STATUS IN ('In Progress', 'Delayed'))  -- Weather risks
    )
    AND TASK_STATUS != 'Completed'  -- Exclude completed tasks
)

SELECT
  RECORD_ID,
  PROJECT_ID,
  PROJECT_NAME,
  TASK_ID,
  TASK_NAME,
  TASK_STATUS,
  ROUND(PERCENT_COMPLETE, 2) AS pct_complete,
  CRITICAL_PATH_FLAG,
  
  -- Alert Flags
  is_high_risk,
  is_critical_path_delayed,
  is_behind_schedule,
  is_over_budget,
  is_critical_blocked,
  has_material_issue,
  has_equipment_issue,
  has_weather_risk,
  
  -- Alert Priority Score (0-100, higher = more urgent)
  ROUND(
    (is_high_risk * 20) +
    (is_critical_path_delayed * 25) +
    (is_behind_schedule * 15) +
    (is_over_budget * 10) +
    (is_critical_blocked * 20) +
    (has_material_issue * 5) +
    (has_equipment_issue * 3) +
    (has_weather_risk * 2)
  , 0) AS alert_priority_score,
  
  -- Alert Severity
  CASE
    WHEN (is_critical_path_delayed = 1 OR is_critical_blocked = 1) AND is_high_risk = 1 THEN 'CRITICAL'
    WHEN is_critical_path_delayed = 1 OR is_critical_blocked = 1 OR is_high_risk = 1 THEN 'HIGH'
    WHEN is_behind_schedule = 1 OR is_over_budget = 1 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS alert_severity,
  
  -- Alert Description
  CONCAT(
    CASE WHEN is_critical_path_delayed = 1 THEN '⚠️ CRITICAL PATH DELAYED | ' ELSE '' END,
    CASE WHEN is_critical_blocked = 1 THEN '🚫 CRITICAL PATH BLOCKED | ' ELSE '' END,
    CASE WHEN is_high_risk = 1 THEN '⚠️ HIGH RISK (' || ROUND(RISK_SCORE, 0) || ') | ' ELSE '' END,
    CASE WHEN is_behind_schedule = 1 THEN '📉 BEHIND SCHEDULE (SPI: ' || ROUND(SCHEDULE_PERFORMANCE_INDEX, 2) || ') | ' ELSE '' END,
    CASE WHEN is_over_budget = 1 THEN '💰 OVER BUDGET (CPI: ' || ROUND(COST_PERFORMANCE_INDEX, 2) || ') | ' ELSE '' END,
    CASE WHEN has_material_issue = 1 THEN '📦 MATERIAL ISSUE (' || MATERIAL_DELIVERY_STATUS || ') | ' ELSE '' END,
    CASE WHEN has_equipment_issue = 1 THEN '🔧 EQUIPMENT ISSUE (' || EQUIPMENT_STATUS || ') | ' ELSE '' END,
    CASE WHEN has_weather_risk = 1 THEN '🌧️ WEATHER RISK (' || WEATHER_CONDITION || ')' ELSE '' END
  ) AS alert_description,
  
  -- Performance Metrics
  ROUND(SCHEDULE_PERFORMANCE_INDEX, 3) AS spi,
  ROUND(COST_PERFORMANCE_INDEX, 3) AS cpi,
  ROUND(RISK_SCORE, 2) AS risk_score,
  days_delayed,
  
  -- Schedule Details
  SCHEDULED_START_DATE,
  SCHEDULED_END_DATE,
  ACTUAL_START_DATE,
  ACTUAL_END_DATE,
  
  -- Resource & Logistics
  RESOURCE_TYPE,
  ROUND(RESOURCE_COST_PER_HOUR, 2) AS hourly_cost,
  WEATHER_CONDITION,
  MATERIAL_DELIVERY_STATUS,
  MATERIAL_DELIVERY_DATE,
  EQUIPMENT_STATUS,
  ROUND(EQUIPMENT_UTILIZATION_RATE, 3) AS equipment_utilization,
  
  -- Recommended Actions
  CASE
    WHEN is_critical_blocked = 1 THEN '1. Immediately unblock critical path task'
    WHEN is_critical_path_delayed = 1 AND is_high_risk = 1 THEN '1. Fast-track critical path recovery, 2. Mitigate high risk factors'
    WHEN is_critical_path_delayed = 1 THEN '1. Accelerate critical path task completion'
    WHEN is_high_risk = 1 AND has_material_issue = 1 THEN '1. Address material delivery issues, 2. Implement risk mitigation plan'
    WHEN is_high_risk = 1 THEN '1. Implement risk mitigation plan'
    WHEN has_material_issue = 1 AND has_equipment_issue = 1 THEN '1. Resolve material delivery, 2. Repair/replace equipment'
    WHEN has_material_issue = 1 THEN '1. Expedite material delivery or find alternative supplier'
    WHEN has_equipment_issue = 1 THEN '1. Prioritize equipment repair or source backup equipment'
    WHEN is_behind_schedule = 1 THEN '1. Analyze schedule variance and reallocate resources'
    WHEN is_over_budget = 1 THEN '1. Review cost overruns and implement cost controls'
    ELSE '1. Monitor closely for further deterioration'
  END AS recommended_action,
  
  DATA_TIMESTAMP AS last_updated
  
FROM alert_conditions
WHERE
  -- Filter to only significant alerts (priority score >= 10)
  (
    (is_high_risk * 20) +
    (is_critical_path_delayed * 25) +
    (is_behind_schedule * 15) +
    (is_over_budget * 10) +
    (is_critical_blocked * 20) +
    (has_material_issue * 5) +
    (has_equipment_issue * 3) +
    (has_weather_risk * 2)
  ) >= 10
  
ORDER BY alert_priority_score DESC, RISK_SCORE DESC, days_delayed DESC
