{{
    config(
        materialized='view',
        tags=['fpr', 'analytics', 'churn', 'retention']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
    WHERE _fivetran_deleted = FALSE
),

risk_categorization AS (
    SELECT
        *,
        CASE
            WHEN customer_churn_probability >= 0.7 THEN 'High Risk'
            WHEN customer_churn_probability >= 0.4 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_category
    FROM source
),

churn_analysis AS (
    SELECT
        risk_category,
        customer_segment,
        customer_lifecycle_stage AS lifecycle_stage,
        product_type,
        
        -- Customer counts and churn metrics
        COUNT(DISTINCT customer_id) AS customer_count,
        ROUND(AVG(customer_churn_probability), 4) AS avg_churn_probability,
        ROUND(AVG(customer_satisfaction_score), 4) AS avg_satisfaction_score,
        
        -- Financial impact
        ROUND(SUM(account_balance), 2) AS total_account_balance,
        ROUND(AVG(account_balance), 2) AS avg_account_balance,
        ROUND(AVG(customer_transaction_value), 2) AS avg_transaction_value,
        ROUND(AVG(customer_transaction_count), 1) AS avg_transaction_count,
        
        -- Engagement metrics
        ROUND(
            AVG(
                CASE 
                    WHEN customer_lifecycle_stage_transition_date IS NOT NULL
                    THEN DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE())
                END
            ),
            1
        ) AS avg_days_since_lifecycle_change,
        
        -- Recommendation performance for at-risk customers
        ROUND(
            100.0 * SUM(CASE WHEN product_recommendation_status IN ('Declined', 'Rejected') THEN 1 ELSE 0 END) / 
            NULLIF(COUNT(*), 0),
            2
        ) AS declined_recommendations_pct
        
    FROM risk_categorization
    GROUP BY 
        risk_category,
        customer_segment,
        customer_lifecycle_stage,
        product_type
),

final AS (
    SELECT
        risk_category,
        customer_segment,
        lifecycle_stage,
        product_type,
        customer_count,
        avg_churn_probability,
        avg_satisfaction_score,
        total_account_balance,
        avg_account_balance,
        avg_transaction_value,
        avg_transaction_count,
        avg_days_since_lifecycle_change,
        declined_recommendations_pct,
        (SELECT MAX(_fivetran_synced) FROM source) AS last_synced_at
    FROM churn_analysis
    WHERE customer_count > 0
)

SELECT * FROM final
ORDER BY 
    CASE risk_category
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
    END,
    total_account_balance DESC,
    customer_count DESC
