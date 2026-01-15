{{
  config(
    materialized='view',
    tags=['cpg', 'analytics', 'customer', 'segmentation']
  )
}}

/*
  CPG Customer Segment Performance
  
  Purpose: Analyze customer lifetime value, order behavior, and satisfaction
  metrics across High-Value, Medium-Value, and Low-Value customer segments.
  
  Key Metrics:
  - Average LTV by segment
  - Order frequency and AOV patterns
  - Customer satisfaction rates
  - Product preference by segment
  
  Business Value: Identify high-value customer behaviors to inform acquisition
  strategy and improve low-value segment conversion tactics.
*/

WITH base_data AS (
  SELECT
    customer_id,
    customer_segment,
    customer_ltv,
    order_frequency,
    average_order_value,
    customer_satisfaction_rate,
    order_total,
    order_status,
    product_category,
    product_rating,
    product_review_count,
    price_optimization_flag,
    price_optimization_result,
    revenue_growth_rate,
    _fivetran_synced
  FROM {{ source('cpg', 'cpg_records') }}
  WHERE _fivetran_deleted = FALSE
),

segment_metrics AS (
  SELECT
    customer_segment,
    
    -- Customer counts
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) AS total_orders,
    COUNT(*)::FLOAT / NULLIF(COUNT(DISTINCT customer_id), 0) AS orders_per_customer,
    
    -- LTV metrics
    AVG(customer_ltv) AS avg_customer_ltv,
    MIN(customer_ltv) AS min_customer_ltv,
    MAX(customer_ltv) AS max_customer_ltv,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY customer_ltv) AS median_customer_ltv,
    STDDEV(customer_ltv) AS stddev_customer_ltv,
    
    -- Order behavior
    AVG(order_frequency) AS avg_order_frequency,
    AVG(average_order_value) AS avg_order_value,
    AVG(order_total) AS avg_current_order_value,
    SUM(order_total) AS total_segment_revenue,
    
    -- Satisfaction metrics
    AVG(customer_satisfaction_rate) AS avg_satisfaction_rate,
    AVG(product_rating) AS avg_product_rating,
    AVG(product_review_count) AS avg_review_engagement,
    
    -- Order fulfillment
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS delivery_rate,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS cancellation_rate,
    
    -- Pricing optimization engagement
    COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END) AS optimized_orders,
    COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) AS optimization_exposure_rate,
    COUNT(CASE WHEN price_optimization_result = 'Success' THEN 1 END)::FLOAT / 
      NULLIF(COUNT(CASE WHEN price_optimization_flag = TRUE THEN 1 END), 0) 
      AS optimization_success_rate,
    
    -- Growth metrics
    AVG(revenue_growth_rate) AS avg_revenue_growth_rate,
    
    -- Data freshness
    MAX(_fivetran_synced) AS last_sync_time
    
  FROM base_data
  GROUP BY customer_segment
),

category_preferences AS (
  SELECT
    customer_segment,
    product_category,
    COUNT(*) AS category_orders,
    SUM(order_total) AS category_revenue,
    ROW_NUMBER() OVER (
      PARTITION BY customer_segment 
      ORDER BY COUNT(*) DESC
    ) AS category_rank
  FROM base_data
  GROUP BY customer_segment, product_category
),

top_categories AS (
  SELECT
    customer_segment,
    product_category AS preferred_category,
    category_orders,
    ROUND(category_revenue, 2) AS category_revenue
  FROM category_preferences
  WHERE category_rank = 1
),

