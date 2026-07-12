{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'monitoring']
  )
}}

/*
  Higher Education Data Quality Monitor
  
  Purpose: Monitor data completeness, validity, and freshness for HED records
  
  Quality Checks (now modular):
  - Record completeness (dq_hed__completeness)
  - Data validity (dq_hed__validity)
  - Duplicate detection (dq_hed__duplicates)
  - Data freshness tracking (dq_hed__freshness)
  - Source freshness tracking (raw HED source)
  
  Use Cases:
  - Daily data quality monitoring
  - Integration health checks
  - Data governance reporting
  - Issue detection and alerting
*/

with completeness as (
    select * from {{ ref('dq_hed__completeness') }}
),

validity as (
    select * from {{ ref('dq_hed__validity') }}
),

duplicates as (
    select * from {{ ref('dq_hed__duplicates') }}
),

freshness as (
    select * from {{ ref('dq_hed__freshness') }}
),

source_freshness as (
    select
        max(last_updated) as source_most_recent_update,
        min(last_updated) as source_oldest_update,
        datediff('hour', max(last_updated), current_timestamp()) as source_hours_since_last_update,
        datediff('day', max(last_updated), current_timestamp()) as source_days_since_last_update,
        case
            when datediff('hour', max(last_updated), current_timestamp()) <= 6 then 'Pass'
            when datediff('hour', max(last_updated), current_timestamp()) <= 24 then 'Warn'
            else 'Error'
        end as source_freshness_status
    from {{ source('hed', 'hed_records') }}
),

summary as (
    select
        current_timestamp() as quality_check_timestamp,
        'Overall Data Quality Summary' as report_section,
        
        -- Aggregate quality metrics from component models
        c.overall_completeness_score as completeness_score,
        v.overall_validity_score as validity_score,
        d.student_uniqueness_pct as uniqueness_score,
        f.records_current_pct as freshness_score,
        
        -- Source freshness metrics from raw source table
        sf.source_most_recent_update,
        sf.source_oldest_update,
        sf.source_hours_since_last_update,
        sf.source_days_since_last_update,
        sf.source_freshness_status,
        
        -- Calculate composite quality score
        round(
            (
                c.overall_completeness_score +
                v.overall_validity_score +
                d.student_uniqueness_pct +
                f.records_current_pct
            ) / 4.0,
            1
        ) as composite_quality_score,
        
        case
            when round((c.overall_completeness_score + v.overall_validity_score + d.student_uniqueness_pct + f.records_current_pct) / 4.0, 1) >= 95 
            then 'Excellent'
            when round((c.overall_completeness_score + v.overall_validity_score + d.student_uniqueness_pct + f.records_current_pct) / 4.0, 1) >= 85 
            then 'Good'
            when round((c.overall_completeness_score + v.overall_validity_score + d.student_uniqueness_pct + f.records_current_pct) / 4.0, 1) >= 70 
            then 'Acceptable'
            else 'Needs Improvement'
        end as overall_quality_status,
        
        c.total_records,
        c.unique_students,
        f.most_recent_update as most_recent_data_update,
        f.hours_since_last_update
    from completeness c
    cross join validity v
    cross join duplicates d
    cross join freshness f
    cross join source_freshness sf
)

select * from summary
