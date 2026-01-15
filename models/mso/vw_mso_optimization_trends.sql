{{
  config(
    tags=['analytics', 'trends', 'mso'],
    materialized='view'
  )
}}

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_mso', 'MSO_RECORDS') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

monthly_trends AS (
  SELECT
    DATE_TRUNC('month', TO_DATE(MATERIAL_OPTIMIZATION_DATE)) AS optimization_month,
    
    -- Record Counts
    COUNT(*) AS records_optimized,
    COUNT(DISTINCT MATERIAL_ID) AS unique_materials,
    COUNT(DISTINCT PRODUCT_ID) AS unique_products,
    
    -- Cost Metrics
    ROUND(AVG(MATERIAL_COST), 2) AS avg_material_cost,
    ROUND(AVG(COST_SAVINGS), 2) AS avg_cost_savings,
    ROUND(SUM(COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Optimization Metrics
    ROUND(AVG(WEIGHT_REDUCTION), 2) AS avg_weight_reduction,
    ROUND(AVG(PERFORMANCE_IMPROVEMENT), 2) AS avg_performance_improvement,
    ROUND(AVG(WASTE_REDUCTION), 2) AS avg_waste_reduction,
    
    -- Scores
    ROUND(AVG(MATERIAL_SELECTION_SCORE), 3) AS avg_selection_score,
    ROUND(AVG(MATERIAL_OPTIMIZATION_SCORE), 3) AS avg_optimization_score,
    
    -- Recommendation Rates
    ROUND(
      SUM(CASE WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS selection_recommended_pct,
    ROUND(
      SUM(CASE WHEN MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS optimization_recommended_pct,
    
    -- CAD System Distribution
    SUM(CASE WHEN CAD_SYSTEM = 'SolidWorks' THEN 1 ELSE 0 END) AS solidworks_count,
    SUM(CASE WHEN CAD_SYSTEM = 'Autodesk Inventor' THEN 1 ELSE 0 END) AS inventor_count,
    SUM(CASE WHEN CAD_SYSTEM = 'Siemens NX' THEN 1 ELSE 0 END) AS siemens_nx_count,
    
    -- Lifecycle Stage Distribution
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STAGE = 'Design' THEN 1 ELSE 0 END) AS design_stage_count,
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STAGE = 'Development' THEN 1 ELSE 0 END) AS development_stage_count,
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STAGE = 'Testing' THEN 1 ELSE 0 END) AS testing_stage_count,
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STAGE = 'Production' THEN 1 ELSE 0 END) AS production_stage_count,
    
    -- ROI
    ROUND(
      (SUM(COST_SAVINGS) / NULLIF(SUM(MATERIAL_COST), 0)) * 100,
      2
    ) AS roi_percentage
    
  FROM source_data
  WHERE MATERIAL_OPTIMIZATION_DATE IS NOT NULL
  GROUP BY optimization_month
)

SELECT * FROM monthly_trends
ORDER BY optimization_month DESC
