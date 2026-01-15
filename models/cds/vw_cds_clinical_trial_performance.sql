{{
  config(
    materialized='view',
    tags=['cds', 'healthcare', 'analytics', 'trials']
  )
}}

/*
  CDS Clinical Trial Performance
  
  Purpose: Monitor clinical trial enrollment, outcomes, and effectiveness
  Refresh: Real-time view on source data
  Audience: Research teams, trial coordinators, medical researchers
  
  Insights:
  - Trial status and enrollment metrics
  - Patient outcomes by trial
  - Trial cost analysis
  - Publication linkage
*/

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_healthcare', 'cds_records') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

trial_metrics AS (
  SELECT
    -- Trial Identifiers
    TRIAL_NAME,
    CLINICAL_TRIAL_ID,
    TRIAL_STATUS,
    
    -- Enrollment Metrics
    COUNT(DISTINCT PATIENT_ID) AS enrolled_patients,
    COUNT(DISTINCT RECORD_ID) AS total_records,
    
    -- Patient Demographics
    COUNT(DISTINCT DIAGNOSIS) AS diagnosis_types_count,
    MODE(DIAGNOSIS) AS most_common_diagnosis,
    
    -- Outcome Metrics
    ROUND(AVG(PATIENT_OUTCOME_SCORE), 3) AS avg_patient_outcome_score,
    ROUND(STDDEV(PATIENT_OUTCOME_SCORE), 3) AS outcome_score_stddev,
    COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) AS high_outcome_count,
    ROUND(COUNT_IF(PATIENT_OUTCOME_SCORE >= 0.7) / COUNT(*) * 100, 2) AS high_outcome_percentage,
    
    -- Treatment Success
    COUNT_IF(TREATMENT_OUTCOME = 'Successful') AS successful_treatments,
    COUNT_IF(TREATMENT_OUTCOME = 'Partial Success') AS partial_success_count,
    COUNT_IF(TREATMENT_OUTCOME = 'Ongoing') AS ongoing_treatments,
    COUNT_IF(TREATMENT_OUTCOME = 'Unsuccessful') AS unsuccessful_treatments,
    ROUND(COUNT_IF(TREATMENT_OUTCOME = 'Successful') / COUNT(*) * 100, 2) AS success_rate,
    
    -- Patient Satisfaction
    COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') AS satisfied_patients,
    COUNT_IF(PATIENT_SATISFACTION = 'Neutral') AS neutral_patients,
    COUNT_IF(PATIENT_SATISFACTION = 'Unsatisfied') AS unsatisfied_patients,
    ROUND(COUNT_IF(PATIENT_SATISFACTION = 'Satisfied') / COUNT(*) * 100, 2) AS satisfaction_rate,
    
    -- Medication Adherence
    ROUND(COUNT_IF(MEDICATION_ADHERENCE = 'Adherent') / COUNT(*) * 100, 2) AS adherence_rate,
    
    -- Safety Metrics
    COUNT_IF(MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening')) AS severe_side_effects,
    ROUND(COUNT_IF(MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening')) / COUNT(*) * 100, 2) AS severe_side_effects_rate,
    COUNT_IF(VITAL_SIGNS IN ('Critical', 'Life-Threatening')) AS critical_vitals_count,
    ROUND(AVG(MEDICAL_ERROR_RATE), 3) AS avg_error_rate,
    
    -- Cost Analysis
    ROUND(AVG(COST_OF_CARE), 2) AS avg_cost_per_patient,
    ROUND(SUM(COST_OF_CARE), 2) AS total_trial_cost,
    ROUND(AVG(MEDICATION_COST), 2) AS avg_medication_cost,
    ROUND(SUM(TOTAL_COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Length of Stay
    ROUND(AVG(LENGTH_OF_STAY), 1) AS avg_length_of_stay,
    
    -- Risk Assessment
    ROUND(AVG(READMISSION_RISK), 3) AS avg_readmission_risk,
    COUNT_IF(READMISSION_RISK > 0.7) AS high_risk_patients,
    
    -- Publication Activity
    COUNT(DISTINCT MEDICAL_PUBLICATION_ID) AS related_publications,
    MIN(PUBLICATION_DATE) AS earliest_publication_date,
    MAX(PUBLICATION_DATE) AS latest_publication_date,
    
    -- Data Quality
    MAX(_FIVETRAN_SYNCED) AS last_updated
    
  FROM source_data
  GROUP BY TRIAL_NAME, CLINICAL_TRIAL_ID, TRIAL_STATUS
),

trial_duration AS (
  SELECT
    CLINICAL_TRIAL_ID,
    DATEDIFF('day', earliest_publication_date, latest_publication_date) AS trial_duration_days
  FROM trial_metrics
),

final AS (
  SELECT
    tm.*,
    td.trial_duration_days,
    
    -- Cost Effectiveness
    ROUND(
      tm.total_trial_cost / NULLIF(tm.successful_treatments, 0),
      2
    ) AS cost_per_successful_outcome,
    
    -- Efficiency Score (higher is better)
    ROUND(
      (tm.success_rate * tm.satisfaction_rate * tm.adherence_rate) / 1000000,
      2
    ) AS efficiency_score
    
  FROM trial_metrics tm
  LEFT JOIN trial_duration td
    ON tm.CLINICAL_TRIAL_ID = td.CLINICAL_TRIAL_ID
)

SELECT
  -- Trial Information
  TRIAL_NAME,
  CLINICAL_TRIAL_ID,
  TRIAL_STATUS,
  trial_duration_days,
  
  -- Enrollment
  enrolled_patients,
  total_records,
  diagnosis_types_count,
  most_common_diagnosis,
  
  -- Outcomes
  avg_patient_outcome_score,
  outcome_score_stddev,
  high_outcome_count,
  high_outcome_percentage,
  
  -- Treatment Results
  successful_treatments,
  partial_success_count,
  ongoing_treatments,
  unsuccessful_treatments,
  success_rate,
  
  -- Patient Experience
  satisfied_patients,
  neutral_patients,
  unsatisfied_patients,
  satisfaction_rate,
  adherence_rate,
  
  -- Safety
  severe_side_effects,
  severe_side_effects_rate,
  critical_vitals_count,
  avg_error_rate,
  
  -- Cost
  avg_cost_per_patient,
  total_trial_cost,
  avg_medication_cost,
  total_cost_savings,
  cost_per_successful_outcome,
  
  -- Clinical Metrics
  avg_length_of_stay,
  avg_readmission_risk,
  high_risk_patients,
  
  -- Publications
  related_publications,
  earliest_publication_date,
  latest_publication_date,
  
  -- Performance Score
  efficiency_score,
  
  -- Metadata
  last_updated

FROM final
ORDER BY 
  CASE TRIAL_STATUS
    WHEN 'Active' THEN 1
    WHEN 'Recruiting' THEN 2
    WHEN 'Enrolling' THEN 3
    WHEN 'Follow-up' THEN 4
    WHEN 'Completed' THEN 5
    WHEN 'Inactive' THEN 6
    WHEN 'Terminated' THEN 7
    ELSE 8
  END,
  enrolled_patients DESC
