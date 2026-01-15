-- Construction Data Quality Monitoring
-- Purpose: Monitor data completeness, consistency, and freshness
-- Materialization: View
-- Tags: data_quality, monitoring, construction

WITH source_data AS (
  SELECT
    *
  FROM {{ source('industries_construction', 'CON_RECORDS') }}
  WHERE TRUE  -- No _FIVETRAN_DELETED column in this schema
),

quality_checks AS (
  SELECT
    COUNT(*) AS total_records,
    
    -- Null Checks (Critical Fields)
    SUM(CASE WHEN PROJECT_ID IS NULL THEN 1 ELSE 0 END) AS null_project_id,
    SUM(CASE WHEN TASK_ID IS NULL THEN 1 ELSE 0 END) AS null_task_id,
    SUM(CASE WHEN TASK_STATUS IS NULL THEN 1 ELSE 0 END) AS null_task_status,
    SUM(CASE WHEN SCHEDULED_START_DATE IS NULL THEN 1 ELSE 0 END) AS null_scheduled_start,
    SUM(CASE WHEN SCHEDULED_END_DATE IS NULL THEN 1 ELSE 0 END) AS null_scheduled_end,
    SUM(CASE WHEN ACTUAL_START_DATE IS NULL THEN 1 ELSE 0 END) AS null_actual_start,
    SUM(CASE WHEN ACTUAL_END_DATE IS NULL THEN 1 ELSE 0 END) AS null_actual_end,
    SUM(CASE WHEN PERCENT_COMPLETE IS NULL THEN 1 ELSE 0 END) AS null_percent_complete,
    SUM(CASE WHEN SCHEDULE_PERFORMANCE_INDEX IS NULL THEN 1 ELSE 0 END) AS null_spi,
    SUM(CASE WHEN COST_PERFORMANCE_INDEX IS NULL THEN 1 ELSE 0 END) AS null_cpi,
    SUM(CASE WHEN RISK_SCORE IS NULL THEN 1 ELSE 0 END) AS null_risk_score,
    
    -- Logical Consistency Checks
    SUM(CASE WHEN SCHEDULED_END_DATE < SCHEDULED_START_DATE THEN 1 ELSE 0 END) AS invalid_scheduled_dates,
    SUM(CASE WHEN ACTUAL_END_DATE < ACTUAL_START_DATE THEN 1 ELSE 0 END) AS invalid_actual_dates,
    SUM(CASE WHEN PERCENT_COMPLETE < 0 OR PERCENT_COMPLETE > 100 THEN 1 ELSE 0 END) AS invalid_percent_complete,
    SUM(CASE WHEN RESOURCE_AVAILABILITY < 0 OR RESOURCE_AVAILABILITY > 1 THEN 1 ELSE 0 END) AS invalid_resource_availability,
    SUM(CASE WHEN EQUIPMENT_UTILIZATION_RATE < 0 OR EQUIPMENT_UTILIZATION_RATE > 1 THEN 1 ELSE 0 END) AS invalid_equipment_utilization,
    SUM(CASE WHEN TEMPERATURE_FAHRENHEIT < -50 OR TEMPERATURE_FAHRENHEIT > 150 THEN 1 ELSE 0 END) AS invalid_temperature,
    SUM(CASE WHEN PRECIPITATION_PROBABILITY < 0 OR PRECIPITATION_PROBABILITY > 100 THEN 1 ELSE 0 END) AS invalid_precipitation,
    SUM(CASE WHEN RISK_SCORE < 0 OR RISK_SCORE > 100 THEN 1 ELSE 0 END) AS invalid_risk_score,
    
    -- Business Logic Checks
    SUM(CASE WHEN TASK_STATUS = 'Completed' AND PERCENT_COMPLETE < 100 THEN 1 ELSE 0 END) AS completed_but_incomplete,
    SUM(CASE WHEN TASK_STATUS = 'Not Started' AND PERCENT_COMPLETE > 0 THEN 1 ELSE 0 END) AS not_started_but_has_progress,
    SUM(CASE WHEN TASK_STATUS = 'Completed' AND ACTUAL_END_DATE IS NULL THEN 1 ELSE 0 END) AS completed_missing_end_date,
    SUM(CASE WHEN TASK_STATUS IN ('In Progress', 'Delayed') AND ACTUAL_START_DATE IS NULL THEN 1 ELSE 0 END) AS active_missing_start_date,
    
    -- Duplicate Checks
    COUNT(DISTINCT RECORD_ID) AS distinct_record_ids,
    COUNT(DISTINCT TASK_ID) AS distinct_task_ids,
    COUNT(DISTINCT PROJECT_ID) AS distinct_project_ids,
    
    -- EVM Performance Index Checks (typical range 0.5 - 1.5)
    SUM(CASE WHEN SCHEDULE_PERFORMANCE_INDEX < 0.5 OR SCHEDULE_PERFORMANCE_INDEX > 1.5 THEN 1 ELSE 0 END) AS unusual_spi,
    SUM(CASE WHEN COST_PERFORMANCE_INDEX < 0.5 OR COST_PERFORMANCE_INDEX > 1.5 THEN 1 ELSE 0 END) AS unusual_cpi,
    
    -- Data Freshness
    MAX(DATA_TIMESTAMP) AS latest_timestamp,
    MIN(DATA_TIMESTAMP) AS earliest_timestamp,
    DATEDIFF(day, MIN(DATA_TIMESTAMP), MAX(DATA_TIMESTAMP)) AS data_span_days,
    DATEDIFF(hour, MAX(DATA_TIMESTAMP), CURRENT_TIMESTAMP()) AS hours_since_last_update
    
  FROM source_data
)

