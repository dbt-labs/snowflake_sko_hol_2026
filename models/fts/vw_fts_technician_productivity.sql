{{
  config(
    materialized='view',
    tags=['fts', 'energy', 'analytics', 'technician', 'productivity']
  )
}}

/*
  FTS Technician Productivity Analysis
  
  Purpose: Track individual technician performance, workload balance, and
  efficiency to optimize workforce utilization and identify training needs.
  
  Key Metrics:
  - Completion rates per technician
  - Average costs and time efficiency
  - Workload distribution
  - AI summarization time savings
  
  Business Value: Balance workloads across technicians, identify top performers
  for best practice sharing, and target training for underperformers.
*/

WITH base_data AS (
  SELECT
    technician_id,
    maintenance_type,
    maintenance_status,
    failure_rate,
    maintenance_cost,
    downtime_hours,
    summarization_time_saved,
    equipment_id,
    log_date
  FROM {{ source('fts', 'fts_records') }}
),

technician_metrics AS (
  SELECT
    technician_id,
    
    -- Workload volume
    COUNT(*) AS total_assignments,
    COUNT(DISTINCT equipment_id) AS equipment_serviced,
    
    -- Status distribution
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END) AS completed_work,
    COUNT(CASE WHEN maintenance_status = 'In Progress' THEN 1 END) AS in_progress_work,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END) AS delayed_work,
    COUNT(CASE WHEN maintenance_status = 'Cancelled' THEN 1 END) AS cancelled_work,
    
    -- Performance rates
    COUNT(CASE WHEN maintenance_status = 'Completed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS completion_rate,
    COUNT(CASE WHEN maintenance_status = 'Delayed' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS delay_rate,
    
    -- Cost metrics
    SUM(maintenance_cost) AS total_cost_generated,
    AVG(maintenance_cost) AS avg_cost_per_job,
    
    -- Time efficiency
    SUM(downtime_hours) AS total_downtime_caused,
    AVG(downtime_hours) AS avg_downtime_per_job,
    
    -- Equipment reliability impact
    AVG(failure_rate) AS avg_equipment_failure_rate,
    AVG(CASE WHEN maintenance_status = 'Completed' THEN failure_rate END) 
      AS avg_failure_rate_post_service,
    
    -- AI efficiency gains
    SUM(summarization_time_saved) AS total_time_saved,
    AVG(summarization_time_saved) AS avg_time_saved_per_log,
    
    -- Maintenance type expertise
    COUNT(CASE WHEN maintenance_type = 'Preventive Maintenance' THEN 1 END) AS preventive_jobs,
    COUNT(CASE WHEN maintenance_type = 'Predictive Maintenance' THEN 1 END) AS predictive_jobs,
    COUNT(CASE WHEN maintenance_type = 'Corrective Maintenance' THEN 1 END) AS corrective_jobs,
    COUNT(CASE WHEN maintenance_type = 'Condition-Based Maintenance' THEN 1 END) AS condition_based_jobs,
    COUNT(CASE WHEN maintenance_type = 'Reliability-Centered Maintenance' THEN 1 END) AS rcm_jobs,
    
    -- Work span
    MIN(log_date) AS first_assignment_date,
    MAX(log_date) AS last_assignment_date
    
  FROM base_data
  GROUP BY technician_id
),

technician_rankings AS (
  SELECT
    technician_id,
    ROW_NUMBER() OVER (ORDER BY completion_rate DESC) AS completion_rank,
    ROW_NUMBER() OVER (ORDER BY avg_cost_per_job ASC) AS cost_efficiency_rank,
    ROW_NUMBER() OVER (ORDER BY avg_downtime_per_job ASC) AS downtime_efficiency_rank,
    ROW_NUMBER() OVER (ORDER BY avg_equipment_failure_rate ASC) AS reliability_rank,
    ROW_NUMBER() OVER (ORDER BY total_assignments DESC) AS workload_rank
  FROM technician_metrics
),

technician_performance AS (
  SELECT
    tm.technician_id,
    
    -- Workload
    tm.total_assignments,
    tm.equipment_serviced,
    ROUND(tm.total_assignments::FLOAT / 
      (SELECT AVG(total_assignments) FROM technician_metrics), 2) 
      AS workload_vs_avg,
    
    -- Status breakdown
    tm.completed_work,
    tm.in_progress_work,
    tm.delayed_work,
    tm.cancelled_work,
    
    -- Performance metrics
    ROUND(tm.completion_rate * 100, 2) AS completion_rate_pct,
    ROUND(tm.delay_rate * 100, 2) AS delay_rate_pct,
    
    -- Cost metrics
    ROUND(tm.total_cost_generated, 2) AS total_cost_generated,
    ROUND(tm.avg_cost_per_job, 2) AS avg_cost_per_job,
    ROUND(tm.avg_cost_per_job / 
      (SELECT AVG(avg_cost_per_job) FROM technician_metrics), 2) 
      AS cost_vs_avg,
    
    -- Time efficiency
    tm.total_downtime_caused,
    ROUND(tm.avg_downtime_per_job, 1) AS avg_downtime_per_job,
    ROUND(tm.avg_downtime_per_job / 
      (SELECT AVG(avg_downtime_per_job) FROM technician_metrics), 2) 
      AS downtime_vs_avg,
    
    -- Equipment reliability
    ROUND(tm.avg_equipment_failure_rate, 3) AS avg_equipment_failure_rate,
    ROUND(tm.avg_failure_rate_post_service, 3) AS avg_failure_rate_post_service,
    
    -- AI productivity gains
    tm.total_time_saved,
    ROUND(tm.avg_time_saved_per_log, 1) AS avg_time_saved_per_log,
    ROUND(tm.total_time_saved::FLOAT / NULLIF(tm.total_assignments, 0), 1) 
      AS time_saved_per_assignment,
    
    -- Expertise profile
    tm.preventive_jobs,
    tm.predictive_jobs,
    tm.corrective_jobs,
    tm.condition_based_jobs,
    tm.rcm_jobs,
    
    -- Proactive work percentage
    ROUND((tm.preventive_jobs + tm.predictive_jobs)::FLOAT / 
      NULLIF(tm.total_assignments, 0) * 100, 1) AS proactive_work_pct,
    
    -- Most common work type
    CASE
      WHEN tm.preventive_jobs >= GREATEST(tm.predictive_jobs, tm.corrective_jobs, 
           tm.condition_based_jobs, tm.rcm_jobs) THEN 'Preventive Maintenance'
      WHEN tm.predictive_jobs >= GREATEST(tm.preventive_jobs, tm.corrective_jobs, 
           tm.condition_based_jobs, tm.rcm_jobs) THEN 'Predictive Maintenance'
      WHEN tm.corrective_jobs >= GREATEST(tm.preventive_jobs, tm.predictive_jobs, 
           tm.condition_based_jobs, tm.rcm_jobs) THEN 'Corrective Maintenance'
      WHEN tm.condition_based_jobs >= GREATEST(tm.preventive_jobs, tm.predictive_jobs, 
           tm.corrective_jobs, tm.rcm_jobs) THEN 'Condition-Based Maintenance'
      ELSE 'Reliability-Centered Maintenance'
    END AS primary_expertise,
    
    -- Experience metrics
    tm.first_assignment_date,
    tm.last_assignment_date,
    DATEDIFF('day', tm.first_assignment_date, tm.last_assignment_date) AS days_active,
    
    -- Rankings
    tr.completion_rank,
    tr.cost_efficiency_rank,
    tr.downtime_efficiency_rank,
    tr.reliability_rank,
    tr.workload_rank,
    
    -- Overall productivity score (0-100)
    ROUND(
      (
        -- Completion rate (30 points)
        (tm.completion_rate * 30) +
        -- Low delay rate (20 points)
        ((1 - tm.delay_rate) * 20) +
        -- Cost efficiency (20 points)
        (LEAST((SELECT AVG(avg_cost_per_job) FROM technician_metrics) / 
          NULLIF(tm.avg_cost_per_job, 0), 2) * 10) +
        -- Time efficiency (15 points)
        (LEAST((SELECT AVG(avg_downtime_per_job) FROM technician_metrics) / 
          NULLIF(tm.avg_downtime_per_job, 0), 2) * 7.5) +
        -- Equipment reliability (15 points)
        ((1 - tm.avg_equipment_failure_rate) * 15)
      ), 0
    ) AS productivity_score
    
  FROM technician_metrics tm
  JOIN technician_rankings tr ON tm.technician_id = tr.technician_id
)

SELECT
  technician_id,
  
  -- Workload
  total_assignments,
  equipment_serviced,
  workload_vs_avg,
  CASE
    WHEN workload_vs_avg >= 1.3 THEN 'Overloaded'
    WHEN workload_vs_avg >= 1.1 THEN 'Above Average Load'
    WHEN workload_vs_avg >= 0.9 THEN 'Balanced Load'
    WHEN workload_vs_avg >= 0.7 THEN 'Below Average Load'
    ELSE 'Underutilized'
  END AS workload_status,
  
  -- Work status
  completed_work,
  in_progress_work,
  delayed_work,
  cancelled_work,
  
  -- Performance
  completion_rate_pct,
  delay_rate_pct,
  
  -- Cost metrics
  total_cost_generated,
  avg_cost_per_job,
  cost_vs_avg,
  
  -- Time metrics
  total_downtime_caused,
  avg_downtime_per_job,
  downtime_vs_avg,
  
  -- Reliability impact
  avg_equipment_failure_rate,
  avg_failure_rate_post_service,
  
  -- AI efficiency
  total_time_saved,
  avg_time_saved_per_log,
  time_saved_per_assignment,
  
  -- Expertise
  preventive_jobs,
  predictive_jobs,
  corrective_jobs,
  condition_based_jobs,
  rcm_jobs,
  proactive_work_pct,
  primary_expertise,
  
  -- Experience
  first_assignment_date,
  last_assignment_date,
  days_active,
  
  -- Rankings (1 = best)
  completion_rank,
  cost_efficiency_rank,
  downtime_efficiency_rank,
  reliability_rank,
  workload_rank,
  
  -- Overall assessment
  productivity_score,
  CASE
    WHEN productivity_score >= 80 THEN 'Top Performer'
    WHEN productivity_score >= 65 THEN 'Strong Performer'
    WHEN productivity_score >= 50 THEN 'Average Performer'
    ELSE 'Needs Development'
  END AS performance_tier,
  
  -- Development recommendations
  CASE
    WHEN completion_rate_pct < 50 THEN 
      'Priority: Improve completion rate through workload adjustment or training'
    WHEN delay_rate_pct > 30 THEN 
      'Priority: Address delays - investigate causes and provide support'
    WHEN avg_downtime_per_job > 7 THEN 
      'Priority: Improve time efficiency - review procedures and techniques'
    WHEN avg_equipment_failure_rate > 0.7 THEN 
      'Priority: Focus on quality - equipment shows high failure rates post-service'
    WHEN workload_vs_avg < 0.7 THEN 
      'Opportunity: Can handle additional assignments'
    WHEN workload_vs_avg > 1.3 THEN 
      'Action: Redistribute workload to prevent burnout'
    WHEN productivity_score >= 80 THEN 
      'Recognition: Excellent performance - consider for mentorship role'
    WHEN proactive_work_pct < 40 THEN 
      'Training: Increase predictive/preventive maintenance skills'
    ELSE 
      'Status: Performing adequately - continue current development path'
  END AS recommendation,
  
  -- Career development path
  CASE
    WHEN productivity_score >= 80 AND proactive_work_pct >= 60 THEN 
      'Senior Technician / Mentor'
    WHEN productivity_score >= 65 AND rcm_jobs > corrective_jobs THEN 
      'Specialist - Advanced Maintenance'
    WHEN productivity_score >= 65 THEN 
      'Senior Technician Track'
    WHEN days_active >= 365 AND productivity_score < 50 THEN 
      'Requires Performance Improvement Plan'
    WHEN days_active < 90 THEN 
      'Early Career - Monitor Progress'
    ELSE 
      'Standard Development Track'
  END AS career_development_path

FROM technician_performance
ORDER BY productivity_score DESC, total_assignments DESC
