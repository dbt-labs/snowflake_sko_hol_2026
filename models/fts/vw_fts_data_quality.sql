{{
  config(
    materialized='view',
    tags=['fts', 'energy', 'data_quality', 'monitoring']
  )
}}

/*
  FTS Data Quality Monitoring
  
  Purpose: Monitor data completeness, consistency, and detect anomalies in
  field service maintenance logs to ensure reliable analytics.
  
  Key Metrics:
  - Null percentage for critical fields
  - Value range validation
  - Duplicate detection
  - Data consistency checks
  
  Business Value: Maintain high-quality data foundation for maintenance
  optimization, equipment reliability tracking, and workforce management.
*/

WITH base_data AS (
  SELECT
    record_id,
    log_date,
    technician_id,
    log_description,
    equipment_id,
    maintenance_type,
    maintenance_status,
    erp_order_id,
    customer_id,
    summarized_log,
    failure_rate,
    maintenance_cost,
    downtime_hours,
    summarization_time_saved
  FROM {{ source('fts', 'fts_records') }}
),

completeness_metrics AS (
  SELECT
    COUNT(*) AS total_records,
    
    -- Null checks for critical fields
    COUNT(CASE WHEN record_id IS NULL THEN 1 END) AS null_record_id,
    COUNT(CASE WHEN log_date IS NULL THEN 1 END) AS null_log_date,
    COUNT(CASE WHEN technician_id IS NULL THEN 1 END) AS null_technician_id,
    COUNT(CASE WHEN equipment_id IS NULL THEN 1 END) AS null_equipment_id,
    COUNT(CASE WHEN maintenance_type IS NULL THEN 1 END) AS null_maintenance_type,
    COUNT(CASE WHEN maintenance_status IS NULL THEN 1 END) AS null_maintenance_status,
    COUNT(CASE WHEN failure_rate IS NULL THEN 1 END) AS null_failure_rate,
    COUNT(CASE WHEN maintenance_cost IS NULL THEN 1 END) AS null_maintenance_cost,
    COUNT(CASE WHEN downtime_hours IS NULL THEN 1 END) AS null_downtime_hours,
    COUNT(CASE WHEN log_description IS NULL THEN 1 END) AS null_log_description,
    COUNT(CASE WHEN summarized_log IS NULL THEN 1 END) AS null_summarized_log,
    
    -- Completeness percentages
    100.0 - (COUNT(CASE WHEN record_id IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS record_id_completeness,
    100.0 - (COUNT(CASE WHEN log_date IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS log_date_completeness,
    100.0 - (COUNT(CASE WHEN maintenance_type IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS maintenance_type_completeness
      
  FROM base_data
),

duplicate_detection AS (
  SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT record_id) AS unique_record_ids,
    COUNT(*) - COUNT(DISTINCT record_id) AS duplicate_record_ids,
    COUNT(DISTINCT technician_id) AS unique_technicians,
    COUNT(DISTINCT equipment_id) AS unique_equipment,
    COUNT(DISTINCT erp_order_id) AS unique_erp_orders,
    COUNT(DISTINCT customer_id) AS unique_customers
  FROM base_data
),

value_validation AS (
  SELECT
    -- Out of range values
    COUNT(CASE WHEN failure_rate < 0 OR failure_rate > 1 THEN 1 END) AS invalid_failure_rates,
    COUNT(CASE WHEN maintenance_cost < 0 THEN 1 END) AS negative_costs,
    COUNT(CASE WHEN maintenance_cost > 10000 THEN 1 END) AS extreme_high_costs,
    COUNT(CASE WHEN downtime_hours < 0 THEN 1 END) AS negative_downtime,
    COUNT(CASE WHEN downtime_hours > 24 THEN 1 END) AS extreme_long_downtime,
    COUNT(CASE WHEN summarization_time_saved < 0 THEN 1 END) AS negative_time_saved,
    COUNT(CASE WHEN summarization_time_saved > 10 THEN 1 END) AS extreme_time_saved,
    
    -- Logical inconsistencies
    COUNT(CASE WHEN maintenance_cost = 0 AND maintenance_status = 'Completed' THEN 1 END) 
      AS zero_cost_completed,
    COUNT(CASE WHEN downtime_hours = 0 AND maintenance_status = 'Completed' THEN 1 END) 
      AS zero_downtime_completed,
    COUNT(CASE WHEN failure_rate > 0.9 AND maintenance_status = 'Completed' THEN 1 END) 
      AS high_failure_post_maintenance,
    
    -- Missing log descriptions
    COUNT(CASE WHEN log_description IS NULL OR LENGTH(log_description) < 10 THEN 1 END) 
      AS insufficient_log_descriptions,
    COUNT(CASE WHEN summarized_log IS NULL OR LENGTH(summarized_log) < 5 THEN 1 END) 
      AS insufficient_summarized_logs
    
  FROM base_data
),

date_metrics AS (
  SELECT
    MIN(TO_DATE(log_date)) AS earliest_log_date,
    MAX(TO_DATE(log_date)) AS latest_log_date,
    COUNT(DISTINCT TO_DATE(log_date)) AS unique_log_days,
    COUNT(CASE WHEN TO_DATE(log_date) > CURRENT_DATE() THEN 1 END) AS future_dated_logs
  FROM base_data
),

categorical_consistency AS (
  SELECT
    COUNT(DISTINCT maintenance_type) AS unique_maintenance_types,
    COUNT(DISTINCT maintenance_status) AS unique_maintenance_statuses,
    
    -- Expected vs actual category counts
    CASE 
      WHEN COUNT(DISTINCT maintenance_status) != 5 THEN 'Unexpected status values'
      ELSE 'Valid'
    END AS status_validation,
    CASE 
      WHEN COUNT(DISTINCT maintenance_type) != 5 THEN 'Unexpected type values'
      ELSE 'Valid'
    END AS type_validation
    
  FROM base_data
)

SELECT
  -- Record counts
  cm.total_records,
  
  -- Completeness metrics
  cm.null_record_id,
  cm.null_log_date,
  cm.null_technician_id,
  cm.null_equipment_id,
  cm.null_maintenance_type,
  cm.null_maintenance_status,
  cm.null_failure_rate,
  cm.null_maintenance_cost,
  cm.null_downtime_hours,
  cm.null_log_description,
  cm.null_summarized_log,
  
  ROUND(cm.record_id_completeness, 2) AS record_id_completeness_pct,
  ROUND(cm.log_date_completeness, 2) AS log_date_completeness_pct,
  ROUND(cm.maintenance_type_completeness, 2) AS maintenance_type_completeness_pct,
  
  -- Overall completeness score
  ROUND(
    (cm.record_id_completeness + cm.log_date_completeness + cm.maintenance_type_completeness) / 3.0, 
    2
  ) AS overall_completeness_score,
  
  -- Duplicate detection
  dd.unique_record_ids,
  dd.duplicate_record_ids,
  dd.unique_technicians,
  dd.unique_equipment,
  dd.unique_erp_orders,
  dd.unique_customers,
  
  ROUND(dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 100, 2) AS duplicate_pct,
  
  -- Value validation issues
  vv.invalid_failure_rates,
  vv.negative_costs,
  vv.extreme_high_costs,
  vv.negative_downtime,
  vv.extreme_long_downtime,
  vv.negative_time_saved,
  vv.extreme_time_saved,
  
  -- Logical consistency issues
  vv.zero_cost_completed,
  vv.zero_downtime_completed,
  vv.high_failure_post_maintenance,
  vv.insufficient_log_descriptions,
  vv.insufficient_summarized_logs,
  
  -- Total validation issues
  (vv.invalid_failure_rates + vv.negative_costs + vv.negative_downtime +
   vv.zero_cost_completed + vv.insufficient_log_descriptions) AS total_validation_issues,
  
  -- Date range metrics
  dm.earliest_log_date,
  dm.latest_log_date,
  DATEDIFF('day', dm.earliest_log_date, dm.latest_log_date) AS log_date_range_days,
  dm.unique_log_days,
  dm.future_dated_logs,
  
  -- Date freshness
  DATEDIFF('day', dm.latest_log_date, CURRENT_DATE()) AS days_since_latest_log,
  CASE
    WHEN DATEDIFF('day', dm.latest_log_date, CURRENT_DATE()) <= 1 THEN 'Current (< 1 day)'
    WHEN DATEDIFF('day', dm.latest_log_date, CURRENT_DATE()) <= 7 THEN 'Recent (< 1 week)'
    WHEN DATEDIFF('day', dm.latest_log_date, CURRENT_DATE()) <= 30 THEN 'Aging (< 1 month)'
    ELSE 'Stale (> 1 month)'
  END AS data_freshness_status,
  
  -- Categorical consistency
  cc.unique_maintenance_types,
  cc.unique_maintenance_statuses,
  cc.status_validation,
  cc.type_validation,
  
  -- Overall data quality score (0-100)
  ROUND(
    100 - (
      -- Completeness impact (40 points)
      ((cm.null_log_date + cm.null_maintenance_type + cm.null_equipment_id)::FLOAT / 
        NULLIF(cm.total_records, 0) * 40) +
      -- Duplicate impact (20 points)
      (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
      -- Validation issues impact (40 points)
      ((vv.invalid_failure_rates + vv.negative_costs + vv.negative_downtime + 
        vv.insufficient_log_descriptions)::FLOAT / NULLIF(cm.total_records, 0) * 40)
    ), 0
  ) AS overall_data_quality_score,
  
  -- Quality status
  CASE
    WHEN ROUND(
      100 - (
        ((cm.null_log_date + cm.null_maintenance_type + cm.null_equipment_id)::FLOAT / 
          NULLIF(cm.total_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.invalid_failure_rates + vv.negative_costs + vv.negative_downtime + 
          vv.insufficient_log_descriptions)::FLOAT / NULLIF(cm.total_records, 0) * 40)
      ), 0
    ) >= 95 THEN 'Excellent'
    WHEN ROUND(
      100 - (
        ((cm.null_log_date + cm.null_maintenance_type + cm.null_equipment_id)::FLOAT / 
          NULLIF(cm.total_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.invalid_failure_rates + vv.negative_costs + vv.negative_downtime + 
          vv.insufficient_log_descriptions)::FLOAT / NULLIF(cm.total_records, 0) * 40)
      ), 0
    ) >= 80 THEN 'Good'
    WHEN ROUND(
      100 - (
        ((cm.null_log_date + cm.null_maintenance_type + cm.null_equipment_id)::FLOAT / 
          NULLIF(cm.total_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.invalid_failure_rates + vv.negative_costs + vv.negative_downtime + 
          vv.insufficient_log_descriptions)::FLOAT / NULLIF(cm.total_records, 0) * 40)
      ), 0
    ) >= 60 THEN 'Fair - Monitor Closely'
    ELSE 'Poor - Immediate Action Required'
  END AS data_quality_status,
  
  -- Recommended actions
  CASE
    WHEN (cm.null_log_date + cm.null_maintenance_type + cm.null_equipment_id) > 0 
      THEN 'Address missing critical fields in source system'
    WHEN dd.duplicate_record_ids > 0 
      THEN 'Investigate and resolve duplicate records'
    WHEN vv.invalid_failure_rates > 0 
      THEN 'Fix invalid failure rate values (must be 0-1)'
    WHEN vv.negative_costs + vv.negative_downtime > 0 
      THEN 'Correct negative values in cost and downtime fields'
    WHEN vv.insufficient_log_descriptions > cm.total_records * 0.1 
      THEN 'Improve log description quality and completeness'
    WHEN dm.future_dated_logs > 0 
      THEN 'Investigate and correct future-dated log entries'
    WHEN DATEDIFF('day', dm.latest_log_date, CURRENT_DATE()) > 7 
      THEN 'Data appears stale - check data ingestion pipeline'
    WHEN cc.status_validation != 'Valid' OR cc.type_validation != 'Valid' 
      THEN 'Review categorical value consistency'
    ELSE 'Data quality is healthy - continue monitoring'
  END AS recommended_action

FROM completeness_metrics cm
CROSS JOIN duplicate_detection dd
CROSS JOIN value_validation vv
CROSS JOIN date_metrics dm
CROSS JOIN categorical_consistency cc