SELECT
  -- Record Counts
  total_records,
  distinct_record_ids,
  distinct_task_ids,
  distinct_project_ids,
  (total_records - distinct_record_ids) AS potential_duplicate_records,
  
  -- Null Completeness (percentage of non-null values)
  ROUND((1 - null_project_id::FLOAT / total_records) * 100, 2) AS pct_project_id_complete,
  ROUND((1 - null_task_id::FLOAT / total_records) * 100, 2) AS pct_task_id_complete,
  ROUND((1 - null_task_status::FLOAT / total_records) * 100, 2) AS pct_task_status_complete,
  ROUND((1 - null_scheduled_start::FLOAT / total_records) * 100, 2) AS pct_scheduled_start_complete,
  ROUND((1 - null_scheduled_end::FLOAT / total_records) * 100, 2) AS pct_scheduled_end_complete,
  ROUND((1 - null_actual_start::FLOAT / total_records) * 100, 2) AS pct_actual_start_complete,
  ROUND((1 - null_actual_end::FLOAT / total_records) * 100, 2) AS pct_actual_end_complete,
  ROUND((1 - null_percent_complete::FLOAT / total_records) * 100, 2) AS pct_percent_complete_complete,
  ROUND((1 - null_spi::FLOAT / total_records) * 100, 2) AS pct_spi_complete,
  ROUND((1 - null_cpi::FLOAT / total_records) * 100, 2) AS pct_cpi_complete,
  ROUND((1 - null_risk_score::FLOAT / total_records) * 100, 2) AS pct_risk_score_complete,
  
  -- Data Quality Issues
  invalid_scheduled_dates,
  invalid_actual_dates,
  invalid_percent_complete,
  invalid_resource_availability,
  invalid_equipment_utilization,
  invalid_temperature,
  invalid_precipitation,
  invalid_risk_score,
  unusual_spi,
  unusual_cpi,
  
  -- Business Logic Issues
  completed_but_incomplete,
  not_started_but_has_progress,
  completed_missing_end_date,
  active_missing_start_date,
  
  -- Total Issues
  (
    null_project_id + null_task_id + null_task_status +
    invalid_scheduled_dates + invalid_actual_dates + invalid_percent_complete +
    invalid_resource_availability + invalid_equipment_utilization +
    completed_but_incomplete + not_started_but_has_progress +
    completed_missing_end_date + active_missing_start_date
  ) AS total_quality_issues,
  
  -- Overall Data Quality Score (0-100, higher is better)
  ROUND(
    100 - (
      (
        (null_project_id + null_task_id + null_task_status) * 100.0 / (total_records * 3) * 0.3 +
        (invalid_scheduled_dates + invalid_actual_dates + invalid_percent_complete) * 100.0 / total_records * 0.3 +
        (completed_but_incomplete + not_started_but_has_progress + completed_missing_end_date + active_missing_start_date) * 100.0 / total_records * 0.4
      )
    )
  , 2) AS overall_quality_score,
  
  -- Data Freshness
  latest_timestamp,
  earliest_timestamp,
  data_span_days,
  hours_since_last_update,
  CASE
    WHEN hours_since_last_update <= 24 THEN 'Fresh'
    WHEN hours_since_last_update <= 72 THEN 'Acceptable'
    WHEN hours_since_last_update <= 168 THEN 'Stale'
    ELSE 'Very Stale'
  END AS data_freshness_status
  
FROM quality_checks
