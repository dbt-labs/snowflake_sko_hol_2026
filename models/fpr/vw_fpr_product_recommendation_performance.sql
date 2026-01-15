{{
    config(
        materialized='view',
        tags=['fpr', 'analytics', 'recommendations', 'conversion']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
    WHERE _fivetran_deleted = FALSE
),

recommendation_analysis AS (
    SELECT
        product_recommendation AS recommended_product,
        product_type AS actual_product_type,
        customer_segment,
        
        -- Recommendation counts by status
        COUNT(*) AS total_recommendations,
        SUM(CASE WHEN product_recommendation_status = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
        SUM(CASE WHEN product_recommendation_status = 'Pending' THEN 1 ELSE 0 END) AS pending_count,
        SUM(CASE WHEN product_recommendation_status IN ('Declined', 'Rejected') THEN 1 ELSE 0 END) AS declined_count,
        SUM(CASE WHEN product_recommendation_status IN ('Accepted', 'In Progress') THEN 1 ELSE 0 END) AS in_progress_count,
        
        -- Approval rate calculation
        ROUND(
            100.0 * SUM(CASE WHEN product_recommendation_status = 'Approved' THEN 1 ELSE 0 END) / 
            NULLIF(COUNT(*), 0), 
            2
        ) AS approval_rate_pct,
        
        -- Average scores
        ROUND(AVG(recommendation_score), 4) AS avg_recommendation_score,
        ROUND(
            AVG(CASE WHEN product_recommendation_status = 'Approved' THEN recommendation_score END), 
            4
        ) AS avg_approved_score,
        ROUND(
            AVG(CASE WHEN product_recommendation_status IN ('Declined', 'Rejected') THEN recommendation_score END), 
            4
        ) AS avg_declined_score,
        ROUND(AVG(customer_product_affinity), 4) AS avg_product_affinity,
        
        -- Time to decision (days from recommendation to lifecycle transition)
        ROUND(
            AVG(
                CASE 
                    WHEN product_recommendation_date IS NOT NULL 
                    AND customer_lifecycle_stage_transition_date IS NOT NULL
                    AND customer_lifecycle_stage_transition_date >= product_recommendation_date
                    THEN DATEDIFF(day, product_recommendation_date, customer_lifecycle_stage_transition_date)
                END
            ),
            1
        ) AS avg_days_to_decision,
        
        -- Sales metrics for approved recommendations
        ROUND(
            SUM(CASE WHEN product_recommendation_status = 'Approved' THEN product_sales_amount ELSE 0 END),
            2
        ) AS total_sales_amount,
        ROUND(
            AVG(CASE WHEN product_recommendation_status = 'Approved' THEN product_sales_amount END),
            2
        ) AS avg_sales_amount
        
    FROM source
    WHERE product_recommendation IS NOT NULL
    GROUP BY 
        product_recommendation,
        product_type,
        customer_segment
),

final AS (
    SELECT
        recommended_product,
        actual_product_type,
        customer_segment,
        total_recommendations,
        approved_count,
        pending_count,
        declined_count,
        in_progress_count,
        approval_rate_pct,
        avg_recommendation_score,
        avg_approved_score,
        avg_declined_score,
        avg_product_affinity,
        avg_days_to_decision,
        total_sales_amount,
        avg_sales_amount,
        (SELECT MAX(_fivetran_synced) FROM source) AS last_synced_at
    FROM recommendation_analysis
    WHERE total_recommendations > 0
)

SELECT * FROM final
ORDER BY 
    total_recommendations DESC,
    approval_rate_pct DESC,
    recommended_product,
    customer_segment
