{{
  config(
    materialized='view',
    tags=['cpg', 'analytics', 'inventory', 'operations']
  )
}}

/*
  CPG Inventory Health by Category
  
  Purpose: Track inventory efficiency metrics segmented by product category
  to identify categories with stockout risks or excess inventory.
  
  Key Metrics:
  - Inventory turnover rate by category
  - Stockout and overstock rates
  - Demand forecast accuracy
  - Optimal inventory levels
  
  Business Value: Optimize working capital, reduce stockouts, and minimize
  carrying costs by identifying categories needing inventory adjustments.
*/

WITH base_data AS (
  SELECT
    product_category,
    product_subcategory,
    product_id,
    order_status,
    inventory_level,
    inventory_turnover,
    stockout_rate,
    overstock_rate,
    demand_forecast,
    product_price,
    order_total,
    _fivetran_synced
  FROM {{ source('cpg', 'cpg_records') }}
  WHERE _fivetran_deleted = FALSE
),

category_metrics AS (
  SELECT
    product_category,
    
    -- Order volume metrics
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS fulfilled_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    
    -- Inventory metrics
    AVG(inventory_level) AS avg_inventory_level,
    MIN(inventory_level) AS min_inventory_level,
    MAX(inventory_level) AS max_inventory_level,
    STDDEV(inventory_level) AS stddev_inventory_level,
    
    -- Turnover analysis
    AVG(inventory_turnover) AS avg_inventory_turnover,
    MIN(inventory_turnover) AS min_inventory_turnover,
    MAX(inventory_turnover) AS max_inventory_turnover,
    
    -- Stockout risk
    AVG(stockout_rate) AS avg_stockout_rate,
    MAX(stockout_rate) AS max_stockout_rate,
    COUNT(CASE WHEN stockout_rate > 0.05 THEN 1 END) AS high_stockout_products,
    
    -- Overstock risk
    AVG(overstock_rate) AS avg_overstock_rate,
    MAX(overstock_rate) AS max_overstock_rate,
    COUNT(CASE WHEN overstock_rate > 0.07 THEN 1 END) AS high_overstock_products,
    
    -- Demand forecasting
    AVG(demand_forecast) AS avg_demand_forecast,
    SUM(demand_forecast) AS total_demand_forecast,
    
    -- Financial metrics
    SUM(order_total) AS category_revenue,
    AVG(product_price) AS avg_product_price,
    SUM(order_total) / NULLIF(SUM(demand_forecast), 0) AS revenue_per_forecast_unit,
    
    -- Product variety
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT product_subcategory) AS unique_subcategories,
    
    -- Data freshness
    MAX(_fivetran_synced) AS last_sync_time
    
  FROM base_data
  GROUP BY product_category
),

