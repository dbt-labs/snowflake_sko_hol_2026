{{
    config(
        materialized='view',
        tags=['fpr', 'alerts', 'operations', 'retention']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
    WHERE _fivetran_deleted = FALSE
),

-- Alert Type 1: High Balance + High Churn Risk
high_balance_churn_risk AS (
    SELECT
        'Critical' AS alert_priority,
        'High Balance + High Churn' AS alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        customer_lifecycle_stage AS lifecycle_stage,
        account_balance,
        customer_churn_probability AS churn_probability,
        customer_satisfaction_score AS satisfaction_score,
        customer_transaction_value AS transaction_value,
        product_type,
        customer_product_affinity AS product_affinity,
        product_recommendation_status AS recommendation_status,
        DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) AS days_since_lifecycle_change,
        DATEDIFF(day, product_recommendation_date, CURRENT_DATE()) AS days_since_recommendation,
        CONCAT(
            'Customer has $', ROUND(account_balance, 2), 
            ' balance with ', ROUND(customer_churn_probability * 100, 1), 
            '% churn risk. Immediate retention intervention required.'
        ) AS alert_reason,
        'Schedule executive relationship review and personalized retention offer' AS recommended_action
    FROM source
    WHERE account_balance > 75000
    AND customer_churn_probability > 0.6
    AND customer_lifecycle_stage IN ('Active', 'Engaged', 'Converted')
),

-- Alert Type 2: Active Customers with Recent Declined Recommendations
declined_recommendations AS (
    SELECT
        'High' AS alert_priority,
        'Declined Recommendation' AS alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        customer_lifecycle_stage,
        account_balance,
        customer_churn_probability,
        customer_satisfaction_score,
        customer_transaction_value,
        product_type,
        customer_product_affinity,
        product_recommendation_status,
        DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) AS days_since_lifecycle_change,
        DATEDIFF(day, product_recommendation_date, CURRENT_DATE()) AS days_since_recommendation,
        CONCAT(
            'Product recommendation declined ', days_since_recommendation, ' days ago. ',
            'Customer shows ', ROUND(customer_product_affinity * 100, 0), '% product affinity.'
        ) AS alert_reason,
        'Review declined recommendation with customer to understand concerns and refine offer' AS recommended_action
    FROM source
    WHERE product_recommendation_status IN ('Declined', 'Rejected')
    AND product_recommendation_date >= DATEADD(day, -90, CURRENT_DATE())
    AND customer_lifecycle_stage IN ('Active', 'Engaged')
),

-- Alert Type 3: Stalled Lifecycle Progression
stalled_lifecycle AS (
    SELECT
        'High' AS alert_priority,
        'Stalled Lifecycle' AS alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        customer_lifecycle_stage,
        account_balance,
        customer_churn_probability,
        customer_satisfaction_score,
        customer_transaction_value,
        product_type,
        customer_product_affinity,
        product_recommendation_status,
        DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) AS days_since_lifecycle_change,
        DATEDIFF(day, product_recommendation_date, CURRENT_DATE()) AS days_since_recommendation,
        CONCAT(
            'Customer in ', customer_lifecycle_stage, ' stage for ', days_since_lifecycle_change, 
            ' days with no progression. Account balance: $', ROUND(account_balance, 2)
        ) AS alert_reason,
        'Initiate engagement campaign to move customer to next lifecycle stage' AS recommended_action
    FROM source
    WHERE customer_lifecycle_stage IN ('Engaged', 'Lead', 'Prospect')
    AND customer_lifecycle_stage_transition_date IS NOT NULL
    AND DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) > 120
),

-- Alert Type 4: High Transaction Value but Disengaged
disengaged_high_spender AS (
    SELECT
        'Critical' AS alert_priority,
        'Disengaged High Spender' AS alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        customer_lifecycle_stage,
        account_balance,
        customer_churn_probability,
        customer_satisfaction_score,
        customer_transaction_value,
        product_type,
        customer_product_affinity,
        product_recommendation_status,
        DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) AS days_since_lifecycle_change,
        DATEDIFF(day, product_recommendation_date, CURRENT_DATE()) AS days_since_recommendation,
        CONCAT(
            'High-value customer ($', ROUND(customer_transaction_value, 2), 
            ' transaction value) showing disengagement. Churn risk: ', 
            ROUND(customer_churn_probability * 100, 1), '%'
        ) AS alert_reason,
        'Urgent: Schedule VIP customer retention meeting with relationship manager' AS recommended_action
    FROM source
    WHERE customer_transaction_value > 8000
    AND customer_lifecycle_stage IN ('Disengaged', 'Inactive', 'Dormant')
),

-- Alert Type 5: Low Satisfaction + High Product Affinity
satisfaction_affinity_mismatch AS (
    SELECT
        'Medium' AS alert_priority,
        'Low Satisfaction + High Affinity' AS alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        customer_lifecycle_stage,
        account_balance,
        customer_churn_probability,
        customer_satisfaction_score,
        customer_transaction_value,
        product_type,
        customer_product_affinity,
        product_recommendation_status,
        DATEDIFF(day, customer_lifecycle_stage_transition_date, CURRENT_DATE()) AS days_since_lifecycle_change,
        DATEDIFF(day, product_recommendation_date, CURRENT_DATE()) AS days_since_recommendation,
        CONCAT(
            'Customer shows high product interest (', ROUND(customer_product_affinity * 100, 0), 
            '%) but low satisfaction (', ROUND(customer_satisfaction_score * 100, 0), 
            '%). Service recovery opportunity.'
        ) AS alert_reason,
        'Contact customer to address satisfaction issues and convert product interest' AS recommended_action
    FROM source
    WHERE customer_satisfaction_score < 0.3
    AND customer_product_affinity > 0.8
    AND customer_lifecycle_stage NOT IN ('Churned', 'Inactive')
),

combined_alerts AS (
    SELECT * FROM high_balance_churn_risk
    UNION ALL
    SELECT * FROM declined_recommendations
    UNION ALL
    SELECT * FROM stalled_lifecycle
    UNION ALL
    SELECT * FROM disengaged_high_spender
    UNION ALL
    SELECT * FROM satisfaction_affinity_mismatch
),

final AS (
    SELECT
        alert_priority,
        alert_type,
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        lifecycle_stage,
        account_balance,
        churn_probability,
        satisfaction_score,
        transaction_value,
        product_type,
        product_affinity,
        recommendation_status,
        days_since_lifecycle_change,
        days_since_recommendation,
        alert_reason,
        recommended_action,
        (SELECT MAX(_fivetran_synced) FROM source) AS last_synced_at
    FROM combined_alerts
)

SELECT * FROM final
ORDER BY 
    CASE alert_priority
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
    END,
    account_balance DESC,
    churn_probability DESC
