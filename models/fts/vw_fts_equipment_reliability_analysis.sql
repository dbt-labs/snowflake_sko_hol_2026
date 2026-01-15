{{
  config(
    materialized='view',
    tags=['fts', 'energy', 'analytics', 'reliability', 'equipment']
  )
}}

/*
  FTS Equipment Reliability Analysis
  
  Purpose: Track equipment failure rates, maintenance history, and predict
  maintenance needs to minimize unplanned downtime and optimize schedules.
  
  Key Metrics:
  - Equipment failure rate classification
  - Maintenance frequency and costs per equipment
  - Downtime patterns and trends
  - Risk-based maintenance prioritization
  
  Business Value: Identify high-risk equipment requiring immediate attention
  and optimize preventive maintenance schedules to reduce failures.
*/

WITH base_data AS (
  SELECT
    equipment_id,
    customer_id,
    maintenance_type,
    maintenance_status,
    failure_rate,
    maintenance_cost,
    downtime_hours,
    log_date
  FROM {{ source('fts', 'fts_records') }}
),

equipment_metrics AS (
  SELECT
    equipment_id,
    customer_id,
    
    -- Failure risk
    AVG(failure_rate) AS avg_failure_rate,
    MIN(failure_rate) AS min_failure_rate,
    MAX(failure_rate) AS max_failure_rate,
    
    -- Maintenance volume
    COUNT(*) AS total_maintenance_events,
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END) AS completed_maintenance,
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END) AS cancelled_maintenance,
    
    -- Cost analysis
    SUM(maintenance_cost) AS total_maintenance_cost,
    AVG(maintenance_cost) AS avg_maintenance_cost,
    
    -- Downtime analysis
    SUM(downtime_hours) AS total_downtime_hours,
    AVG(downtime_hours) AS avg_downtime_hours,
    
    -- Maintenance type distribution
    COUNT(CASE WHEN maintenance_type = 'Preventive Maintenance' THEN 1 END) AS preventive_count,
    COUNT(CASE WHEN maintenance_type = 'Predictive Maintenance' THEN 1 END) AS predictive_count,
    COUNT(CASE WHEN maintenance_type = 'Corrective Maintenance' THEN 1 END) AS corrective_count,
    COUNT(CASE WHEN maintenance_type = 'Condition-Based Maintenance' THEN 1 END) AS condition_based_count,
    COUNT(CASE WHEN maintenance_type = 'Reliability-Centered Maintenance' THEN 1 END) AS rcm_count,
    
    -- Completion rate
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS completion_rate,
    
    -- Last maintenance
    MAX(log_date) AS last_maintenance_date,
    MIN(log_date) AS first_maintenance_date
    
  FROM base_data
  GROUP BY equipment_id, customer_id
),

equipment_classification AS (
  SELECT
    equipment_id,
    customer_id,
    
    -- Failure metrics
    ROUND(avg_failure_rate, 3) AS avg_failure_rate,
    ROUND(min_failure_rate, 3) AS min_failure_rate,
    ROUND(max_failure_rate, 3) AS max_failure_rate,
    
    -- Risk classification
    CASE
      WHEN avg_failure_rate >= 0.7 THEN 'Critical Risk'
      WHEN avg_failure_rate >= 0.5 THEN 'High Risk'
      WHEN avg_failure_rate >= 0.3 THEN 'Medium Risk'
      ELSE 'Low Risk'
    END AS risk_level,
    
    -- Maintenance volume
    total_maintenance_events,
    completed_maintenance,
    cancelled_maintenance,
    ROUND(completion_rate * 100, 2) AS completion_rate_pct,
    
    -- Cost metrics
    ROUND(total_maintenance_cost, 2) AS total_maintenance_cost,
    ROUND(avg_maintenance_cost, 2) AS avg_maintenance_cost,
    ROUND(total_maintenance_cost / NULLIF(total_maintenance_events, 0), 2) 
      AS cost_per_event,
    
    -- Downtime metrics
    total_downtime_hours,
    ROUND(avg_downtime_hours, 1) AS avg_downtime_hours,
    ROUND(total_downtime_hours::FLOAT / NULLIF(total_maintenance_events, 0), 1) 
      AS downtime_per_event,
    
    -- Maintenance strategy mix
    preventive_count,
    predictive_count,
    corrective_count,
    condition_based_count,
    rcm_count,
    
    -- Calculate strategy percentage
    ROUND(corrective_count::FLOAT / NULLIF(total_maintenance_events, 0) * 100, 1) 
      AS corrective_pct,
    ROUND((preventive_count + predictive_count)::FLOAT / 
      NULLIF(total_maintenance_events, 0) * 100, 1) AS proactive_pct,
    
    -- Maintenance frequency (days between events)
    CASE 
      WHEN total_maintenance_events > 1 THEN
        DATEDIFF('day', first_maintenance_date, last_maintenance_date)::FLOAT / 
          NULLIF(total_maintenance_events - 1, 0)
      ELSE NULL
    END AS avg_days_between_maintenance,
    
    -- Recency
    last_maintenance_date,
    DATEDIFF('day', last_maintenance_date, CURRENT_DATE()) AS days_since_last_maintenance,
    
    -- Equipment health score (0-100)
    ROUND(
      (
        -- Low failure rate (40 points)
        ((1 - avg_failure_rate) * 40) +
        -- High completion rate (20 points)
        (completion_rate * 20) +
        -- Low downtime (20 points)
        (CASE 
          WHEN avg_downtime_hours <= 3 THEN 20
          WHEN avg_downtime_hours <= 6 THEN 15
          WHEN avg_downtime_hours <= 8 THEN 10
          ELSE 5
        END) +
        -- Proactive maintenance mix (20 points)
        (LEAST((preventive_count + predictive_count)::FLOAT / 
          NULLIF(total_maintenance_events, 0), 1) * 20)
      ), 0
    ) AS equipment_health_score,
    
    first_maintenance_date
    
  FROM equipment_metrics
)

