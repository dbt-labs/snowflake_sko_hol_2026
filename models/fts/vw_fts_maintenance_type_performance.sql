{{
  config(
    materialized='view',
    tags=['fts', 'energy', 'analytics', 'maintenance', 'strategy']
  )
}}

/*
  FTS Maintenance Type Performance
  
  Purpose: Compare the effectiveness of different maintenance strategies
  (Preventive, Predictive, Corrective, Condition-Based, Reliability-Centered)
  to optimize the maintenance strategy mix.
  
  Key Metrics:
  - Completion rates by maintenance type
  - Cost efficiency per strategy
  - Downtime reduction effectiveness
  - Equipment reliability impact
  
  Business Value: Determine the optimal mix of maintenance strategies to
  maximize reliability while minimizing costs and downtime.
*/

WITH base_data AS (
  SELECT
    maintenance_type,
    maintenance_status,
    failure_rate,
    maintenance_cost,
    downtime_hours,
    equipment_id,
    log_date
  FROM {{ source('fts', 'fts_records') }}
),

maintenance_type_metrics AS (
  SELECT
    maintenance_type,
    
    -- Volume metrics
    COUNT(*) AS total_activities,
    COUNT(DISTINCT equipment_id) AS equipment_count,
    
    -- Status distribution
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END) AS completed,
    COUNT(CASE WHEN maintenance_status = 'In Progress' THEN 1 END) AS in_progress,
    COUNT(CASE WHEN maintenance_status = 'Scheduled' THEN 1 END) AS scheduled,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END) AS delayed,
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END) AS cancelled,
    
    -- Performance rates
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS completion_rate,
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS delay_rate,
    
    -- Cost metrics
    SUM(maintenance_cost) AS total_cost,
    AVG(maintenance_cost) AS avg_cost,
    MIN(maintenance_cost) AS min_cost,
    MAX(maintenance_cost) AS max_cost,
    STDDEV(maintenance_cost) AS cost_stddev,
    
    -- Downtime metrics
    SUM(downtime_hours) AS total_downtime,
    AVG(downtime_hours) AS avg_downtime,
    MIN(downtime_hours) AS min_downtime,
    MAX(downtime_hours) AS max_downtime,
    
    -- Equipment reliability impact
    AVG(failure_rate) AS avg_failure_rate,
    AVG(CASE WHEN maintenance_status = 'Completed' THEN failure_rate END) 
      AS avg_failure_rate_completed,
    
    -- Cost efficiency
    SUM(maintenance_cost) / NULLIF(SUM(downtime_hours), 0) AS cost_per_downtime_hour,
    SUM(maintenance_cost) / NULLIF(COUNT(DISTINCT equipment_id), 0) AS cost_per_equipment
    
  FROM base_data
  GROUP BY maintenance_type
),

type_rankings AS (
  SELECT
    maintenance_type,
    ROW_NUMBER() OVER (ORDER BY completion_rate DESC) AS completion_rank,
    ROW_NUMBER() OVER (ORDER BY avg_cost ASC) AS cost_efficiency_rank,
    ROW_NUMBER() OVER (ORDER BY avg_downtime ASC) AS downtime_reduction_rank,
    ROW_NUMBER() OVER (ORDER BY avg_failure_rate ASC) AS reliability_improvement_rank
  FROM maintenance_type_metrics
),

type_performance AS (
  SELECT
    mtm.maintenance_type,
    
    -- Volume
    mtm.total_activities,
    mtm.equipment_count,
    ROUND(mtm.total_activities::FLOAT / 
      (SELECT SUM(total_activities) FROM maintenance_type_metrics) * 100, 1) 
      AS pct_of_total_activities,
    
    -- Status breakdown
    mtm.completed,
    mtm.in_progress,
    mtm.scheduled,
    mtm.delayed,
    mtm.cancelled,
    
    -- Performance rates
    ROUND(mtm.completion_rate * 100, 2) AS completion_rate_pct,
    ROUND(mtm.cancellation_rate * 100, 2) AS cancellation_rate_pct,
    ROUND(mtm.delay_rate * 100, 2) AS delay_rate_pct,
    
    -- Cost analysis
    ROUND(mtm.total_cost, 2) AS total_cost,
    ROUND(mtm.avg_cost, 2) AS avg_cost,
    ROUND(mtm.min_cost, 2) AS min_cost,
    ROUND(mtm.max_cost, 2) AS max_cost,
    ROUND(mtm.cost_stddev, 2) AS cost_variability,
    ROUND(mtm.cost_per_equipment, 2) AS cost_per_equipment,
    
    -- Downtime analysis
    mtm.total_downtime,
    ROUND(mtm.avg_downtime, 1) AS avg_downtime,
    mtm.min_downtime,
    mtm.max_downtime,
    
    -- Reliability impact
    ROUND(mtm.avg_failure_rate, 3) AS avg_failure_rate,
    ROUND(mtm.avg_failure_rate_completed, 3) AS avg_failure_rate_after_completion,
    
    -- Cost efficiency
    ROUND(mtm.cost_per_downtime_hour, 2) AS cost_per_downtime_hour,
    
    -- Rankings
    tr.completion_rank,
    tr.cost_efficiency_rank,
    tr.downtime_reduction_rank,
    tr.reliability_improvement_rank,
    
    -- Overall effectiveness score (0-100)
    ROUND(
      (
        -- Completion rate (30 points)
        (mtm.completion_rate * 30) +
        -- Cost efficiency (25 points) - lower cost is better
        ((1 - (mtm.avg_cost - (SELECT MIN(avg_cost) FROM maintenance_type_metrics)) / 
          NULLIF((SELECT MAX(avg_cost) - MIN(avg_cost) FROM maintenance_type_metrics), 0)) * 25) +
        -- Downtime reduction (25 points) - lower downtime is better
        ((1 - (mtm.avg_downtime - (SELECT MIN(avg_downtime) FROM maintenance_type_metrics)) / 
          NULLIF((SELECT MAX(avg_downtime) - MIN(avg_downtime) FROM maintenance_type_metrics), 0)) * 25) +
        -- Reliability improvement (20 points) - lower failure rate is better
        ((1 - mtm.avg_failure_rate) * 20)
      ), 0
    ) AS effectiveness_score
    
  FROM maintenance_type_metrics mtm
  JOIN type_rankings tr ON mtm.maintenance_type = tr.maintenance_type
)

