{{
  config(
    materialized='view',
    tags=['hed', 'staging']
  )
}}

/*
  Staging Model: HED Student Records
  
  Purpose: Single source of truth for all HED data transformations
  
  This model:
  - Centralizes source reference
  - Standardizes column naming
  - Handles type casting
  - Provides base calculations used across downstream models
*/

with source as (
    select * from {{ source('hed', 'hed_records') }}
),

staged as (
    select
        -- Identifiers
        record_id,
        student_id,
        advisor_id,
        major_code,
        
        -- Academic Information
        academic_standing,
        case
            when current_gpa > 4 then current_gpa / 100.0
            else current_gpa
        end as current_gpa,
        credit_hours_attempted,
        credit_hours_earned,
        case
            when course_completion_rate > 1 then course_completion_rate / 100.0
            else course_completion_rate
        end as course_completion_rate,
        avg_assignment_score,
        
        -- Engagement Metrics
        case
            when engagement_score > 100 then engagement_score::float / 10
            else engagement_score::float
        end as engagement_score,
        total_course_views,
        assignment_submissions,
        discussion_posts,
        
        -- Academic Integrity
        plagiarism_incidents,
        writing_quality_score,
        
        -- Financial Information
        financial_aid_amount,
        
        -- Risk & Intervention
        at_risk_flag,
        intervention_count,
        
        -- Dates
        enrollment_date,
        last_login_date,
        last_updated,
        
        -- Calculated Fields: Days since last login, as of the source snapshot
        datediff('day', last_login_date, max(last_updated) over ()) as days_since_last_login,
        
        -- Calculated Fields: Days active since enrollment
        datediff('day', enrollment_date, last_login_date) as days_active_since_enrollment,
        
        -- Calculated Fields: Credit success rate
        case 
            when credit_hours_attempted > 0 
            then round(credit_hours_earned::decimal / credit_hours_attempted * 100, 1)
            else 0
        end as credit_success_rate_pct

    from source
)

select * from staged
