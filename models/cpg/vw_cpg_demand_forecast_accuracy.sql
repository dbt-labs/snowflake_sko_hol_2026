{{
  config(
    materialized='view',
    tags=['cpg', 'analytics', 'forecasting', 'planning']
  )
}}

/*
  CPG Demand Forecast Accuracy
  
  Purpose: Monitor the quality of demand forecasting and its correlation with
  order fulfillment, product ratings, and cancellation rates.
  
  Key Metrics:
  - Forecast distribution analysis
  - Order fulfillment by forecast level
  - Product rating correlation with demand
  - Cancellation patterns by forecast tier
  
  Business Value: Improve demand planning accuracy to reduce stockouts and
  optimize inventory investment based on reliable forecasts.
*/

WITH base_data AS (
  SELECT
    product_id,
    product_category,
    product_subcategory,
    demand_forecast,
    inventory_level,
    inventory_turnover,
    stockout_rate,
    order_status,
    order_total,
    product_rating,
    product_review_count,
    customer_segment,
    customer_satisfaction_rate,
    price_elasticity,
    _fivetran_synced
  FROM {{ source('cpg', 'cpg_records') }}
  WHERE _fivetran_deleted = FALSE
),

forecast_tiers AS (
  SELECT
    *,
    CASE
      WHEN demand_forecast <= 25 THEN 'Low Demand (1-25)'
      WHEN demand_forecast <= 50 THEN 'Medium Demand (26-50)'
      WHEN demand_forecast <= 75 THEN 'High Demand (51-75)'
      ELSE 'Very High Demand (76+)'
    END AS demand_tier,
    CASE
      WHEN inventory_level < (demand_forecast * 5) THEN 'Under-Stocked'
      WHEN inventory_level > (demand_forecast * 15) THEN 'Over-Stocked'
      ELSE 'Adequately Stocked'
    END AS inventory_status
  FROM base_data
),

forecast_tier_analysis AS (
  SELECT
    demand_tier,
    
    -- Volume metrics
    COUNT(*) AS total_orders,
    COUNT(DISTINCT product_id) AS unique_products,
    AVG(demand_forecast) AS avg_demand_forecast,
    MIN(demand_forecast) AS min_demand_forecast,
    MAX(demand_forecast) AS max_demand_forecast,
    
    -- Inventory positioning
    AVG(inventory_level) AS avg_inventory_level,
    AVG(inventory_turnover) AS avg_inventory_turnover,
    AVG(stockout_rate) AS avg_stockout_rate,
    
    -- Inventory status distribution
    COUNT(CASE WHEN inventory_status = 'Under-Stocked' THEN 1 END) AS understocked_products,
    COUNT(CASE WHEN inventory_status = 'Over-Stocked' THEN 1 END) AS overstocked_products,
    COUNT(CASE WHEN inventory_status = 'Adequately Stocked' THEN 1 END) AS well_stocked_products,
    
    -- Order fulfillment
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    COUNT(CASE WHEN order_status = 'Pending' THEN 1 END) AS pending_orders,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS fulfillment_rate,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    
    -- Revenue metrics
    SUM(order_total) AS total_revenue,
    AVG(order_total) AS avg_order_value,
    
    -- Quality metrics
    AVG(product_rating) AS avg_product_rating,
    AVG(product_review_count) AS avg_review_count,
    AVG(customer_satisfaction_rate) AS avg_customer_satisfaction,
    
    -- Customer segment mix
    COUNT(CASE WHEN customer_segment = 'High-Value' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS high_value_customer_pct,
    
    -- Price sensitivity
    AVG(price_elasticity) AS avg_price_elasticity,
    
    MAX(_fivetran_synced) AS last_sync_time
    
  FROM forecast_tiers
  GROUP BY demand_tier
),

category_forecast_performance AS (
  SELECT
    product_category,
    COUNT(*) AS category_orders,
    AVG(demand_forecast) AS avg_category_forecast,
    AVG(inventory_level) AS avg_category_inventory,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS category_fulfillment_rate,
    AVG(stockout_rate) AS avg_category_stockout_rate,
    SUM(order_total) AS category_revenue,
    AVG(product_rating) AS avg_category_rating
  FROM forecast_tiers
  GROUP BY product_category
),

forecast_accuracy_metrics AS (
  SELECT
    demand_tier,
    total_orders,
    unique_products,
    ROUND(avg_demand_forecast, 1) AS avg_demand_forecast,
    min_demand_forecast,
    max_demand_forecast,
    
    -- Inventory metrics
    ROUND(avg_inventory_level, 0) AS avg_inventory_level,
    ROUND(avg_inventory_turnover, 2) AS avg_inventory_turnover,
    ROUND(avg_stockout_rate * 100, 2) AS avg_stockout_rate_pct,
    
    -- Inventory positioning
    understocked_products,
    overstocked_products,
    well_stocked_products,
    ROUND(well_stocked_products::FLOAT / NULLIF(total_orders, 0) * 100, 2) 
      AS well_stocked_pct,
    
    -- Fulfillment performance
    delivered_orders,
    cancelled_orders,
    pending_orders,
    ROUND(fulfillment_rate * 100, 2) AS fulfillment_rate_pct,
    ROUND(cancellation_rate * 100, 2) AS cancellation_rate_pct,
    
    -- Revenue metrics
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_revenue / NULLIF(avg_demand_forecast, 0), 2) AS revenue_per_forecast_unit,
    
    -- Quality indicators
    ROUND(avg_product_rating, 2) AS avg_product_rating,
    ROUND(avg_review_count, 0) AS avg_review_count,
    ROUND(avg_customer_satisfaction * 100, 2) AS avg_customer_satisfaction_pct,
    
    -- Customer value
    ROUND(high_value_customer_pct * 100, 2) AS high_value_customer_pct,
    
    -- Demand responsiveness
    ROUND(avg_price_elasticity, 3) AS avg_price_elasticity,
    
    -- Forecast quality score (0-100)
    ROUND(
      (
        -- Fulfillment rate (30 points)
        (fulfillment_rate * 30) +
        -- Inventory positioning (25 points)
        ((well_stocked_products::FLOAT / NULLIF(total_orders, 0)) * 25) +
        -- Low stockout rate (20 points)
        (CASE WHEN avg_stockout_rate < 0.03 THEN 20
              WHEN avg_stockout_rate < 0.06 THEN 15
              ELSE 5 END) +
        -- Customer satisfaction (15 points)
        (avg_customer_satisfaction * 15) +
        -- Product rating (10 points)
        ((avg_product_rating / 5.0) * 10)
      ), 0
    ) AS forecast_accuracy_score,
    
    last_sync_time
    
  FROM forecast_tier_analysis
)

