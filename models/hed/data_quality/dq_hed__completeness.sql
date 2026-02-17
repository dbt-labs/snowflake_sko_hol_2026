{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'completeness']
  )
}}

/*
  Data Quality Component: Completeness Checks
  
  Purpose: Monitor data completeness for required fields
  
  Checks:
  - Missing student IDs
  - Missing enrollment dates
  - Missing academic standing
  - Missing GPA
  - Missing major codes
  - Missing advisor IDs
  - Overall completeness score
*/

with source_data as (
    select * from {{ ref('stg_hed__students') }}
),

completeness_metrics as (
    select
        'Record Completeness' as quality_dimension,
        count(*) as total_records,
        count(distinct student_id) as unique_students,
        count(distinct record_id) as unique_record_ids,
        
        -- Check for required field completeness
        count(*) - count(student_id) as missing_student_ids,
        count(*) - count(enrollment_date) as missing_enrollment_dates,
        count(*) - count(academic_standing) as missing_academic_standing,
        count(*) - count(current_gpa) as missing_gpa,
        count(*) - count(major_code) as missing_major_codes,
        count(*) - count(advisor_id) as missing_advisor_ids,
        
        -- Calculate completeness percentages
        round((count(student_id)::decimal / nullif(count(*), 0)) * 100, 2) as student_id_completeness_pct,
        round((count(enrollment_date)::decimal / nullif(count(*), 0)) * 100, 2) as enrollment_date_completeness_pct,
        round((count(academic_standing)::decimal / nullif(count(*), 0)) * 100, 2) as academic_standing_completeness_pct,
        round((count(current_gpa)::decimal / nullif(count(*), 0)) * 100, 2) as gpa_completeness_pct,
        round((count(major_code)::decimal / nullif(count(*), 0)) * 100, 2) as major_completeness_pct,
        
        -- Overall completeness score
        round(
            (
                (count(student_id)::decimal / nullif(count(*), 0)) +
                (count(enrollment_date)::decimal / nullif(count(*), 0)) +
                (count(academic_standing)::decimal / nullif(count(*), 0)) +
                (count(current_gpa)::decimal / nullif(count(*), 0)) +
                (count(major_code)::decimal / nullif(count(*), 0))
            ) / 5.0 * 100,
            1
        ) as overall_completeness_score
    from source_data
)

select * from completeness_metrics
