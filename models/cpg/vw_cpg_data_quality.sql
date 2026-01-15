{{
  config(
    materialized='view',
    tags=['cpg', 'data_quality', 'monitoring']
  )
}}

/*
  CPG Data Quality Monitoring
  
  Purpose: Monitor data completeness, freshness, consistency, and detect anomalies
  in the CPG records to ensure reliable analytics.
  
  Key Metrics:
  - Null percentage for critical fields
  - Fivetran sync freshness
  - Duplicate detection
  - Value range validation
  - Data consistency checks
  
  Business Value: Maintain high-quality data foundation for pricing optimization,
  inventory management, and customer analytics.
*/

WITH base_data AS (
  SELECT
    record_id,
    order_id,
    customer_id,
    product_id,
    order_date,
    order_total,
    product_price,
    inventory_level,
    customer_segment,
    order_status,
    product_category,
    product_subcategory,
    customer_ltv,
    order_frequency,
    average_order_value,
    product_rating,
    product_review_count,
    price_optimization_flag,
    price_elasticity,
    demand_forecast,
    inventory_turnover,
    stockout_rate,
    overstock_rate,
    revenue_growth_rate,
    customer_satisfaction_rate,
    price_optimization_date,
    price_optimization_result,
    price_optimization_recommendation,
    _fivetran_deleted,
    _fivetran_synced
  FROM {{ source('cpg', 'cpg_records') }}
),