inventory_health_classification AS (
  SELECT
    product_category,
    total_orders,
    fulfilled_orders,
    cancelled_orders,
    ROUND(cancellation_rate * 100, 2) AS cancellation_rate_pct,
    
    -- Inventory levels
    ROUND(avg_inventory_level, 0) AS avg_inventory_level,
    min_inventory_level,
    max_inventory_level,
    ROUND(stddev_inventory_level, 2) AS inventory_variability,
    
    -- Turnover health
    ROUND(avg_inventory_turnover, 2) AS avg_inventory_turnover,
    ROUND(min_inventory_turnover, 2) AS min_inventory_turnover,
    ROUND(max_inventory_turnover, 2) AS max_inventory_turnover,
    CASE
      WHEN avg_inventory_turnover >= 8 THEN 'Excellent (Fast-Moving)'
      WHEN avg_inventory_turnover >= 6 THEN 'Good (Healthy)'
      WHEN avg_inventory_turnover >= 4 THEN 'Fair (Monitor)'
      ELSE 'Poor (Slow-Moving)'
    END AS turnover_health_status,
    
    -- Stockout analysis
    ROUND(avg_stockout_rate * 100, 2) AS avg_stockout_rate_pct,
    ROUND(max_stockout_rate * 100, 2) AS max_stockout_rate_pct,
    high_stockout_products,
    CASE
      WHEN avg_stockout_rate < 0.02 THEN 'Low Risk'
      WHEN avg_stockout_rate < 0.05 THEN 'Medium Risk'
      ELSE 'High Risk'
    END AS stockout_risk_level,
    
    -- Overstock analysis
    ROUND(avg_overstock_rate * 100, 2) AS avg_overstock_rate_pct,
    ROUND(max_overstock_rate * 100, 2) AS max_overstock_rate_pct,
    high_overstock_products,
    CASE
      WHEN avg_overstock_rate < 0.03 THEN 'Low Risk'
      WHEN avg_overstock_rate < 0.06 THEN 'Medium Risk'
      ELSE 'High Risk'
    END AS overstock_risk_level,
    
    -- Demand metrics
    ROUND(avg_demand_forecast, 0) AS avg_demand_forecast,
    total_demand_forecast,
    
    -- Financial performance
    ROUND(category_revenue, 2) AS category_revenue,
    ROUND(avg_product_price, 2) AS avg_product_price,
    ROUND(revenue_per_forecast_unit, 2) AS revenue_per_forecast_unit,
    
    -- Portfolio metrics
    unique_products,
    unique_subcategories,
    
    -- Overall health score (0-100)
    ROUND(
      (
        (CASE WHEN avg_inventory_turnover >= 8 THEN 25
              WHEN avg_inventory_turnover >= 6 THEN 20
              WHEN avg_inventory_turnover >= 4 THEN 15
              ELSE 10 END) +
        (CASE WHEN avg_stockout_rate < 0.02 THEN 25
              WHEN avg_stockout_rate < 0.05 THEN 15
              ELSE 5 END) +
        (CASE WHEN avg_overstock_rate < 0.03 THEN 25
              WHEN avg_overstock_rate < 0.06 THEN 15
              ELSE 5 END) +
        (CASE WHEN cancellation_rate < 0.20 THEN 25
              WHEN cancellation_rate < 0.30 THEN 15
              ELSE 5 END)
      ), 0
    ) AS inventory_health_score,
    
    last_sync_time
    
  FROM category_metrics
)

SELECT
  product_category,
  
  -- Order metrics
  total_orders,
  fulfilled_orders,
  cancelled_orders,
  cancellation_rate_pct,
  
  -- Inventory position
  avg_inventory_level,
  min_inventory_level,
  max_inventory_level,
  inventory_variability,
  
  -- Turnover analysis
  avg_inventory_turnover,
  min_inventory_turnover,
  max_inventory_turnover,
  turnover_health_status,
  
  -- Stockout risk
  avg_stockout_rate_pct,
  max_stockout_rate_pct,
  high_stockout_products,
  stockout_risk_level,
  
  -- Overstock risk
  avg_overstock_rate_pct,
  max_overstock_rate_pct,
  high_overstock_products,
  overstock_risk_level,
  
  -- Demand planning
  avg_demand_forecast,
  total_demand_forecast,
  
  -- Financial metrics
  category_revenue,
  avg_product_price,
  revenue_per_forecast_unit,
  
  -- Portfolio
  unique_products,
  unique_subcategories,
  
  -- Overall assessment
  inventory_health_score,
  CASE
    WHEN inventory_health_score >= 80 THEN 'Excellent'
    WHEN inventory_health_score >= 60 THEN 'Good'
    WHEN inventory_health_score >= 40 THEN 'Needs Attention'
    ELSE 'Critical'
  END AS overall_health_status,
  
  -- Recommended actions
  CASE
    WHEN stockout_risk_level = 'High Risk' AND overstock_risk_level = 'Low Risk' 
      THEN 'Increase inventory levels'
    WHEN overstock_risk_level = 'High Risk' AND stockout_risk_level = 'Low Risk' 
      THEN 'Reduce inventory levels'
    WHEN avg_inventory_turnover < 4 
      THEN 'Improve demand forecasting'
    WHEN cancellation_rate_pct > 30 
      THEN 'Investigate fulfillment issues'
    ELSE 'Maintain current strategy'
  END AS recommended_action,
  
  last_sync_time

FROM inventory_health_classification
ORDER BY inventory_health_score ASC, category_revenue DESC
