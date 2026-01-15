{{
  config(
    materialized='view',
    tags=['cds', 'healthcare', 'data_quality', 'monitoring']
  )
}}

/*
  CDS Data Quality Monitor
  
  Purpose: Monitor data completeness, freshness, and integrity
  Refresh: Real-time view on source data
  Audience: Data engineers, quality assurance teams
  
  Checks:
  - Field completeness
  - Data freshness
  - Value validation
  - Duplicate detection
*/

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_healthcare', 'cds_records') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

completeness_checks AS (
  SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT PATIENT_ID) AS unique_patients,
    COUNT(DISTINCT RECORD_ID) AS unique_records,
    
    -- Critical Field Completeness
    COUNT(PATIENT_ID) AS patient_id_populated,
    COUNT(DIAGNOSIS) AS diagnosis_populated,
    COUNT(TREATMENT_OUTCOME) AS treatment_outcome_populated,
    COUNT(PATIENT_OUTCOME_SCORE) AS outcome_score_populated,
    COUNT(COST_OF_CARE) AS cost_populated,
    
    -- Calculate Null Percentages
    ROUND((1 - COUNT(PATIENT_ID) / COUNT(*)) * 100, 2) AS patient_id_null_pct,
    ROUND((1 - COUNT(DIAGNOSIS) / COUNT(*)) * 100, 2) AS diagnosis_null_pct,
    ROUND((1 - COUNT(TREATMENT_OUTCOME) / COUNT(*)) * 100, 2) AS treatment_outcome_null_pct,
    ROUND((1 - COUNT(PATIENT_OUTCOME_SCORE) / COUNT(*)) * 100, 2) AS outcome_score_null_pct,
    ROUND((1 - COUNT(COST_OF_CARE) / COUNT(*)) * 100, 2) AS cost_null_pct,
    ROUND((1 - COUNT(MEDICATION_ADHERENCE) / COUNT(*)) * 100, 2) AS adherence_null_pct,
    ROUND((1 - COUNT(TRIAL_STATUS) / COUNT(*)) * 100, 2) AS trial_status_null_pct,
    
    -- Data Freshness
    MAX(_FIVETRAN_SYNCED) AS last_sync_time,
    MIN(_FIVETRAN_SYNCED) AS first_sync_time,
    DATEDIFF('hour', MAX(_FIVETRAN_SYNCED), CURRENT_TIMESTAMP()) AS hours_since_last_sync,
    DATEDIFF('day', MIN(_FIVETRAN_SYNCED), MAX(_FIVETRAN_SYNCED)) AS data_range_days
    
  FROM source_data
),

value_validation AS (
  SELECT
    -- Invalid Score Ranges (should be 0.0 to 1.0)
    COUNT_IF(PATIENT_OUTCOME_SCORE < 0 OR PATIENT_OUTCOME_SCORE > 1) AS invalid_outcome_scores,
    COUNT_IF(READMISSION_RISK < 0 OR READMISSION_RISK > 1) AS invalid_readmission_risk,
    COUNT_IF(MEDICAL_ERROR_RATE < 0 OR MEDICAL_ERROR_RATE > 1) AS invalid_error_rate,
    
    -- Negative Cost Values (should be positive)
    COUNT_IF(COST_OF_CARE < 0) AS negative_care_costs,
    COUNT_IF(MEDICATION_COST < 0) AS negative_medication_costs,
    COUNT_IF(TOTAL_COST_SAVINGS < 0) AS negative_savings,
    
    -- Invalid Length of Stay (should be positive)
    COUNT_IF(LENGTH_OF_STAY < 0) AS negative_length_of_stay,
    COUNT_IF(LENGTH_OF_STAY > 365) AS excessive_length_of_stay,
    
    -- Suspicious High Costs (potential data entry errors)
    COUNT_IF(COST_OF_CARE > 1000000) AS suspiciously_high_costs,
    COUNT_IF(MEDICATION_COST > 50000) AS suspiciously_high_med_costs,
    
    -- Total rows for percentage calculations
    COUNT(*) AS total_records
    
  FROM source_data
),

duplicate_checks AS (
  SELECT
    COUNT(*) - COUNT(DISTINCT RECORD_ID) AS duplicate_record_ids,
    COUNT(*) - COUNT(DISTINCT PATIENT_ID) AS duplicate_patient_ids,
    
    -- Identify exact duplicate rows (excluding Fivetran metadata)
    COUNT(*) - COUNT(DISTINCT 
      CONCAT_WS('|',
        PATIENT_ID,
        DIAGNOSIS,
        TREATMENT_OUTCOME,
        PATIENT_OUTCOME_SCORE,
        COST_OF_CARE
      )
    ) AS potential_duplicate_rows
    
  FROM source_data
),

