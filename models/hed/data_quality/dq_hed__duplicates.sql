{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'duplicates']
  )
}}

/*
  Data Quality Component: Duplicate Detection
  
  Purpose: Identify duplicate records in the data
  
  Checks:
  - Duplicate student records
  - Duplicate record IDs
  - Student uniqueness percentage
  - Record ID uniqueness percentage
*/

with source_data as (
    select * from {{ ref('stg_hed__students') }}
),

duplicate_metrics as (
    select
        'Duplicate Detection' as quality_dimension,
        count(*) as total_records,
        count(distinct student_id) as unique_students,
        count(*) - count(distinct student_id) as duplicate_student_records,
        count(distinct record_id) as unique_record_ids,
        count(*) - count(distinct record_id) as duplicate_record_ids,
        
        round(
            (count(distinct student_id)::decimal / nullif(count(*), 0)) * 100,
            2
        ) as student_uniqueness_pct,
        round(
            (count(distinct record_id)::decimal / nullif(count(*), 0)) * 100,
            2
        ) as record_id_uniqueness_pct
    from source_data
)

select * from duplicate_metrics