SELECT
  demand_tier,
  
  -- Volume
  total_orders,
  unique_products,
  avg_demand_forecast,
  min_demand_forecast,
  max_demand_forecast,
  
  -- Inventory metrics
  avg_inventory_level,
  avg_inventory_turnover,
  avg_stockout_rate_pct,
  
  -- Inventory balance
  understocked_products,
  overstocked_products,
  well_stocked_products,
  well_stocked_pct,
  
  -- Order fulfillment
  delivered_orders,
  cancelled_orders,
  pending_orders,
  fulfillment_rate_pct,
  cancellation_rate_pct,
  
  -- Financial performance
  total_revenue,
  avg_order_value,
  revenue_per_forecast_unit,
  
  -- Quality metrics
  avg_product_rating,
  avg_review_count,
  avg_customer_satisfaction_pct,
  
  -- Customer segment
  high_value_customer_pct,
  
  -- Market responsiveness
  avg_price_elasticity,
  
  -- Overall assessment
  forecast_accuracy_score,
  CASE
    WHEN forecast_accuracy_score >= 80 THEN 'Excellent Forecast Quality'
    WHEN forecast_accuracy_score >= 60 THEN 'Good Forecast Quality'
    WHEN forecast_accuracy_score >= 40 THEN 'Fair - Needs Improvement'
    ELSE 'Poor - Revise Forecasting Model'
  END AS forecast_quality_status,
  
  -- Recommendations
  CASE
    WHEN cancellation_rate_pct > 30 THEN 
      'High cancellations indicate demand overestimation'
    WHEN understocked_products > overstocked_products * 2 THEN 
      'Increase safety stock for this demand tier'
    WHEN overstocked_products > understocked_products * 2 THEN 
      'Reduce inventory investment for this demand tier'
    WHEN avg_stockout_rate_pct > 6 THEN 
      'Improve inventory replenishment frequency'
    WHEN fulfillment_rate_pct < 70 THEN 
      'Investigate fulfillment process bottlenecks'
    ELSE 'Maintain current forecasting approach'
  END AS recommended_action,
  
  last_sync_time

FROM forecast_accuracy_metrics
ORDER BY 
  CASE demand_tier
    WHEN 'Very High Demand (76+)' THEN 1
    WHEN 'High Demand (51-75)' THEN 2
    WHEN 'Medium Demand (26-50)' THEN 3
    WHEN 'Low Demand (1-25)' THEN 4
  END