data_distribution AS (
  SELECT
    -- Count distinct values for key categorical fields
    COUNT(DISTINCT DIAGNOSIS) AS unique_diagnoses,
    COUNT(DISTINCT TREATMENT_PLAN) AS unique_treatment_plans,
    COUNT(DISTINCT TRIAL_STATUS) AS unique_trial_statuses,
    COUNT(DISTINCT PATIENT_SATISFACTION) AS unique_satisfaction_levels,
    COUNT(DISTINCT MEDICATION_ADHERENCE) AS unique_adherence_levels,
    
    -- Outlier Detection
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY COST_OF_CARE) AS cost_95th_percentile,
    MAX(COST_OF_CARE) AS max_cost
    
  FROM source_data
),

quality_score AS (
  SELECT
    cc.total_records,
    
    -- Calculate Overall Completeness Score (0-100)
    ROUND(
      (
        (100 - cc.patient_id_null_pct) * 0.25 +
        (100 - cc.diagnosis_null_pct) * 0.20 +
        (100 - cc.treatment_outcome_null_pct) * 0.20 +
        (100 - cc.outcome_score_null_pct) * 0.15 +
        (100 - cc.cost_null_pct) * 0.10 +
        (100 - cc.adherence_null_pct) * 0.05 +
        (100 - cc.trial_status_null_pct) * 0.05
      ),
      2
    ) AS completeness_score,
    
    -- Calculate Data Validity Score (0-100)
    ROUND(
      (1 - (
        COALESCE(vv.invalid_outcome_scores, 0) +
        COALESCE(vv.invalid_readmission_risk, 0) +
        COALESCE(vv.invalid_error_rate, 0) +
        COALESCE(vv.negative_care_costs, 0) +
        COALESCE(vv.negative_medication_costs, 0) +
        COALESCE(vv.negative_length_of_stay, 0)
      ) / NULLIF(cc.total_records, 0)) * 100,
      2
    ) AS validity_score,
    
    -- Calculate Freshness Score (0-100, decreases with hours since sync)
    ROUND(
      GREATEST(0, 100 - (cc.hours_since_last_sync * 2)),
      2
    ) AS freshness_score
    
  FROM completeness_checks cc
  CROSS JOIN value_validation vv
)

SELECT
  -- Report Metadata
  'CDS Healthcare Data Quality Report' AS report_name,
  CURRENT_TIMESTAMP() AS report_generated_at,
  
  -- Record Counts
  cc.total_records,
  cc.unique_patients,
  cc.unique_records,
  dc.duplicate_record_ids,
  dc.duplicate_patient_ids,
  dc.potential_duplicate_rows,
  
  -- Completeness Metrics
  cc.patient_id_null_pct,
  cc.diagnosis_null_pct,
  cc.treatment_outcome_null_pct,
  cc.outcome_score_null_pct,
  cc.cost_null_pct,
  cc.adherence_null_pct,
  cc.trial_status_null_pct,
  
  -- Validity Issues
  vv.invalid_outcome_scores,
  vv.invalid_readmission_risk,
  vv.invalid_error_rate,
  vv.negative_care_costs,
  vv.negative_medication_costs,
  vv.negative_savings,
  vv.negative_length_of_stay,
  vv.excessive_length_of_stay,
  vv.suspiciously_high_costs,
  vv.suspiciously_high_med_costs,
  
  -- Data Distribution
  dd.unique_diagnoses,
  dd.unique_treatment_plans,
  dd.unique_trial_statuses,
  dd.unique_satisfaction_levels,
  dd.unique_adherence_levels,
  dd.cost_95th_percentile,
  dd.max_cost,
  
  -- Freshness
  cc.last_sync_time,
  cc.first_sync_time,
  cc.hours_since_last_sync,
  cc.data_range_days,
  
  -- Quality Scores
  qs.completeness_score,
  qs.validity_score,
  qs.freshness_score,
  ROUND((qs.completeness_score + qs.validity_score + qs.freshness_score) / 3, 2) AS overall_quality_score,
  
  -- Quality Assessment
  CASE
    WHEN (qs.completeness_score + qs.validity_score + qs.freshness_score) / 3 >= 90 THEN 'Excellent'
    WHEN (qs.completeness_score + qs.validity_score + qs.freshness_score) / 3 >= 75 THEN 'Good'
    WHEN (qs.completeness_score + qs.validity_score + qs.freshness_score) / 3 >= 60 THEN 'Fair'
    ELSE 'Needs Attention'
  END AS quality_rating

FROM completeness_checks cc
CROSS JOIN value_validation vv
CROSS JOIN duplicate_checks dc
CROSS JOIN data_distribution dd
CROSS JOIN quality_score qs
