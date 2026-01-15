{{
  config(
    tags=['analytics', 'designer', 'mso'],
    materialized='view'
  )
}}

WITH source_data AS (
  SELECT *
  FROM {{ source('industries_mso', 'MSO_RECORDS') }}
  WHERE _FIVETRAN_DELETED = FALSE
),

designer_performance AS (
  SELECT
    DESIGNER_SKILL_LEVEL,
    
    -- Record Counts
    COUNT(*) AS record_count,
    COUNT(DISTINCT DESIGNER_ID) AS unique_designers,
    COUNT(DISTINCT PRODUCT_ID) AS unique_products,
    
    -- Designer Experience
    ROUND(AVG(DESIGNER_EXPERIENCE), 1) AS avg_experience_years,
    MIN(DESIGNER_EXPERIENCE) AS min_experience_years,
    MAX(DESIGNER_EXPERIENCE) AS max_experience_years,
    
    -- Cost Performance
    ROUND(AVG(MATERIAL_COST), 2) AS avg_material_cost,
    ROUND(AVG(COST_SAVINGS), 2) AS avg_cost_savings,
    ROUND(SUM(COST_SAVINGS), 2) AS total_cost_savings,
    
    -- Optimization Effectiveness
    ROUND(AVG(WEIGHT_REDUCTION), 2) AS avg_weight_reduction,
    ROUND(AVG(PERFORMANCE_IMPROVEMENT), 2) AS avg_performance_improvement,
    ROUND(AVG(WASTE_REDUCTION), 2) AS avg_waste_reduction,
    
    -- Quality Scores
    ROUND(AVG(MATERIAL_SELECTION_SCORE), 3) AS avg_selection_score,
    ROUND(AVG(MATERIAL_OPTIMIZATION_SCORE), 3) AS avg_optimization_score,
    ROUND(AVG(PRODUCT_PERFORMANCE), 2) AS avg_product_performance,
    
    -- Recommendation Success Rates
    ROUND(
      SUM(CASE WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS selection_recommended_pct,
    ROUND(
      SUM(CASE WHEN MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS optimization_recommended_pct,
    
    -- Both Recommended (High Quality)
    ROUND(
      SUM(
        CASE 
          WHEN MATERIAL_SELECTION_RECOMMENDATION = 'Recommended' 
           AND MATERIAL_OPTIMIZATION_RECOMMENDATION = 'Recommended' 
          THEN 1 
          ELSE 0 
        END
      ) * 100.0 / COUNT(*),
      2
    ) AS both_recommended_pct,
    
    -- CAD System Preferences
    SUM(CASE WHEN CAD_SYSTEM = 'SolidWorks' THEN 1 ELSE 0 END) AS solidworks_usage,
    SUM(CASE WHEN CAD_SYSTEM = 'Autodesk Inventor' THEN 1 ELSE 0 END) AS inventor_usage,
    SUM(CASE WHEN CAD_SYSTEM = 'Siemens NX' THEN 1 ELSE 0 END) AS siemens_nx_usage,
    
    -- Product Lifecycle Performance
    SUM(CASE WHEN PRODUCT_LIFECYCLE_STATUS = 'Active' THEN 1 ELSE 0 END) AS active_products,
    ROUND(
      SUM(CASE WHEN PRODUCT_LIFECYCLE_STATUS = 'Active' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
      2
    ) AS active_product_pct,
    
    -- Material Efficiency
    ROUND(AVG(MATERIAL_WEIGHT), 2) AS avg_material_weight,
    ROUND(AVG(MATERIAL_WASTE), 2) AS avg_material_waste,
    ROUND(
      AVG(MATERIAL_WASTE / NULLIF(MATERIAL_WEIGHT, 0)) * 100,
      2
    ) AS avg_waste_percentage,
    
    -- ROI
    ROUND(
      (SUM(COST_SAVINGS) / NULLIF(SUM(MATERIAL_COST), 0)) * 100,
      2
    ) AS roi_percentage
    
  FROM source_data
  GROUP BY DESIGNER_SKILL_LEVEL
)

SELECT * FROM designer_performance
ORDER BY 
  CASE DESIGNER_SKILL_LEVEL
    WHEN 'Beginner' THEN 1
    WHEN 'Intermediate' THEN 2
    WHEN 'Advanced' THEN 3
  END
