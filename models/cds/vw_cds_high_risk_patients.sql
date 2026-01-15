{{
  config(
    materialized='view',
    tags=['cds', 'healthcare', 'alerts', 'operations']
  )
}}

/*
  CDS High Risk Patients Alert View
  
  Purpose: Identify patients requiring immediate clinical attention
  Refresh: Real-time view on source data
  Audience: Clinical teams, care coordinators, hospital operations
  
  Alert Criteria:
  - High readmission risk (>0.7)
  - Low patient outcome score (<0.3)
  - Life-threatening conditions
  - High medical error rate (>0.5)
  - Non-adherent with unsuccessful outcomes
*/

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_healthcare', 'cds_records') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

risk_assessment AS (
  SELECT
    -- Patient & Record Identifiers
    RECORD_ID,
    PATIENT_ID,
    
    -- Clinical Information
    DIAGNOSIS,
    MEDICAL_CONDITIONS,
    MEDICAL_HISTORY,
    TREATMENT_PLAN,
    TREATMENT_OUTCOME,
    
    -- Current Status
    VITAL_SIGNS,
    ALLERGIES,
    LAB_RESULTS,
    
    -- Medications
    CURRENT_MEDICATIONS,
    MEDICATION_ADHERENCE,
    MEDICATION_SIDE_EFFECTS,
    
    -- Outcome Metrics
    PATIENT_OUTCOME_SCORE,
    PATIENT_SATISFACTION,
    
    -- Risk Indicators
    READMISSION_RISK,
    MEDICAL_ERROR_RATE,
    
    -- Clinical Trial
    CLINICAL_TRIAL_ID,
    TRIAL_STATUS,
    
    -- Costs
    COST_OF_CARE,
    LENGTH_OF_STAY,
    
    -- Data Quality
    _FIVETRAN_SYNCED,
    
    -- Risk Flags
    CASE WHEN READMISSION_RISK > 0.7 THEN TRUE ELSE FALSE END AS high_readmission_risk,
    CASE WHEN PATIENT_OUTCOME_SCORE < 0.3 THEN TRUE ELSE FALSE END AS low_outcome_score,
    CASE WHEN VITAL_SIGNS IN ('Critical', 'Life-Threatening') THEN TRUE ELSE FALSE END AS critical_vitals,
    CASE WHEN MEDICATION_SIDE_EFFECTS IN ('Severe', 'Life-Threatening') THEN TRUE ELSE FALSE END AS severe_side_effects,
    CASE WHEN MEDICAL_ERROR_RATE > 0.5 THEN TRUE ELSE FALSE END AS high_error_rate,
    CASE WHEN MEDICATION_ADHERENCE = 'Non-Adherent' AND TREATMENT_OUTCOME = 'Unsuccessful' THEN TRUE ELSE FALSE END AS non_adherent_unsuccessful,
    CASE WHEN LAB_RESULTS IN ('Critical', 'Life-Threatening') THEN TRUE ELSE FALSE END AS critical_labs,
    CASE WHEN ALLERGIES IN ('Severe', 'Life-Threatening') THEN TRUE ELSE FALSE END AS severe_allergies,
    CASE WHEN LENGTH_OF_STAY > 180 THEN TRUE ELSE FALSE END AS extended_stay,
    CASE WHEN PATIENT_SATISFACTION = 'Unsatisfied' AND PATIENT_OUTCOME_SCORE < 0.5 THEN TRUE ELSE FALSE END AS poor_experience
    
  FROM source_data
),

risk_scoring AS (
  SELECT
    *,
    
    -- Calculate Risk Score (0-10 scale, higher = more critical)
    (
      CASE WHEN high_readmission_risk THEN 2 ELSE 0 END +
      CASE WHEN low_outcome_score THEN 2 ELSE 0 END +
      CASE WHEN critical_vitals THEN 2 ELSE 0 END +
      CASE WHEN severe_side_effects THEN 1 ELSE 0 END +
      CASE WHEN high_error_rate THEN 1 ELSE 0 END +
      CASE WHEN non_adherent_unsuccessful THEN 1 ELSE 0 END +
      CASE WHEN critical_labs THEN 1 ELSE 0 END +
      CASE WHEN severe_allergies THEN 0.5 ELSE 0 END +
      CASE WHEN extended_stay THEN 0.5 ELSE 0 END +
      CASE WHEN poor_experience THEN 0.5 ELSE 0 END
    ) AS risk_score,
    
    -- Count active risk flags
    (
      CASE WHEN high_readmission_risk THEN 1 ELSE 0 END +
      CASE WHEN low_outcome_score THEN 1 ELSE 0 END +
      CASE WHEN critical_vitals THEN 1 ELSE 0 END +
      CASE WHEN severe_side_effects THEN 1 ELSE 0 END +
      CASE WHEN high_error_rate THEN 1 ELSE 0 END +
      CASE WHEN non_adherent_unsuccessful THEN 1 ELSE 0 END +
      CASE WHEN critical_labs THEN 1 ELSE 0 END +
      CASE WHEN severe_allergies THEN 1 ELSE 0 END +
      CASE WHEN extended_stay THEN 1 ELSE 0 END +
      CASE WHEN poor_experience THEN 1 ELSE 0 END
    ) AS active_risk_flags
    
  FROM risk_assessment
),

