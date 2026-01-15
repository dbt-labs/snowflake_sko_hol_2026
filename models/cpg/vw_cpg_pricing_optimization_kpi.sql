{{
  config(
    materialized='view',
    tags=['cpg', 'analytics', 'pricing', 'kpi']
  )
}}

/*
  CPG Pricing Optimization KPI Dashboard
  
  Purpose: Executive-level metrics tracking the effectiveness of dynamic pricing
  strategies across products and categories.
  
  Key Metrics:
  - Price optimization success rate
  - Revenue impact by optimization action
  - Price elasticity analysis
  - Category-level pricing performance
  
  Business Value: Understand ROI of pricing optimization initiatives and identify
  which product categories respond best to dynamic pricing strategies.
*/

WITH base_data AS (
  SELECT
    record_id,
    order_date,
    order_total,
    product_price,
    product_category,
    product_subcategory,
    price_optimization_flag,
    price_optimization_result,
    price_optimization_recommendation,
    price_elasticity,
    revenue_growth_rate,
    order_status,
    _fivetran_synced
  FROM {{ source('cpg', 'cpg_records') }}
  WHERE _fivetran_deleted = FALSE
),

optimization_metrics AS (
  SELECT
    -- Overall optimization metrics
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END) AS optimized_orders,
    COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS optimization_rate,
    
    -- Success metrics
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END) AS successful_optimizations,
    COUNT(CASE WHEN price_optimization_result = 'Failure' THEN 1 END) AS failed_optimizations,
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END), 0) AS success_rate,
    
    -- Revenue impact
    SUM(CASE WHEN price_optimization_flag = TRUE THEN order_total ELSE 0 END) AS revenue_from_optimized,
    SUM(CASE WHEN price_optimization_flag = FALSE THEN order_total ELSE 0 END) AS revenue_from_standard,
    SUM(order_total) AS total_revenue,
    AVG(CASE WHEN price_optimization_flag = TRUE THEN order_total END) AS avg_optimized_order_value,
    AVG(CASE WHEN price_optimization_flag = FALSE THEN order_total END) AS avg_standard_order_value,
    
    -- Price elasticity insights
    AVG(price_elasticity) AS avg_price_elasticity,
    AVG(CASE WHEN price_optimization_recommendation = 'Increase Price' 
        THEN price_elasticity END) AS avg_elasticity_increase_recs,
    AVG(CASE WHEN price_optimization_recommendation = 'Decrease Price' 
        THEN price_elasticity END) AS avg_elasticity_decrease_recs,
    
    -- Growth metrics
    AVG(revenue_growth_rate) AS avg_revenue_growth_rate,
    AVG(CASE WHEN price_optimization_result = 'Success' 
        THEN revenue_growth_rate END) AS avg_growth_successful_pricing,
    
    -- Order fulfillment
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS delivery_rate,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    
    -- Data freshness
    MAX(_fivetran_synced) AS last_sync_time
  FROM base_data
),

category_performance AS (
  SELECT
    product_category,
    COUNT(*) AS category_orders,
    COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END) AS category_optimized_orders,
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END), 0) 
      AS category_success_rate,
    SUM(order_total) AS category_revenue,
    AVG(price_elasticity) AS category_avg_elasticity,
    AVG(revenue_growth_rate) AS category_growth_rate
  FROM base_data
  GROUP BY product_category
),

recommendation_analysis AS (
  SELECT
    price_optimization_recommendation,
    COUNT(*) AS recommendation_count,
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END) AS successful_count,
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS recommendation_success_rate,
    SUM(order_total) AS recommendation_revenue,
    AVG(revenue_growth_rate) AS avg_revenue_growth
  FROM base_data
  WHERE price_optimization_flag = TRUE
  GROUP BY price_optimization_recommendation
)

SELECT
  -- KPI Metrics
  om.total_orders,
  om.optimized_orders,
  ROUND(om.optimization_rate * 100, 2) AS optimization_rate_pct,
  om.successful_optimizations,
  om.failed_optimizations,
  ROUND(om.success_rate * 100, 2) AS success_rate_pct,
  
  -- Revenue Impact
  ROUND(om.total_revenue, 2) AS total_revenue,
  ROUND(om.revenue_from_optimized, 2) AS revenue_from_optimized_pricing,
  ROUND(om.revenue_from_standard, 2) AS revenue_from_standard_pricing,
  ROUND(om.avg_optimized_order_value, 2) AS avg_optimized_order_value,
  ROUND(om.avg_standard_order_value, 2) AS avg_standard_order_value,
  ROUND((om.avg_optimized_order_value - om.avg_standard_order_value) / 
    NULLIF(om.avg_standard_order_value, 0) * 100, 2) AS pricing_lift_pct,
  
  -- Elasticity Insights
  ROUND(om.avg_price_elasticity, 3) AS avg_price_elasticity,
  ROUND(om.avg_elasticity_increase_recs, 3) AS avg_elasticity_for_price_increases,
  ROUND(om.avg_elasticity_decrease_recs, 3) AS avg_elasticity_for_price_decreases,
  
  -- Growth Metrics
  ROUND(om.avg_revenue_growth_rate * 100, 2) AS avg_revenue_growth_rate_pct,
  ROUND(om.avg_growth_successful_pricing * 100, 2) AS avg_growth_successful_pricing_pct,
  
  -- Fulfillment Metrics
  ROUND(om.delivery_rate * 100, 2) AS delivery_rate_pct,
  ROUND(om.cancellation_rate * 100, 2) AS cancellation_rate_pct,
  
  -- Top Performing Category
  (SELECT product_category FROM category_performance 
   ORDER BY category_revenue DESC LIMIT 1) AS top_revenue_category,
  (SELECT ROUND(category_revenue, 2) FROM category_performance 
   ORDER BY category_revenue DESC LIMIT 1) AS top_category_revenue,
  
  -- Best Elasticity Category
  (SELECT product_category FROM category_performance 
   ORDER BY category_success_rate DESC LIMIT 1) AS best_optimization_category,
  (SELECT ROUND(category_success_rate * 100, 2) FROM category_performance 
   ORDER BY category_success_rate DESC LIMIT 1) AS best_category_success_rate_pct,
  
  -- Recommendation Performance
  (SELECT price_optimization_recommendation FROM recommendation_analysis 
   ORDER BY recommendation_success_rate DESC LIMIT 1) AS best_performing_recommendation,
  (SELECT ROUND(recommendation_success_rate * 100, 2) FROM recommendation_analysis 
   ORDER BY recommendation_success_rate DESC LIMIT 1) AS best_recommendation_success_rate_pct,
  
  -- Data Freshness
  om.last_sync_time,
  DATEDIFF('hour', om.last_sync_time, CURRENT_TIMESTAMP()) AS hours_since_last_sync

FROM optimization_metrics om
