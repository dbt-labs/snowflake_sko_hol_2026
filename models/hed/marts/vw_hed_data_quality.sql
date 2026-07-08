{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'monitoring']
  )
}}

/*
  Higher Education Data Quality Monitor
  
  Purpose: Monitor data completeness, validity, freshness, and row-count stability for HED records
  
  Quality Checks (now modular):
  - Record completeness (dq_hed__completeness)
  - Data validity (dq_hed__validity)
  - Duplicate detection (dq_hed__duplicates)
  - Data freshness tracking (dq_hed__freshness)
  - Row-count drift monitoring (dq_hed__row_count_drift)
  
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

row_count_drift as (
    select * from {{ ref('dq_hed__row_count_drift') }}
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
        f.hours_since_last_update,
        r.latest_updated_date as row_count_drift_latest_date,
        r.current_row_count,
        r.avg_row_count_previous_7_days,
        r.row_count_drift_pct,
        r.row_count_drift_status
    from completeness c
    cross join validity v
    cross join duplicates d
    cross join freshness f
    cross join row_count_drift r
)

select * from summary
