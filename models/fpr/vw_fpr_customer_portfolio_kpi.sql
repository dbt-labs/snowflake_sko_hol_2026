{{
    config(
        materialized='view',
        tags=['fpr', 'analytics', 'kpi', 'executive']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
    WHERE _fivetran_deleted = FALSE
),

portfolio_overview AS (
    SELECT
        'Portfolio Overview' AS metric_category,
        'Total Customers' AS metric_name,
        COUNT(DISTINCT customer_id) AS metric_value,
        NULL AS segment_detail,
        NULL AS lifecycle_detail,
        NULL AS product_detail
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Total Account Balance',
        ROUND(SUM(account_balance), 2),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Average Account Balance',
        ROUND(AVG(account_balance), 2),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Total Transaction Value',
        ROUND(SUM(customer_transaction_value), 2),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Total Transaction Count',
        SUM(customer_transaction_count),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Average Customer Satisfaction',
        ROUND(AVG(customer_satisfaction_score), 4),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Average Churn Probability',
        ROUND(AVG(customer_churn_probability), 4),
        NULL,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Portfolio Overview',
        'Average Product Affinity',
        ROUND(AVG(customer_product_affinity), 4),
        NULL,
        NULL,
        NULL
    FROM source
),

segment_metrics AS (
    SELECT
        'Customer Segments' AS metric_category,
        'Customers by Segment' AS metric_name,
        COUNT(DISTINCT customer_id) AS metric_value,
        customer_segment AS segment_detail,
        NULL AS lifecycle_detail,
        NULL AS product_detail
    FROM source
    GROUP BY customer_segment
    
    UNION ALL
    
    SELECT
        'Customer Segments',
        'Avg Balance by Segment',
        ROUND(AVG(account_balance), 2),
        customer_segment,
        NULL,
        NULL
    FROM source
    GROUP BY customer_segment
    
    UNION ALL
    
    SELECT
        'Customer Segments',
        'Avg Churn Risk by Segment',
        ROUND(AVG(customer_churn_probability), 4),
        customer_segment,
        NULL,
        NULL
    FROM source
    GROUP BY customer_segment
),

lifecycle_metrics AS (
    SELECT
        'Lifecycle Stages' AS metric_category,
        'Customers by Lifecycle' AS metric_name,
        COUNT(DISTINCT customer_id) AS metric_value,
        NULL AS segment_detail,
        customer_lifecycle_stage AS lifecycle_detail,
        NULL AS product_detail
    FROM source
    GROUP BY customer_lifecycle_stage
    
    UNION ALL
    
    SELECT
        'Lifecycle Stages',
        'Avg Balance by Lifecycle',
        ROUND(AVG(account_balance), 2),
        NULL,
        customer_lifecycle_stage,
        NULL
    FROM source
    GROUP BY customer_lifecycle_stage
    
    UNION ALL
    
    SELECT
        'Lifecycle Stages',
        'Avg Satisfaction by Lifecycle',
        ROUND(AVG(customer_satisfaction_score), 4),
        NULL,
        customer_lifecycle_stage,
        NULL
    FROM source
    GROUP BY customer_lifecycle_stage
),

product_metrics AS (
    SELECT
        'Product Distribution' AS metric_category,
        'Customers by Product' AS metric_name,
        COUNT(DISTINCT customer_id) AS metric_value,
        NULL AS segment_detail,
        NULL AS lifecycle_detail,
        product_type AS product_detail
    FROM source
    GROUP BY product_type
    
    UNION ALL
    
    SELECT
        'Product Distribution',
        'Avg Balance by Product',
        ROUND(AVG(account_balance), 2),
        NULL,
        NULL,
        product_type
    FROM source
    GROUP BY product_type
    
    UNION ALL
    
    SELECT
        'Product Distribution',
        'Total Sales by Product',
        ROUND(SUM(product_sales_amount), 2),
        NULL,
        NULL,
        product_type
    FROM source
    GROUP BY product_type
),

combined_metrics AS (
    SELECT * FROM portfolio_overview
    UNION ALL
    SELECT * FROM segment_metrics
    UNION ALL
    SELECT * FROM lifecycle_metrics
    UNION ALL
    SELECT * FROM product_metrics
),

final AS (
    SELECT
        metric_category,
        metric_name,
        metric_value,
        segment_detail,
        lifecycle_detail,
        product_detail,
        (SELECT MAX(_fivetran_synced) FROM source) AS last_synced_at
    FROM combined_metrics
)

SELECT * FROM final
ORDER BY 
    metric_category,
    metric_name,
    segment_detail NULLS LAST,
    lifecycle_detail NULLS LAST,
    product_detail NULLS LAST
