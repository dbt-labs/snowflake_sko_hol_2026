{{
  config(
    tags=['analytics', 'segmentation', 'mso'],
    materialized='view'
  )
}}

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_mso', 'MSO_RECORDS') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

cad_system_metrics AS (
  SELECT
    CAD_SYSTEM,
    
    -- Record Counts
    COUNT(*) AS record_count,
    COUNT(DISTINCT DESIGNER_ID) AS unique_designers,
    COUNT(DISTINCT PRODUCT_ID) AS unique_products,
    
    -- Cost Metrics
    ROUND(AVG(MATERIAL_COST), 2) AS avg_material_cost,
    ROUND(AVG(COST_SAVINGS), 2) AS avg_cost_savings,
    ROUND(SUM(COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Optimization Performance
    ROUND(AVG(WEIGHT_REDUCTION), 2) AS avg_weight_reduction,
    ROUND(AVG(PERFORMANCE_IMPROVEMENT), 2) AS avg_performance_improvement,
    ROUND(AVG(WASTE_REDUCTION), 2) AS avg_waste_reduction,
    
    -- Material Quality
    ROUND(AVG(MATERIAL_WEIGHT), 2) AS avg_material_weight,
    ROUND(AVG(MATERIAL_WASTE), 2) AS avg_material_waste,
    ROUND(AVG(PRODUCT_PERFORMANCE), 2) AS avg_product_performance,
    
    -- Scores
    ROUND(AVG(MATERIAL_SELECTION_SCORE), 3) AS avg_selection_score,
    ROUND(AVG(MATERIAL_OPTIMIZATION_SCORE), 3) AS avg_optimization_score,
    
    -- Recommendation Success Rates
    ROUND(
      SUM(CASE WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS selection_recommended_pct,
    ROUND(
      SUM(CASE WHEN MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS optimization_recommended_pct,
    
    -- Designer Experience
    ROUND(AVG(DESIGNER_EXPERIENCE), 1) AS avg_designer_experience,
    
    -- Lifecycle Distribution
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STATUS = 'Active' THEN 1 ELSE 0 END) AS active_products,
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STATUS = 'On Hold' THEN 1 ELSE 0 END) AS on_hold_products,
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STATUS = 'Inactive' THEN 1 ELSE 0 END) AS inactive_products,
    
    -- ROI
    ROUND(
      (SUM(COST_SAVINGS) / NULLIF(SUM(MATERIAL_COST), 0)) * 100,
      2
    ) AS roi_percentage
    
  FROM source_data
  GROUP BY CAD_SYSTEM
)

SELECT * FROM cad_system_metrics
ORDER BY record_count DESC
