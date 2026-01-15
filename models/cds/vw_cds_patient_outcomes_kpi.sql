{{
  config(
    materialized='view',
    tags=['cds', 'healthcare', 'kpi', 'executive']
  )
}}

/*
  CDS Patient Outcomes KPI Dashboard
  
  Purpose: Executive-level healthcare performance metrics
  Refresh: Real-time view on source data
  Audience: Healthcare executives, clinical leadership
  
  Key Metrics:
  - Patient volume and outcome scores
  - Treatment success rates
  - Cost metrics and savings
  - Patient satisfaction
  - Medication adherence
  - Risk indicators
*/

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_healthcare', 'cds_records') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

kpi_metrics AS (
  SELECT
    -- Patient Volume
    COUNT(DISTINCT PATIENT_ID) AS total_patients,
    COUNT(DISTINCT RECORD_ID) AS total_records,
    
    -- Outcome Metrics
    ROUND(AVG(PATIENT_OUTCOME_SCORE), 3) AS avg_patient_outcome_score,
    ROUND(MIN(PATIENT_OUTCOME_SCORE), 3) AS min_patient_outcome_score,
    ROUND(MAX(PATIENT_OUTCOME_SCORE), 3) AS max_patient_outcome_score,
    COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) AS high_outcome_count,
    ROUND(COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) / COUNT(*) * 100, 2) AS high_outcome_percentage,
    
    -- Treatment Success
    COUNT_IF(TREATMENT_OUTCOME = 'Successful') AS successful_treatments,
    COUNT_IF(TREATMENT_OUTCOME IN ('Successful', 'Partial Success')) AS positive_treatments,
    ROUND(COUNT_IF(TREATMENT_OUTCOME = 'Successful') / COUNT(*) * 100, 2) AS treatment_success_rate,
    ROUND(COUNT_IF(TREATMENT_OUTCOME IN ('Successful', 'Partial Success')) / COUNT(*) * 100, 2) AS positive_outcome_rate,
    
    -- Patient Satisfaction
    COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') AS satisfied_patients,
    COUNT_IF(PATIENT_SATISFACTION = 'Unsatisfied') AS unsatisfied_patients,
    ROUND(COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') / COUNT(*) * 100, 2) AS satisfaction_rate,
    
    -- Medication Adherence
    COUNT_IF(MEDICATION_ADHERENCE = 'Adherent') AS adherent_patients,
    COUNT_IF(MEDICATION_ADHERENCE = 'Non-Adherent') AS non_adherent_patients,
    ROUND(COUNT_IF(MEDICATION_ADHERENCE = 'Adherent') / COUNT(*) * 100, 2) AS adherence_rate,
    
    -- Cost Metrics
    ROUND(AVG(COST_OF_CARE), 2) AS avg_cost_of_care,
    ROUND(SUM(COST_OF_CARE), 2) AS total_cost_of_care,
    ROUND(AVG(MEDICATION_COST), 2) AS avg_medication_cost,
    ROUND(SUM(MEDICATION_COST), 2) AS total_medication_cost,
    ROUND(SUM(TOTAL_COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Length of Stay
    ROUND(AVG(LENGTH_OF_STAY), 1) AS avg_length_of_stay,
    ROUND(MIN(LENGTH_OF_STAY), 0) AS min_length_of_stay,
    ROUND(MAX(LENGTH_OF_STAY), 0) AS max_length_of_stay,
    
    -- Risk Indicators
    ROUND(AVG(READMISSION_RISK), 3) AS avg_readmission_risk,
    COUNT_IF(READMISSION_RISK > 0.7) AS high_readmission_risk_count,
    ROUND(COUNT_IF(READMISSION_RISK > 0.7) / COUNT(*) * 100, 2) AS high_risk_percentage,
    ROUND(AVG(MEDICAL_ERROR_RATE), 3) AS avg_medical_error_rate,
    COUNT_IF(MEDICAL_ERROR_RATE > 0.5) AS high_error_rate_count,
    
    -- Critical Conditions
    COUNT_IF(VITAL_SIGNS IN ('Critical', 'Life-Threatening')) AS critical_vitals_count,
    COUNT_IF(MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening')) AS severe_side_effects_count,
    COUNT_IF(ALLERGIES IN ('Severe', 'Life-Threatening')) AS severe_allergies_count,
    
    -- Data Freshness
    MAX(_FIVETRAN_SYNCED) AS last_sync_time,
    DATEDIFF('hour', MAX(_FIVETRAN_SYNCED), CURRENT_TIMESTAMP()) AS hours_since_last_sync
    
  FROM source_data
)

SELECT
  -- Metadata
  'CDS Healthcare' AS dataset,
  CURRENT_TIMESTAMP() AS report_generated_at,
  last_sync_time,
  hours_since_last_sync,
  
  -- Volume
  total_patients,
  total_records,
  
  -- Outcomes
  avg_patient_outcome_score,
  min_patient_outcome_score,
  max_patient_outcome_score,
  high_outcome_count,
  high_outcome_percentage,
  
  -- Treatment
  successful_treatments,
  positive_treatments,
  treatment_success_rate,
  positive_outcome_rate,
  
  -- Satisfaction
  satisfied_patients,
  unsatisfied_patients,
  satisfaction_rate,
  
  -- Adherence
  adherent_patients,
  non_adherent_patients,
  adherence_rate,
  
  -- Costs
  avg_cost_of_care,
  total_cost_of_care,
  avg_medication_cost,
  total_medication_cost,
  total_cost_savings,
  
  -- Length of Stay
  avg_length_of_stay,
  min_length_of_stay,
  max_length_of_stay,
  
  -- Risk
  avg_readmission_risk,
  high_readmission_risk_count,
  high_risk_percentage,
  avg_medical_error_rate,
  high_error_rate_count,
  
  -- Critical
  critical_vitals_count,
  severe_side_effects_count,
  severe_allergies_count

FROM kpi_metrics