SELECT
  equipment_id,
  customer_id,
  
  -- Risk assessment
  risk_level,
  avg_failure_rate,
  min_failure_rate,
  max_failure_rate,
  
  -- Maintenance history
  total_maintenance_events,
  completed_maintenance,
  cancelled_maintenance,
  completion_rate_pct,
  
  -- Cost analysis
  total_maintenance_cost,
  avg_maintenance_cost,
  cost_per_event,
  
  -- Downtime analysis
  total_downtime_hours,
  avg_downtime_hours,
  downtime_per_event,
  
  -- Maintenance strategy breakdown
  preventive_count,
  predictive_count,
  corrective_count,
  condition_based_count,
  rcm_count,
  corrective_pct,
  proactive_pct,
  
  -- Maintenance frequency
  ROUND(avg_days_between_maintenance, 1) AS avg_days_between_maintenance,
  
  -- Recency
  last_maintenance_date,
  days_since_last_maintenance,
  
  -- Overall health
  equipment_health_score,
  CASE
    WHEN equipment_health_score >= 80 THEN 'Excellent Condition'
    WHEN equipment_health_score >= 60 THEN 'Good Condition'
    WHEN equipment_health_score >= 40 THEN 'Fair - Monitor Closely'
    ELSE 'Poor - Immediate Attention Required'
  END AS equipment_health_status,
  
  -- Maintenance priority (1-5, 5 = highest)
  CASE
    WHEN risk_level = 'Critical Risk' AND days_since_last_maintenance > 60 THEN 5
    WHEN risk_level = 'Critical Risk' THEN 4
    WHEN risk_level = 'High Risk' AND days_since_last_maintenance > 90 THEN 4
    WHEN risk_level = 'High Risk' THEN 3
    WHEN risk_level = 'Medium Risk' AND days_since_last_maintenance > 120 THEN 3
    WHEN risk_level = 'Medium Risk' THEN 2
    ELSE 1
  END AS maintenance_priority,
  
  -- Recommended actions
  CASE
    WHEN risk_level = 'Critical Risk' AND corrective_pct > 60 THEN 
      'URGENT: Shift to predictive maintenance to prevent failures'
    WHEN risk_level = 'Critical Risk' THEN 
      'URGENT: Schedule immediate inspection and preventive maintenance'
    WHEN risk_level = 'High Risk' AND days_since_last_maintenance > 90 THEN 
      'Schedule maintenance soon - equipment overdue for service'
    WHEN risk_level = 'High Risk' AND corrective_pct > 50 THEN 
      'Increase predictive maintenance to reduce reactive work'
    WHEN avg_downtime_hours > 7 THEN 
      'Investigate root causes of extended downtime'
    WHEN completion_rate_pct < 50 THEN 
      'Address maintenance completion issues (cancellations/delays)'
    WHEN proactive_pct > 70 THEN 
      'Excellent proactive maintenance strategy - continue current approach'
    ELSE 
      'Equipment is stable - maintain current maintenance schedule'
  END AS recommended_action,
  
  -- Next maintenance recommendation
  CASE
    WHEN days_since_last_maintenance IS NULL THEN 'Schedule initial baseline maintenance'
    WHEN days_since_last_maintenance > 90 THEN 'Overdue - schedule immediately'
    WHEN days_since_last_maintenance > 60 THEN 'Due soon - schedule within 2 weeks'
    WHEN days_since_last_maintenance > 30 THEN 'On schedule - monitor'
    ELSE 'Recently serviced'
  END AS next_maintenance_timing

FROM equipment_classification
ORDER BY 
  maintenance_priority DESC,
  equipment_health_score ASC,
  total_maintenance_cost DESC
