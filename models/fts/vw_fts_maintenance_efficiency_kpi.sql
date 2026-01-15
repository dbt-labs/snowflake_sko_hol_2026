{{
  config(
    materialized='view',
    tags=['fts', 'energy', 'analytics', 'maintenance', 'kpi']
  )
}}

/*
  FTS Maintenance Efficiency KPI Dashboard
  
  Purpose: Executive-level metrics tracking the effectiveness of field service
  maintenance operations across all maintenance types and equipment.
  
  Key Metrics:
  - Maintenance completion rates
  - Average costs and downtime by maintenance type
  - AI summarization time savings
  - Overall operational efficiency
  
  Business Value: Optimize maintenance strategies, reduce costs, and minimize
  equipment downtime through data-driven insights.
*/

WITH base_data AS (
  SELECT
    record_id,
    log_date,
    technician_id,
    equipment_id,
    customer_id,
    maintenance_type,
    maintenance_status,
    failure_rate,
    maintenance_cost,
    downtime_hours,
    summarization_time_saved
  FROM {{ source('fts', 'fts_records') }}
),

overall_metrics AS (
  SELECT
    -- Volume metrics
    COUNT(*) AS total_maintenance_activities,
    COUNT(DISTINCT equipment_id) AS unique_equipment_serviced,
    COUNT(DISTINCT technician_id) AS active_technicians,
    COUNT(DISTINCT customer_id) AS customers_served,
    
    -- Status distribution
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END) AS completed_activities,
    COUNT(CASE WHEN maintenance_status = 'In Progress' THEN 1 END) AS in_progress_activities,
    COUNT(CASE WHEN maintenance_status = 'Scheduled' THEN 1 END) AS scheduled_activities,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END) AS delayed_activities,
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END) AS cancelled_activities,
    
    -- Completion rate
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS completion_rate,
    
    -- Cancellation and delay rates
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS delay_rate,
    
    -- Cost metrics
    SUM(maintenance_cost) AS total_maintenance_cost,
    AVG(maintenance_cost) AS avg_maintenance_cost,
    STDDEV(maintenance_cost) AS stddev_maintenance_cost,
    
    -- Downtime metrics
    SUM(downtime_hours) AS total_downtime_hours,
    AVG(downtime_hours) AS avg_downtime_hours,
    
    -- Equipment reliability
    AVG(failure_rate) AS avg_failure_rate,
    COUNT(CASE WHEN failure_rate > 0.7 THEN 1 END) AS high_risk_equipment_count,
    COUNT(CASE WHEN failure_rate < 0.3 THEN 1 END) AS low_risk_equipment_count,
    
    -- AI efficiency gains
    SUM(summarization_time_saved) AS total_time_saved_hours,
    AVG(summarization_time_saved) AS avg_time_saved_per_log
    
  FROM base_data
),

maintenance_type_breakdown AS (
  SELECT
    maintenance_type,
    COUNT(*) AS activities,
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS type_completion_rate,
    AVG(maintenance_cost) AS avg_cost,
    AVG(downtime_hours) AS avg_downtime,
    AVG(failure_rate) AS avg_failure_rate
  FROM base_data
  GROUP BY maintenance_type
),

best_performing_type AS (
  SELECT
    maintenance_type,
    type_completion_rate,
    avg_cost,
    avg_downtime
  FROM maintenance_type_breakdown
  ORDER BY type_completion_rate DESC, avg_cost ASC
  LIMIT 1
),

worst_performing_type AS (
  SELECT
    maintenance_type,
    type_completion_rate,
    avg_cost,
    avg_downtime
  FROM maintenance_type_breakdown
  ORDER BY type_completion_rate ASC, avg_cost DESC
  LIMIT 1
)

