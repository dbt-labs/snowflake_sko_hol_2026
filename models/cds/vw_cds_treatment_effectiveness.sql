{{
  config(
    materialized='view',
    tags=['cds', 'healthcare', 'analytics', 'clinical']
  )
}}

/*
  CDS Treatment Effectiveness Analysis
  
  Purpose: Analyze treatment outcomes by diagnosis and treatment plan
  Refresh: Real-time view on source data
  Audience: Clinical teams, treatment coordinators
  
  Insights:
  - Success rates by diagnosis type
  - Treatment plan effectiveness
  - Cost per successful outcome
  - Medication adherence impact
*/

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_healthcare', 'cds_records') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

treatment_analysis AS (
  SELECT
    -- Grouping Dimensions
    DIAGNOSIS,
    TREATMENT_PLAN,
    
    -- Patient Counts
    COUNT(DISTINCT PATIENT_ID) AS patient_count,
    COUNT(DISTINCT RECORD_ID) AS record_count,
    
    -- Outcome Metrics
    ROUND(AVG(PATIENT_OUTCOME_SCORE), 3) AS avg_outcome_score,
    COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) AS high_outcome_count,
    ROUND(COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) / COUNT(*) * 100, 2) AS high_outcome_rate,
    
    -- Treatment Success
    COUNT_IF(TREATMENT_OUTCOME = 'Successful') AS successful_count,
    COUNT_IF(TREATMENT_OUTCOME = 'Partial Success') AS partial_success_count,
    COUNT_IF(TREATMENT_OUTCOME = 'Ongoing') AS ongoing_count,
    COUNT_IF(TREATMENT_OUTCOME = 'Unsuccessful') AS unsuccessful_count,
    ROUND(COUNT_IF(TREATMENT_OUTCOME = 'Successful') / COUNT(*) * 100, 2) AS success_rate,
    
    -- Patient Satisfaction
    COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') AS satisfied_count,
    ROUND(COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') / COUNT(*) * 100, 2) AS satisfaction_rate,
    
    -- Medication Adherence
    COUNT_IF(MEDICATION_ADHERENCE = 'Adherent') AS adherent_count,
    COUNT_IF(MEDICATION_ADHERENCE = 'Partially Adherent') AS partially_adherent_count,
    COUNT_IF(MEDICATION_ADHERENCE = 'Non-Adherent') AS non_adherent_count,
    ROUND(COUNT_IF(MEDICATION_ADHERENCE = 'Adherent') / COUNT(*) * 100, 2) AS adherence_rate,
    
    -- Cost Effectiveness
    ROUND(AVG(COST_OF_CARE), 2) AS avg_cost_of_care,
    ROUND(AVG(MEDICATION_COST), 2) AS avg_medication_cost,
    ROUND(SUM(TOTAL_COST_SAVINGS), 2) AS total_savings,
    ROUND(AVG(TOTAL_COST_SAVINGS), 2) AS avg_savings_per_patient,
    
    -- Calculate cost per successful outcome
    ROUND(
      SUM(COST_OF_CARE) / NULLIF(COUNT_IF(TREATMENT_OUTCOME = 'Successful'), 0),
      2
    ) AS cost_per_successful_outcome,
    
    -- Length of Stay
    ROUND(AVG(LENGTH_OF_STAY), 1) AS avg_length_of_stay,
    
    -- Risk Indicators
    ROUND(AVG(READMISSION_RISK), 3) AS avg_readmission_risk,
    ROUND(AVG(MEDICAL_ERROR_RATE), 3) AS avg_error_rate,
    
    -- Side Effects
    COUNT_IF(MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening')) AS severe_side_effects_count,
    ROUND(COUNT_IF(MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening')) / COUNT(*) * 100, 2) AS severe_side_effects_rate
    
  FROM source_data
  GROUP BY DIAGNOSIS, TREATMENT_PLAN
)

SELECT
  -- Dimensions
  DIAGNOSIS,
  TREATMENT_PLAN,
  
  -- Volume
  patient_count,
  record_count,
  
  -- Outcomes
  avg_outcome_score,
  high_outcome_count,
  high_outcome_rate,
  
  -- Treatment Results
  successful_count,
  partial_success_count,
  ongoing_count,
  unsuccessful_count,
  success_rate,
  
  -- Satisfaction
  satisfied_count,
  satisfaction_rate,
  
  -- Adherence
  adherent_count,
  partially_adherent_count,
  non_adherent_count,
  adherence_rate,
  
  -- Cost Analysis
  avg_cost_of_care,
  avg_medication_cost,
  total_savings,
  avg_savings_per_patient,
  cost_per_successful_outcome,
  
  -- Clinical Metrics
  avg_length_of_stay,
  avg_readmission_risk,
  avg_error_rate,
  severe_side_effects_count,
  severe_side_effects_rate,
  
  -- Rankings (for prioritization)
  RANK() OVER (ORDER BY success_rate DESC) AS success_rate_rank,
  RANK() OVER (ORDER BY cost_per_successful_outcome ASC) AS cost_effectiveness_rank

FROM treatment_analysis
WHERE patient_count >= 5  -- Filter out very small sample sizes
ORDER BY patient_count DESC, success_rate DESC
