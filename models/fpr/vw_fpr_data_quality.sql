{{
    config(
        materialized='view',
        tags=['fpr', 'data_quality', 'monitoring']
    )
}}

WITH source AS (
    SELECT * 
    FROM {{ source('fpr', 'fpr_records') }}
),

-- Completeness checks
completeness_checks AS (
    SELECT
        'Completeness' AS quality_check_category,
        'Total Records' AS check_name,
        CAST(COUNT(*) AS VARCHAR) AS check_result,
        'Pass' AS threshold_status,
        COUNT(*) AS record_count,
        NULL AS percentage
    FROM source
    WHERE _fivetran_deleted = FALSE
    
    UNION ALL
    
    SELECT
        'Completeness',
        'Deleted Records',
        CAST(COUNT(*) AS VARCHAR),
        CASE WHEN COUNT(*) = 0 THEN 'Pass' ELSE 'Warning' END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source), 0), 2)
    FROM source
    WHERE _fivetran_deleted = TRUE
    
    UNION ALL
    
    SELECT
        'Completeness',
        'Missing Customer Email',
        CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN 100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0) > 5 THEN 'Fail'
            WHEN 100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0) > 1 THEN 'Warning'
            ELSE 'Pass'
        END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND (customer_email IS NULL OR customer_email = '')
    
    UNION ALL
    
    SELECT
        'Completeness',
        'Missing Account Balance',
        CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN COUNT(*) > 0 THEN 'Fail'
            ELSE 'Pass'
        END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND account_balance IS NULL
    
    UNION ALL
    
    SELECT
        'Completeness',
        'Missing Transaction Count',
        CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN 100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0) > 2 THEN 'Warning'
            ELSE 'Pass'
        END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND customer_transaction_count IS NULL
    
    UNION ALL
    
    SELECT
        'Completeness',
        'Missing Product Recommendation Date',
        CAST(COUNT(*) AS VARCHAR),
        'Pass',
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND product_recommendation_date IS NULL
),

-- Integrity checks
integrity_checks AS (
    SELECT
        'Integrity' AS quality_check_category,
        'Duplicate Customer IDs' AS check_name,
        CAST(COUNT(*) AS VARCHAR) AS check_result,
        CASE WHEN COUNT(*) > 0 THEN 'Warning' ELSE 'Pass' END AS threshold_status,
        COUNT(*) AS record_count,
        NULL AS percentage
    FROM (
        SELECT customer_id, COUNT(*) AS duplicate_count
        FROM source
        WHERE _fivetran_deleted = FALSE
        GROUP BY customer_id
        HAVING COUNT(*) > 1
    ) duplicates
    
    UNION ALL
    
    SELECT
        'Integrity',
        'Records with Status but No Recommendation Date',
        CAST(COUNT(*) AS VARCHAR),
        CASE WHEN COUNT(*) > 0 THEN 'Warning' ELSE 'Pass' END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND product_recommendation_status IS NOT NULL
    AND product_recommendation_date IS NULL
),

-- Validity checks
validity_checks AS (
    SELECT
        'Validity' AS quality_check_category,
        'Invalid Recommendation Score' AS check_name,
        CAST(COUNT(*) AS VARCHAR) AS check_result,
        CASE WHEN COUNT(*) > 0 THEN 'Fail' ELSE 'Pass' END AS threshold_status,
        COUNT(*) AS record_count,
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2) AS percentage
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND (recommendation_score < 0 OR recommendation_score > 1)
    
    UNION ALL
    
    SELECT
        'Validity',
        'Invalid Churn Probability',
        CAST(COUNT(*) AS VARCHAR),
        CASE WHEN COUNT(*) > 0 THEN 'Fail' ELSE 'Pass' END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND (customer_churn_probability < 0 OR customer_churn_probability > 1)
    
    UNION ALL
    
    SELECT
        'Validity',
        'Invalid Satisfaction Score',
        CAST(COUNT(*) AS VARCHAR),
        CASE WHEN COUNT(*) > 0 THEN 'Fail' ELSE 'Pass' END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND (customer_satisfaction_score < 0 OR customer_satisfaction_score > 1)
    
    UNION ALL
    
    SELECT
        'Validity',
        'Invalid Product Affinity',
        CAST(COUNT(*) AS VARCHAR),
        CASE WHEN COUNT(*) > 0 THEN 'Fail' ELSE 'Pass' END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND (customer_product_affinity < 0 OR customer_product_affinity > 1)
    
    UNION ALL
    
    SELECT
        'Validity',
        'Negative Account Balance',
        CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN COUNT(*) > 10 THEN 'Warning'
            ELSE 'Pass'
        END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND account_balance < 0
),

-- Freshness checks
freshness_checks AS (
    SELECT
        'Freshness' AS quality_check_category,
        'Last Sync Timestamp' AS check_name,
        CAST(MAX(_fivetran_synced) AS VARCHAR) AS check_result,
        CASE 
            WHEN DATEDIFF(hour, MAX(_fivetran_synced), CURRENT_TIMESTAMP()) > 24 THEN 'Fail'
            WHEN DATEDIFF(hour, MAX(_fivetran_synced), CURRENT_TIMESTAMP()) > 12 THEN 'Warning'
            ELSE 'Pass'
        END AS threshold_status,
        NULL AS record_count,
        NULL AS percentage
    FROM source
    
    UNION ALL
    
    SELECT
        'Freshness',
        'Hours Since Last Sync',
        CAST(DATEDIFF(hour, MAX(_fivetran_synced), CURRENT_TIMESTAMP()) AS VARCHAR),
        CASE 
            WHEN DATEDIFF(hour, MAX(_fivetran_synced), CURRENT_TIMESTAMP()) > 24 THEN 'Fail'
            WHEN DATEDIFF(hour, MAX(_fivetran_synced), CURRENT_TIMESTAMP()) > 12 THEN 'Warning'
            ELSE 'Pass'
        END,
        NULL,
        NULL
    FROM source
    
    UNION ALL
    
    SELECT
        'Freshness',
        'Records Synced Today',
        CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN COUNT(*) = 0 THEN 'Warning'
            ELSE 'Pass'
        END,
        COUNT(*),
        ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM source WHERE _fivetran_deleted = FALSE), 0), 2)
    FROM source
    WHERE _fivetran_deleted = FALSE
    AND DATE(_fivetran_synced) = CURRENT_DATE()
),

combined_checks AS (
    SELECT * FROM completeness_checks
    UNION ALL
    SELECT * FROM integrity_checks
    UNION ALL
    SELECT * FROM validity_checks
    UNION ALL
    SELECT * FROM freshness_checks
),

final AS (
    SELECT
        quality_check_category,
        check_name,
        check_result,
        threshold_status,
        record_count,
        percentage,
        CURRENT_TIMESTAMP() AS measured_at
    FROM combined_checks
)

SELECT * FROM final
ORDER BY 
    CASE quality_check_category
        WHEN 'Freshness' THEN 1
        WHEN 'Completeness' THEN 2
        WHEN 'Integrity' THEN 3
        WHEN 'Validity' THEN 4
    END,
    CASE threshold_status
        WHEN 'Fail' THEN 1
        WHEN 'Warning' THEN 2
        WHEN 'Pass' THEN 3
    END,
    check_name
