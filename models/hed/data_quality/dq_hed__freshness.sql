{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'freshness']
  )
}}

/*
  Data Quality Component: Freshness Checks
  
  Purpose: Monitor data freshness and staleness
  
  Checks:
  - Most recent update timestamp
  - Oldest update timestamp
  - Hours since last update
  - Days since last update
  - Freshness status classification
  - Records over 7 days old
  - Current records percentage
*/

with source_data as (
    select * from {{ ref('stg_hed__students') }}
),

freshness_metrics as (
    select
        'Data Freshness' as quality_dimension,
        max(last_updated) as most_recent_update,
        min(last_updated) as oldest_update,
        datediff('hour', max(last_updated), current_timestamp()) as hours_since_last_update,
        datediff('day', max(last_updated), current_timestamp()) as days_since_last_update,
        
        case
            when datediff('day', max(last_updated), current_timestamp()) <= 7 then 100
            when datediff('day', max(last_updated), current_timestamp()) <= 30 then 50
            else 0
        end as source_freshness_score,
        
        case
            when datediff('hour', max(last_updated), current_timestamp()) <= 1 then 'Excellent'

            when datediff('hour', max(last_updated), current_timestamp()) <= 6 then 'Good'
            when datediff('hour', max(last_updated), current_timestamp()) <= 24 then 'Acceptable'
            when datediff('day', max(last_updated), current_timestamp()) <= 3 then 'Needs Attention'
            else 'Stale Data'
        end as freshness_status,
        
        -- Check for stale individual records
        count(case when datediff('day', last_updated, current_timestamp()) > 7 then 1 end) as records_over_7_days_old,
        round(
            count(case when datediff('day', last_updated, current_timestamp()) <= 7 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as records_current_pct
    from source_data
)

select * from freshness_metrics
