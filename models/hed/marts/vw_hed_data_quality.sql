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

base as (
    select
        current_timestamp() as quality_check_timestamp,
        'Overall Data Quality Summary' as report_section,
        
        -- Aggregate quality metrics from component models
        c.overall_completeness_score as completeness_score,
        v.overall_validity_score as validity_score,
        d.student_uniqueness_pct as uniqueness_score,
        d.record_id_uniqueness_pct as record_id_uniqueness_score,
        f.records_current_pct as freshness_score,
        f.records_recent_30d_pct as freshness_30d_score,
        
        c.total_records,
        c.unique_students,
        c.missing_advisor_ids,
        c.missing_last_login_dates,
        c.missing_last_updated_timestamps,
        v.invalid_assignment_score_records,
        v.invalid_date_logic_records,
        v.invalid_plagiarism_records,
        v.invalid_intervention_records,
        d.duplicate_student_records,
        d.duplicate_record_ids,
        f.most_recent_update as most_recent_data_update,
        f.hours_since_last_update,
        f.records_over_7_days_old,
        f.records_over_30_days_old
    from completeness c
    cross join validity v
    cross join duplicates d
    cross join freshness f
),

summary as (
    select
        *,
        round(
            (
                completeness_score +
                validity_score +
                uniqueness_score +
                record_id_uniqueness_score +
                freshness_score
            ) / 5.0,
            1
        ) as composite_quality_score
    from base
)

select
    *,
    case
        when composite_quality_score >= 95 then 'Excellent'
        when composite_quality_score >= 85 then 'Good'
        when composite_quality_score >= 70 then 'Acceptable'
        else 'Needs Improvement'
    end as overall_quality_status
from summary

