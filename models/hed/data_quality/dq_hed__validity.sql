{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'validity']
  )
}}

/*
  Data Quality Component: Validity Checks
  
  Purpose: Validate data ranges and logical consistency
  
  Checks:
  - GPA validity (0.0 - 4.0)
  - Credit hours validity (earned <= attempted)
  - Course completion rate validity (0.0 - 1.0)
  - Engagement score validity (0 - 100)
  - Assignment score validity (0 - 100)
  - Financial aid validity (non-negative)
  - Date logic validity (enrollment <= last_login)
  - Plagiarism incidents validity (non-negative)
  - Intervention count validity (non-negative)
  - Overall validity score
*/

with source_data as (
    select * from {{ ref('stg_hed__students') }}
),

validity_metrics as (
    select
        'Data Validity' as quality_dimension,
        
        -- GPA validity (should be between 0.0 and 4.0)
        count(case when current_gpa < 0.0 or current_gpa > 4.0 then 1 end) as invalid_gpa_records,
        round(
            count(case when current_gpa >= 0.0 and current_gpa <= 4.0 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as gpa_validity_pct,
        
        -- Credit hours validity (earned should not exceed attempted)
        count(case when credit_hours_earned > credit_hours_attempted then 1 end) as invalid_credit_hour_records,
        round(
            count(case when credit_hours_earned <= credit_hours_attempted then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as credit_hours_validity_pct,
        
        -- Course completion rate validity (should be between 0.0 and 1.0)
        count(case when course_completion_rate < 0.0 or course_completion_rate > 1.0 then 1 end) as invalid_completion_rate_records,
        round(
            count(case when course_completion_rate >= 0.0 and course_completion_rate <= 1.0 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as completion_rate_validity_pct,
        
        -- Engagement score validity (should be between 0 and 100)
        count(case when engagement_score < 0 or engagement_score > 100 then 1 end) as invalid_engagement_score_records,
        round(
            count(case when engagement_score >= 0 and engagement_score <= 100 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as engagement_score_validity_pct,
        
        -- Assignment score validity (should be between 0 and 100)
        count(case when avg_assignment_score < 0 or avg_assignment_score > 100 then 1 end) as invalid_assignment_score_records,
        round(
            count(case when avg_assignment_score >= 0 and avg_assignment_score <= 100 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as assignment_score_validity_pct,
        
        -- Financial aid validity (should be non-negative)
        count(case when financial_aid_amount < 0 then 1 end) as invalid_financial_aid_records,
        round(
            count(case when financial_aid_amount >= 0 then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as financial_aid_validity_pct,
        
        -- Date logic validity (enrollment should be before last login)
        count(case when enrollment_date > last_login_date then 1 end) as invalid_date_logic_records,
        round(
            count(case when enrollment_date <= last_login_date then 1 end)::decimal 
            / nullif(count(*), 0) * 100,
            2
        ) as date_logic_validity_pct,

        -- Plagiarism incident validity (should be non-negative)
        count(case when plagiarism_incidents < 0 then 1 end) as invalid_plagiarism_records,
        round(
            count(case when plagiarism_incidents >= 0 then 1 end)::decimal
            / nullif(count(*), 0) * 100,
            2
        ) as plagiarism_validity_pct,

        -- Intervention count validity (should be non-negative)
        count(case when intervention_count < 0 then 1 end) as invalid_intervention_records,
        round(
            count(case when intervention_count >= 0 then 1 end)::decimal
            / nullif(count(*), 0) * 100,
            2
        ) as intervention_validity_pct,
        
        -- Overall validity score
        round(
            (
                (count(case when current_gpa >= 0.0 and current_gpa <= 4.0 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when credit_hours_earned <= credit_hours_attempted then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when course_completion_rate >= 0.0 and course_completion_rate <= 1.0 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when engagement_score >= 0 and engagement_score <= 100 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when avg_assignment_score >= 0 and avg_assignment_score <= 100 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when financial_aid_amount >= 0 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when enrollment_date <= last_login_date then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when plagiarism_incidents >= 0 then 1 end)::decimal / nullif(count(*), 0)) +
                (count(case when intervention_count >= 0 then 1 end)::decimal / nullif(count(*), 0))
            ) / 9.0 * 100,
            1
        ) as overall_validity_score
    from source_data
)

select * from validity_metrics
