{{
  config(
    tags=['analytics', 'kpi', 'executive', 'mso'],
    materialized='view'
  )
}}

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_mso', 'MSO_RECORDS') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

kpi_summary AS (
  SELECT
    -- Record Counts
    COUNT(*) AS total_records,
    COUNT(DISTINCT MATERIAL_ID) AS unique_materials,
    COUNT(DISTINCT PRODUCT_ID) AS unique_products,
    COUNT(DISTINCT DESIGNER_ID) AS unique_designers,
    
    -- Cost Metrics
    ROUND(AVG(MATERIAL_COST), 2) AS avg_material_cost,
    ROUND(SUM(MATERIAL_COST), 2) AS total_material_cost,
    ROUND(AVG(COST_SAVINGS), 2) AS avg_cost_savings,
    ROUND(SUM(COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Optimization Metrics
    ROUND(AVG(WEIGHT_REDUCTION), 2) AS avg_weight_reduction,
    ROUND(AVG(PERFORMANCE_IMPROVEMENT), 2) AS avg_performance_improvement,
    ROUND(AVG(WASTE_REDUCTION), 2) AS avg_waste_reduction,
    
    -- Material Properties
    ROUND(AVG(MATERIAL_WEIGHT), 2) AS avg_material_weight,
    ROUND(AVG(MATERIAL_WASTE), 2) AS avg_material_waste,
    ROUND(AVG(PRODUCT_PERFORMANCE), 2) AS avg_product_performance,
    
    -- Recommendation Rates
    ROUND(
      SUM(CASE WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS material_selection_recommended_pct,
    ROUND(
      SUM(CASE WHEN MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS material_optimization_recommended_pct,
    
    -- Scores
    ROUND(AVG(MATERIAL_SELECTION_SCORE), 3) AS avg_material_selection_score,
    ROUND(AVG(MATERIAL_OPTIMIZATION_SCORE), 3) AS avg_material_optimization_score,
    
    -- ROI Calculation (Cost Savings / Material Cost)
    ROUND(
      (SUM(COST_SAVINGS) / NULLIF(SUM(MATERIAL_COST), 0)) * 100,
      2
    ) AS roi_percentage,
    
    -- Data Freshness
    MAX(_FIVETRAN_SYNCED) AS last_sync_time,
    DATEDIFF('day', MAX(MATERIAL_OPTIMIZATION_DATE), CURRENT_DATE()) AS days_since_last_optimization
    
  FROM source_data
)

SELECT * FROM kpi_summary
