{{
  config(
    tags=['analytics', 'data_quality', 'monitoring', 'mso'],
    materialized='view'
  )
}}

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_mso', 'MSO_RECORDS') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

data_quality_checks AS (
  SELECT
    -- Record Counts
    COUNT(*) AS total_records,
    COUNT(DISTINCT RECORD_ID) AS unique_record_ids,
    
    -- Completeness - Identifiers
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN MATERIAL_ID IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS material_id_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN PRODUCT_ID IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS product_id_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN DESIGNER_ID IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS designer_id_completeness_pct,
    
    -- Completeness - Key Metrics
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN MATERIAL_COST IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS material_cost_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN COST_SAVINGS IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS cost_savings_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN WEIGHT_REDUCTION IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS weight_reduction_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN PERFORMANCE_IMPROVEMENT IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS performance_improvement_completeness_pct,
    
    -- Completeness - Material Properties
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN DENSITY IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS density_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN YOUNGS_MODULUS IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS youngs_modulus_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN POISSONS_RATIO IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS poissons_ratio_completeness_pct,
    
    -- Completeness - Dates
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN MATERIAL_SELECTION_DATE IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS selection_date_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN MATERIAL_OPTIMIZATION_DATE IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS optimization_date_completeness_pct,
    
    -- Completeness - Categorical
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN CAD_SYSTEM IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS cad_system_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN PRODUCT_LIFECYCLE_STAGE IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS lifecycle_stage_completeness_pct,
    ROUND(
      (COUNT(*) - COUNT(CASE WHEN DESIGNER_SKILL_LEVEL IS NULL THEN 1 END)) * 100.0 / COUNT(*),
      2
    ) AS skill_level_completeness_pct,
    
    -- Data Quality Issues
    SUM(CASE WHEN MATERIAL_COST < 0 THEN 1 ELSE 0 END) AS negative_cost_count,
    SUM(CASE WHEN MATERIAL_WEIGHT < 0 THEN 1 ELSE 0 END) AS negative_weight_count,
    SUM(CASE WHEN COST_SAVINGS < 0 THEN 1 ELSE 0 END) AS negative_savings_count,
    SUM(CASE WHEN MATERIAL_SELECTION_SCORE < 0 OR MATERIAL_SELECTION_SCORE > 1 THEN 1 ELSE 0 END) AS invalid_selection_score_count,
    SUM(CASE WHEN MATERIAL_OPTIMIZATION_SCORE < 0 OR MATERIAL_OPTIMIZATION_SCORE > 1 THEN 1 ELSE 0 END) AS invalid_optimization_score_count,
    
    -- Duplicate Checks
    COUNT(*) - COUNT(DISTINCT RECORD_ID) AS duplicate_record_ids,
    
    -- Date Validity
    SUM(
      CASE 
        WHEN MATERIAL_OPTIMIZATION_DATE < MATERIAL_SELECTION_DATE 
        THEN 1 
        ELSE 0 
      END
    ) AS optimization_before_selection_count,
    
    -- Recommendation Consistency
    SUM(
      CASE 
        WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' 
         AND MATERIAL_SELECTION_SCORE < 0.5 
        THEN 1 
        ELSE 0 
      END
    ) AS inconsistent_selection_recommendation_count,
    SUM(
      CASE 
        WHEN MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' 
         AND MATERIAL_OPTIMIZATION_SCORE < 0.5 
        THEN 1 
        ELSE 0 
      END
    ) AS inconsistent_optimization_recommendation_count,
    
    -- Data Freshness
    MAX(_FIVETRAN_SYNCED) AS last_sync_time,
    DATEDIFF('hour', MAX(_FIVETRAN_SYNCED), CURRENT_TIMESTAMP()) AS hours_since_last_sync,
    MIN(MATERIAL_SELECTION_DATE) AS earliest_selection_date,
    MAX(MATERIAL_OPTIMIZATION_DATE) AS latest_optimization_date,
    
    -- Overall Data Quality Score (average of key completeness metrics)
    ROUND(
      (
        (COUNT(*) - COUNT(CASE WHEN MATERIAL_ID IS NULL THEN 1 END)) * 100.0 / COUNT(*) +
        (COUNT(*) - COUNT(CASE WHEN MATERIAL_COST IS NULL THEN 1 END)) * 100.0 / COUNT(*) +
        (COUNT(*) - COUNT(CASE WHEN COST_SAVINGS IS NULL THEN 1 END)) * 100.0 / COUNT(*) +
        (COUNT(*) - COUNT(CASE WHEN CAD_SYSTEM IS NULL THEN 1 END)) * 100.0 / COUNT(*) +
        (COUNT(*) - COUNT(CASE WHEN MATERIAL_SELECTION_DATE IS NULL THEN 1 END)) * 100.0 / COUNT(*)
      ) / 5,
      2
    ) AS overall_data_quality_score
    
  FROM source_data
)

SELECT * FROM data_quality_checks