SELECT
  maintenance_type,
  
  -- Volume and share
  total_activities,
  equipment_count,
  pct_of_total_activities,
  
  -- Status breakdown
  completed,
  in_progress,
  scheduled,
  delayed,
  cancelled,
  
  -- Performance metrics
  completion_rate_pct,
  cancellation_rate_pct,
  delay_rate_pct,
  
  -- Cost metrics
  total_cost,
  avg_cost,
  min_cost,
  max_cost,
  cost_variability,
  cost_per_equipment,
  cost_per_downtime_hour,
  
  -- Downtime metrics
  total_downtime,
  avg_downtime,
  min_downtime,
  max_downtime,
  
  -- Reliability impact
  avg_failure_rate,
  avg_failure_rate_after_completion,
  
  -- Performance rankings (1 = best)
  completion_rank,
  cost_efficiency_rank,
  downtime_reduction_rank,
  reliability_improvement_rank,
  
  -- Overall assessment
  effectiveness_score,
  CASE
    WHEN effectiveness_score >= 75 THEN 'Highly Effective'
    WHEN effectiveness_score >= 60 THEN 'Effective'
    WHEN effectiveness_score >= 45 THEN 'Moderately Effective'
    ELSE 'Needs Optimization'
  END AS effectiveness_rating,
  
  -- Strategy classification
  CASE
    WHEN maintenance_type IN ('Preventive Maintenance', 'Predictive Maintenance') 
      THEN 'Proactive Strategy'
    WHEN maintenance_type = 'Corrective Maintenance' 
      THEN 'Reactive Strategy'
    ELSE 'Advanced Strategy'
  END AS strategy_category,
  
  -- ROI indicator (effectiveness relative to cost)
  ROUND(effectiveness_score / NULLIF(avg_cost, 0) * 100, 2) AS roi_indicator,
  
  -- Recommendations
  CASE
    WHEN maintenance_type = 'Corrective Maintenance' AND avg_failure_rate > 0.6 THEN
      'High reactive costs - shift more work to predictive/preventive strategies'
    WHEN maintenance_type = 'Predictive Maintenance' AND completion_rate_pct < 60 THEN
      'Low completion rate - investigate scheduling and resource constraints'
    WHEN maintenance_type = 'Preventive Maintenance' AND avg_downtime > 6 THEN
      'High downtime - optimize preventive procedures for efficiency'
    WHEN cancellation_rate_pct > 25 THEN
      'High cancellation rate - improve work order planning and coordination'
    WHEN effectiveness_score >= 75 THEN
      'Excellent performance - use as model for other maintenance types'
    WHEN cost_per_downtime_hour > 100 THEN
      'High cost per downtime hour - review cost structure and efficiency'
    ELSE
      'Performance is adequate - focus on continuous improvement'
  END AS recommendation,
  
  -- Strategic value
  CASE
    WHEN maintenance_type IN ('Predictive Maintenance', 'Condition-Based Maintenance') 
      AND avg_failure_rate < 0.4 THEN 'High Strategic Value - Prevents Failures'
    WHEN maintenance_type = 'Preventive Maintenance' 
      AND completion_rate_pct > 75 THEN 'High Strategic Value - Reliable Execution'
    WHEN maintenance_type = 'Reliability-Centered Maintenance' 
      AND avg_failure_rate < 0.5 THEN 'High Strategic Value - Advanced Approach'
    WHEN maintenance_type = 'Corrective Maintenance' 
      THEN 'Necessary But Costly - Minimize When Possible'
    ELSE 'Medium Strategic Value'
  END AS strategic_value_assessment

FROM type_performance
ORDER BY effectiveness_score DESC, avg_cost ASC