alert_prioritization AS (
  SELECT
    *,
    
    -- Determine Priority Level
    CASE
      WHEN risk_score >= 5 THEN 'Critical'
      WHEN risk_score >= 3 THEN 'High'
      WHEN risk_score >= 1.5 THEN 'Medium'
      ELSE 'Low'
    END AS priority_level,
    
    -- Generate Alert Message
    CONCAT(
      'Patient ', PATIENT_ID, ' requires attention: ',
      CASE WHEN critical_vitals THEN 'Critical vitals. ' ELSE '' END,
      CASE WHEN severe_side_effects THEN 'Severe medication side effects. ' ELSE '' END,
      CASE WHEN high_readmission_risk THEN 'High readmission risk (' || ROUND(READMISSION_RISK * 100, 0) || '%). ' ELSE '' END,
      CASE WHEN low_outcome_score THEN 'Low outcome score (' || ROUND(PATIENT_OUTCOME_SCORE, 2) || '). ' ELSE '' END,
      CASE WHEN non_adherent_unsuccessful THEN 'Non-adherent with unsuccessful treatment. ' ELSE '' END,
      CASE WHEN high_error_rate THEN 'High error rate (' || ROUND(MEDICAL_ERROR_RATE * 100, 0) || '%). ' ELSE '' END
    ) AS alert_message,
    
    -- Recommended Actions
    ARRAY_CONSTRUCT_COMPACT(
      CASE WHEN critical_vitals THEN 'Immediate clinical assessment required' END,
      CASE WHEN severe_side_effects THEN 'Review medication regimen' END,
      CASE WHEN high_readmission_risk THEN 'Schedule follow-up care' END,
      CASE WHEN non_adherent_unsuccessful THEN 'Patient education and adherence support' END,
      CASE WHEN high_error_rate THEN 'Care quality review' END,
      CASE WHEN extended_stay THEN 'Discharge planning review' END,
      CASE WHEN poor_experience THEN 'Patient experience intervention' END
    ) AS recommended_actions
    
  FROM risk_scoring
)

SELECT
  -- Identifiers
  RECORD_ID,
  PATIENT_ID,
  
  -- Priority
  priority_level,
  risk_score,
  active_risk_flags,
  
  -- Clinical Context
  DIAGNOSIS,
  MEDICAL_CONDITIONS,
  TREATMENT_PLAN,
  TREATMENT_OUTCOME,
  
  -- Current Status
  VITAL_SIGNS,
  LAB_RESULTS,
  ALLERGIES,
  
  -- Medications
  CURRENT_MEDICATIONS,
  MEDICATION_ADHERENCE,
  MEDICATION_SIDE_EFFECTS,
  
  -- Outcome & Satisfaction
  PATIENT_OUTCOME_SCORE,
  PATIENT_SATISFACTION,
  
  -- Risk Metrics
  READMISSION_RISK,
  MEDICAL_ERROR_RATE,
  LENGTH_OF_STAY,
  
  -- Trial Information
  CLINICAL_TRIAL_ID,
  TRIAL_STATUS,
  
  -- Cost
  COST_OF_CARE,
  
  -- Risk Flags
  high_readmission_risk,
  low_outcome_score,
  critical_vitals,
  severe_side_effects,
  high_error_rate,
  non_adherent_unsuccessful,
  critical_labs,
  severe_allergies,
  extended_stay,
  poor_experience,
  
  -- Alert Details
  alert_message,
  recommended_actions,
  
  -- Metadata
  _FIVETRAN_SYNCED AS last_updated

FROM alert_prioritization

-- Filter to only show patients with at least one risk flag
WHERE active_risk_flags > 0

-- Order by priority and risk score
ORDER BY
  CASE priority_level
    WHEN 'Critical' THEN 1
    WHEN 'High' THEN 2
    WHEN 'Medium' THEN 3
    WHEN 'Low' THEN 4
  END,
  risk_score DESC,
  PATIENT_ID