segment_analysis AS (
  SELECT
    sm.customer_segment,
    
    -- Customer metrics
    sm.unique_customers,
    sm.total_orders,
    ROUND(sm.orders_per_customer, 1) AS orders_per_customer,
    
    -- LTV analysis
    ROUND(sm.avg_customer_ltv, 2) AS avg_customer_ltv,
    ROUND(sm.min_customer_ltv, 2) AS min_customer_ltv,
    ROUND(sm.max_customer_ltv, 2) AS max_customer_ltv,
    ROUND(sm.median_customer_ltv, 2) AS median_customer_ltv,
    ROUND(sm.stddev_customer_ltv, 2) AS ltv_variability,
    
    -- Order behavior
    ROUND(sm.avg_order_frequency, 1) AS avg_order_frequency,
    ROUND(sm.avg_order_value, 2) AS avg_order_value,
    ROUND(sm.avg_current_order_value, 2) AS avg_current_order_value,
    ROUND(sm.total_segment_revenue, 2) AS total_segment_revenue,
    
    -- Revenue per customer
    ROUND(sm.total_segment_revenue / NULLIF(sm.unique_customers, 0), 2) 
      AS revenue_per_customer,
    
    -- Satisfaction
    ROUND(sm.avg_satisfaction_rate * 100, 2) AS avg_satisfaction_rate_pct,
    ROUND(sm.avg_product_rating, 2) AS avg_product_rating,
    ROUND(sm.avg_review_engagement, 0) AS avg_reviews_per_product,
    
    -- Fulfillment
    sm.delivered_orders,
    sm.cancelled_orders,
    ROUND(sm.delivery_rate * 100, 2) AS delivery_rate_pct,
    ROUND(sm.cancellation_rate * 100, 2) AS cancellation_rate_pct,
    
    -- Pricing optimization
    sm.optimized_orders,
    ROUND(sm.optimization_exposure_rate * 100, 2) AS optimization_exposure_rate_pct,
    ROUND(sm.optimization_success_rate * 100, 2) AS optimization_success_rate_pct,
    
    -- Growth
    ROUND(sm.avg_revenue_growth_rate * 100, 2) AS avg_revenue_growth_rate_pct,
    
    -- Category preferences
    tc.preferred_category,
    tc.category_orders AS preferred_category_orders,
    tc.category_revenue AS preferred_category_revenue,
    
    -- Segment health score (0-100)
    ROUND(
      (
        -- LTV contribution (40 points)
        (sm.avg_customer_ltv / 10000.0 * 40) +
        -- Order frequency (20 points)
        (sm.avg_order_frequency / 10.0 * 20) +
        -- Satisfaction (20 points)
        (sm.avg_satisfaction_rate * 20) +
        -- Delivery rate (20 points)
        (sm.delivery_rate * 20)
      ), 0
    ) AS segment_health_score,
    
    sm.last_sync_time
    
  FROM segment_metrics sm
  LEFT JOIN top_categories tc ON sm.customer_segment = tc.customer_segment
)

SELECT
  customer_segment,
  
  -- Customer base
  unique_customers,
  total_orders,
  orders_per_customer,
  
  -- Lifetime value
  avg_customer_ltv,
  min_customer_ltv,
  max_customer_ltv,
  median_customer_ltv,
  ltv_variability,
  
  -- Purchasing behavior
  avg_order_frequency,
  avg_order_value,
  avg_current_order_value,
  total_segment_revenue,
  revenue_per_customer,
  
  -- Customer experience
  avg_satisfaction_rate_pct,
  avg_product_rating,
  avg_reviews_per_product,
  
  -- Operational metrics
  delivered_orders,
  cancelled_orders,
  delivery_rate_pct,
  cancellation_rate_pct,
  
  -- Pricing strategy response
  optimized_orders,
  optimization_exposure_rate_pct,
  optimization_success_rate_pct,
  
  -- Growth trajectory
  avg_revenue_growth_rate_pct,
  
  -- Product preferences
  preferred_category,
  preferred_category_orders,
  preferred_category_revenue,
  
  -- Segment assessment
  segment_health_score,
  CASE
    WHEN segment_health_score >= 75 THEN 'Excellent - Retain & Grow'
    WHEN segment_health_score >= 50 THEN 'Good - Nurture'
    WHEN segment_health_score >= 25 THEN 'Fair - Improve Experience'
    ELSE 'At Risk - Intervention Needed'
  END AS segment_health_status,
  
  -- Strategic recommendations
  CASE
    WHEN customer_segment = 'High-Value' THEN 
      'Focus on retention, exclusive offers, premium service'
    WHEN customer_segment = 'Medium-Value' AND avg_order_frequency < 5 THEN 
      'Increase engagement through loyalty programs'
    WHEN customer_segment = 'Medium-Value' THEN 
      'Upsell to increase AOV, targeted cross-sell'
    WHEN customer_segment = 'Low-Value' AND cancellation_rate_pct > 30 THEN 
      'Address fulfillment issues, improve product quality'
    WHEN customer_segment = 'Low-Value' THEN 
      'Reactivation campaigns, value demonstration'
    ELSE 'Monitor and maintain'
  END AS recommended_strategy,
  
  last_sync_time

FROM segment_analysis
ORDER BY 
  CASE customer_segment
    WHEN 'High-Value' THEN 1
    WHEN 'Medium-Value' THEN 2
    WHEN 'Low-Value' THEN 3
  END