SELECT
  -- Volume metrics
  om.total_maintenance_activities,
  om.unique_equipment_serviced,
  om.active_technicians,
  om.customers_served,
  
  -- Status distribution
  om.completed_activities,
  om.in_progress_activities,
  om.scheduled_activities,
  om.delayed_activities,
  om.cancelled_activities,
  
  -- Performance rates
  ROUND(om.completion_rate * 100, 2) AS completion_rate_pct,
  ROUND(om.cancellation_rate * 100, 2) AS cancellation_rate_pct,
  ROUND(om.delay_rate * 100, 2) AS delay_rate_pct,
  
  -- Cost analysis
  ROUND(om.total_maintenance_cost, 2) AS total_maintenance_cost,
  ROUND(om.avg_maintenance_cost, 2) AS avg_maintenance_cost,
  ROUND(om.stddev_maintenance_cost, 2) AS cost_variability,
  ROUND(om.total_maintenance_cost / NULLIF(om.unique_equipment_serviced, 0), 2) 
    AS cost_per_equipment,
  
  -- Downtime analysis
  om.total_downtime_hours,
  ROUND(om.avg_downtime_hours, 1) AS avg_downtime_hours,
  ROUND(om.total_downtime_hours / NULLIF(om.unique_equipment_serviced, 0), 1) 
    AS downtime_per_equipment,
  
  -- Reliability metrics
  ROUND(om.avg_failure_rate, 3) AS avg_equipment_failure_rate,
  om.high_risk_equipment_count,
  om.low_risk_equipment_count,
  ROUND(om.high_risk_equipment_count::FLOAT / 
    NULLIF(om.unique_equipment_serviced, 0) * 100, 2) AS high_risk_equipment_pct,
  
  -- AI efficiency
  om.total_time_saved_hours,
  ROUND(om.avg_time_saved_per_log, 1) AS avg_time_saved_per_log,
  ROUND(om.total_time_saved_hours::FLOAT / NULLIF(om.active_technicians, 0), 1) 
    AS time_saved_per_technician,
  
  -- Best performing maintenance type
  bpt.maintenance_type AS best_maintenance_type,
  ROUND(bpt.type_completion_rate * 100, 2) AS best_type_completion_rate_pct,
  ROUND(bpt.avg_cost, 2) AS best_type_avg_cost,
  ROUND(bpt.avg_downtime, 1) AS best_type_avg_downtime,
  
  -- Worst performing maintenance type
  wpt.maintenance_type AS worst_maintenance_type,
  ROUND(wpt.type_completion_rate * 100, 2) AS worst_type_completion_rate_pct,
  ROUND(wpt.avg_cost, 2) AS worst_type_avg_cost,
  ROUND(wpt.avg_downtime, 1) AS worst_type_avg_downtime,
  
  -- Overall efficiency score (0-100)
  ROUND(
    (
      -- Completion rate (30 points)
      (om.completion_rate * 30) +
      -- Low cancellation rate (20 points)
      ((1 - om.cancellation_rate) * 20) +
      -- Low delay rate (20 points)
      ((1 - om.delay_rate) * 20) +
      -- Equipment reliability (20 points)
      ((1 - om.avg_failure_rate) * 20) +
      -- Time savings (10 points)
      (LEAST(om.avg_time_saved_per_log / 5.0, 1) * 10)
    ), 0
  ) AS overall_efficiency_score,
  
  -- Efficiency status
  CASE
    WHEN ROUND(
      (
        (om.completion_rate * 30) +
        ((1 - om.cancellation_rate) * 20) +
        ((1 - om.delay_rate) * 20) +
        ((1 - om.avg_failure_rate) * 20) +
        (LEAST(om.avg_time_saved_per_log / 5.0, 1) * 10)
      ), 0
    ) >= 80 THEN 'Excellent Operations'
    WHEN ROUND(
      (
        (om.completion_rate * 30) +
        ((1 - om.cancellation_rate) * 20) +
        ((1 - om.delay_rate) * 20) +
        ((1 - om.avg_failure_rate) * 20) +
        (LEAST(om.avg_time_saved_per_log / 5.0, 1) * 10)
      ), 0
    ) >= 60 THEN 'Good Operations'
    WHEN ROUND(
      (
        (om.completion_rate * 30) +
        ((1 - om.cancellation_rate) * 20) +
        ((1 - om.delay_rate) * 20) +
        ((1 - om.avg_failure_rate) * 20) +
        (LEAST(om.avg_time_saved_per_log / 5.0, 1) * 10)
      ), 0
    ) >= 40 THEN 'Needs Improvement'
    ELSE 'Critical - Immediate Action Required'
  END AS efficiency_status,
  
  -- Key recommendations
  CASE
    WHEN om.cancellation_rate > 0.25 THEN 
      'High cancellation rate - investigate scheduling and resource allocation'
    WHEN om.delay_rate > 0.25 THEN 
      'High delay rate - improve work order planning and parts availability'
    WHEN om.avg_failure_rate > 0.6 THEN 
      'High equipment failure rates - shift to more predictive maintenance'
    WHEN om.completion_rate < 0.5 THEN 
      'Low completion rate - address technician capacity or process bottlenecks'
    ELSE 
      'Operations are healthy - focus on continuous improvement'
  END AS primary_recommendation

FROM overall_metrics om
CROSS JOIN best_performing_type bpt
CROSS JOIN worst_performing_type wpt