completeness_metrics AS (
  SELECT
    COUNT(*) AS total_records,
    COUNT(CASE WHEN _fivetran_deleted = TRUE THEN 1 END) AS deleted_records,
    COUNT(CASE WHEN _fivetran_deleted = FALSE THEN 1 END) AS active_records,
    
    -- Null checks for critical fields
    COUNT(CASE WHEN record_id IS NULL THEN 1 END) AS null_record_id,
    COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS null_order_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS null_customer_id,
    COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS null_product_id,
    COUNT(CASE WHEN order_date IS NULL THEN 1 END) AS null_order_date,
    COUNT(CASE WHEN order_total IS NULL THEN 1 END) AS null_order_total,
    COUNT(CASE WHEN product_price IS NULL THEN 1 END) AS null_product_price,
    COUNT(CASE WHEN inventory_level IS NULL THEN 1 END) AS null_inventory_level,
    COUNT(CASE WHEN customer_segment IS NULL THEN 1 END) AS null_customer_segment,
    COUNT(CASE WHEN order_status IS NULL THEN 1 END) AS null_order_status,
    COUNT(CASE WHEN product_category IS NULL THEN 1 END) AS null_product_category,
    COUNT(CASE WHEN customer_ltv IS NULL THEN 1 END) AS null_customer_ltv,
    COUNT(CASE WHEN price_elasticity IS NULL THEN 1 END) AS null_price_elasticity,
    COUNT(CASE WHEN demand_forecast IS NULL THEN 1 END) AS null_demand_forecast,
    
    -- Completeness percentage
    100.0 - (COUNT(CASE WHEN record_id IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS record_id_completeness,
    100.0 - (COUNT(CASE WHEN order_date IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS order_date_completeness,
    100.0 - (COUNT(CASE WHEN customer_segment IS NULL THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0) * 100) AS customer_segment_completeness
      
  FROM base_data
),

duplicate_detection AS (
  SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT record_id) AS unique_record_ids,
    COUNT(*) - COUNT(DISTINCT record_id) AS duplicate_record_ids,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT product_id) AS unique_product_ids
  FROM base_data
  WHERE _fivetran_deleted = FALSE
),

value_validation AS (
  SELECT
    -- Out of range values
    COUNT(CASE WHEN order_total < 0 THEN 1 END) AS negative_order_totals,
    COUNT(CASE WHEN product_price < 0 THEN 1 END) AS negative_product_prices,
    COUNT(CASE WHEN inventory_level < 0 THEN 1 END) AS negative_inventory_levels,
    COUNT(CASE WHEN customer_ltv < 0 THEN 1 END) AS negative_ltv,
    COUNT(CASE WHEN product_rating < 1 OR product_rating > 5 THEN 1 END) AS invalid_ratings,
    COUNT(CASE WHEN price_elasticity < 0 OR price_elasticity > 1 THEN 1 END) AS invalid_elasticity,
    COUNT(CASE WHEN stockout_rate < 0 OR stockout_rate > 1 THEN 1 END) AS invalid_stockout_rate,
    COUNT(CASE WHEN overstock_rate < 0 OR overstock_rate > 1 THEN 1 END) AS invalid_overstock_rate,
    COUNT(CASE WHEN customer_satisfaction_rate < 0 OR customer_satisfaction_rate > 1 THEN 1 END) 
      AS invalid_satisfaction_rate,
    
    -- Logical inconsistencies
    COUNT(CASE WHEN order_total = 0 AND order_status = 'Delivered' THEN 1 END) AS zero_value_delivered,
    COUNT(CASE WHEN inventory_level = 0 AND order_status = 'Delivered' THEN 1 END) AS zero_inventory_delivered,
    COUNT(CASE WHEN price_optimization_flag = TRUE AND price_optimization_result IS NULL THEN 1 END) 
      AS missing_optimization_results,
    
    -- Extreme outliers (potential data quality issues)
    COUNT(CASE WHEN order_total > 10000 THEN 1 END) AS extreme_high_order_values,
    COUNT(CASE WHEN product_price > 10000 THEN 1 END) AS extreme_high_product_prices,
    COUNT(CASE WHEN inventory_level > 1000 THEN 1 END) AS extreme_high_inventory,
    COUNT(CASE WHEN customer_ltv > 100000 THEN 1 END) AS extreme_high_ltv
    
  FROM base_data
  WHERE _fivetran_deleted = FALSE
),

freshness_metrics AS (
  SELECT
    MAX(TO_TIMESTAMP(_fivetran_synced)) AS last_sync_time,
    MIN(TO_TIMESTAMP(_fivetran_synced)) AS earliest_sync_time,
    COUNT(DISTINCT DATE_TRUNC('day', TO_TIMESTAMP(_fivetran_synced))) AS sync_days,
    COUNT(DISTINCT DATE_TRUNC('day', TO_DATE(order_date))) AS order_date_days,
    MIN(TO_DATE(order_date)) AS earliest_order_date,
    MAX(TO_DATE(order_date)) AS latest_order_date
  FROM base_data
  WHERE _fivetran_deleted = FALSE
),

categorical_consistency AS (
  SELECT
    COUNT(DISTINCT customer_segment) AS unique_customer_segments,
    COUNT(DISTINCT order_status) AS unique_order_statuses,
    COUNT(DISTINCT product_category) AS unique_product_categories,
    COUNT(DISTINCT product_subcategory) AS unique_product_subcategories,
    COUNT(DISTINCT price_optimization_result) AS unique_optimization_results,
    COUNT(DISTINCT price_optimization_recommendation) AS unique_optimization_recommendations,
    
    -- Expected vs actual category counts
    CASE 
      WHEN COUNT(DISTINCT customer_segment) != 3 THEN 'Unexpected segment values'
      ELSE 'Valid'
    END AS segment_validation,
    CASE 
      WHEN COUNT(DISTINCT order_status) != 4 THEN 'Unexpected status values'
      ELSE 'Valid'
    END AS status_validation
    
  FROM base_data
  WHERE _fivetran_deleted = FALSE
)

SELECT
  -- Record counts
  cm.total_records,
  cm.deleted_records,
  cm.active_records,
  ROUND(cm.active_records::FLOAT / NULLIF(cm.total_records, 0) * 100, 2) AS active_record_pct,
  
  -- Completeness metrics
  cm.null_record_id,
  cm.null_order_id,
  cm.null_customer_id,
  cm.null_product_id,
  cm.null_order_date,
  cm.null_order_total,
  cm.null_product_price,
  cm.null_inventory_level,
  cm.null_customer_segment,
  cm.null_order_status,
  cm.null_product_category,
  cm.null_customer_ltv,
  cm.null_price_elasticity,
  cm.null_demand_forecast,
  
  ROUND(cm.record_id_completeness, 2) AS record_id_completeness_pct,
  ROUND(cm.order_date_completeness, 2) AS order_date_completeness_pct,
  ROUND(cm.customer_segment_completeness, 2) AS customer_segment_completeness_pct,
  
  -- Overall completeness score
  ROUND(
    (cm.record_id_completeness + cm.order_date_completeness + cm.customer_segment_completeness) / 3.0, 
    2
  ) AS overall_completeness_score,
  
  -- Duplicate detection
  dd.unique_record_ids,
  dd.duplicate_record_ids,
  dd.unique_order_ids,
  dd.unique_customer_ids,
  dd.unique_product_ids,
  
  -- Duplicate percentage
  ROUND(dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 100, 2) AS duplicate_pct,
  
  -- Value validation issues
  vv.negative_order_totals,
  vv.negative_product_prices,
  vv.negative_inventory_levels,
  vv.negative_ltv,
  vv.invalid_ratings,
  vv.invalid_elasticity,
  vv.invalid_stockout_rate,
  vv.invalid_overstock_rate,
  vv.invalid_satisfaction_rate,
  
  -- Logical consistency issues
  vv.zero_value_delivered,
  vv.zero_inventory_delivered,
  vv.missing_optimization_results,
  
  -- Outlier detection
  vv.extreme_high_order_values,
  vv.extreme_high_product_prices,
  vv.extreme_high_inventory,
  vv.extreme_high_ltv,
  
  -- Total validation issues
  (vv.negative_order_totals + vv.negative_product_prices + vv.negative_inventory_levels +
   vv.negative_ltv + vv.invalid_ratings + vv.invalid_elasticity + vv.invalid_stockout_rate +
   vv.invalid_overstock_rate + vv.invalid_satisfaction_rate + vv.zero_value_delivered +
   vv.zero_inventory_delivered + vv.missing_optimization_results) AS total_validation_issues,
  
  -- Data quality score (0-100)
  ROUND(
    100 - (
      -- Completeness impact (40 points)
      ((cm.null_order_date + cm.null_customer_segment + cm.null_product_category)::FLOAT / 
        NULLIF(cm.active_records, 0) * 40) +
      -- Duplicate impact (20 points)
      (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
      -- Validation issues impact (40 points)
      ((vv.negative_order_totals + vv.negative_product_prices + vv.invalid_ratings + 
        vv.invalid_elasticity)::FLOAT / NULLIF(cm.active_records, 0) * 40)
    ), 0
  ) AS overall_data_quality_score,
  
  -- Freshness metrics
  fm.last_sync_time,
  fm.earliest_sync_time,
  DATEDIFF('hour', fm.last_sync_time, CURRENT_TIMESTAMP()) AS hours_since_last_sync,
  DATEDIFF('day', fm.last_sync_time, CURRENT_TIMESTAMP()) AS days_since_last_sync,
  fm.sync_days AS unique_sync_days,
  fm.order_date_days AS unique_order_date_days,
  fm.earliest_order_date,
  fm.latest_order_date,
  DATEDIFF('day', fm.earliest_order_date, fm.latest_order_date) AS order_date_range_days,
  
  -- Freshness status
  CASE
    WHEN DATEDIFF('hour', fm.last_sync_time, CURRENT_TIMESTAMP()) <= 24 THEN 'Fresh (< 24 hours)'
    WHEN DATEDIFF('hour', fm.last_sync_time, CURRENT_TIMESTAMP()) <= 72 THEN 'Recent (< 3 days)'
    WHEN DATEDIFF('hour', fm.last_sync_time, CURRENT_TIMESTAMP()) <= 168 THEN 'Aging (< 1 week)'
    ELSE 'Stale (> 1 week)'
  END AS data_freshness_status,
  
  -- Categorical consistency
  cc.unique_customer_segments,
  cc.unique_order_statuses,
  cc.unique_product_categories,
  cc.unique_product_subcategories,
  cc.unique_optimization_results,
  cc.unique_optimization_recommendations,
  cc.segment_validation,
  cc.status_validation,
  
  -- Overall health assessment
  CASE
    WHEN ROUND(
      100 - (
        ((cm.null_order_date + cm.null_customer_segment + cm.null_product_category)::FLOAT / 
          NULLIF(cm.active_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.negative_order_totals + vv.negative_product_prices + vv.invalid_ratings + 
          vv.invalid_elasticity)::FLOAT / NULLIF(cm.active_records, 0) * 40)
      ), 0
    ) >= 95 THEN 'Excellent'
    WHEN ROUND(
      100 - (
        ((cm.null_order_date + cm.null_customer_segment + cm.null_product_category)::FLOAT / 
          NULLIF(cm.active_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.negative_order_totals + vv.negative_product_prices + vv.invalid_ratings + 
          vv.invalid_elasticity)::FLOAT / NULLIF(cm.active_records, 0) * 40)
      ), 0
    ) >= 80 THEN 'Good'
    WHEN ROUND(
      100 - (
        ((cm.null_order_date + cm.null_customer_segment + cm.null_product_category)::FLOAT / 
          NULLIF(cm.active_records, 0) * 40) +
        (dd.duplicate_record_ids::FLOAT / NULLIF(dd.total_records, 0) * 20) +
        ((vv.negative_order_totals + vv.negative_product_prices + vv.invalid_ratings + 
          vv.invalid_elasticity)::FLOAT / NULLIF(cm.active_records, 0) * 40)
      ), 0
    ) >= 60 THEN 'Fair - Monitor Closely'
    ELSE 'Poor - Immediate Action Required'
  END AS data_quality_status,
  
  -- Recommended actions
  CASE
    WHEN (cm.null_order_date + cm.null_customer_segment + cm.null_product_category) > 0 
      THEN 'Address missing critical fields in source system'
    WHEN dd.duplicate_record_ids > 0 
      THEN 'Investigate and resolve duplicate records'
    WHEN (vv.negative_order_totals + vv.negative_product_prices) > 0 
      THEN 'Fix negative value data quality issues'
    WHEN DATEDIFF('hour', fm.last_sync_time, CURRENT_TIMESTAMP()) > 72 
      THEN 'Check Fivetran connector sync status'
    WHEN cc.segment_validation != 'Valid' OR cc.status_validation != 'Valid' 
      THEN 'Review categorical value consistency'
    ELSE 'Data quality is healthy - continue monitoring'
  END AS recommended_action

FROM completeness_metrics cm
CROSS JOIN duplicate_detection dd
CROSS JOIN value_validation vv
CROSS JOIN freshness_metrics fm
CROSS JOIN categorical_consistency cc
