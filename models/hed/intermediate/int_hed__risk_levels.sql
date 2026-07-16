{{
  config(
    materialized='view',
    tags=['hed', 'intermediate', 'risk']
  )
}}

/*
  Intermediate Model: Student Risk Levels
  
  Purpose: Centralized risk categorization logic used by multiple downstream models
  
  Risk Dimensions:
  - GPA Risk Level
  - Completion Risk Level
  - Engagement Risk Level
  - Login Recency Risk Level
  - Overall Risk Assessment
  
  Used By:
  - vw_hed_retention_risk_analysis
  - vw_hed_data_quality (anomaly detection)
*/

with students as (
    select * from {{ ref('stg_hed__student') }}
),

risk_calculations as (
    select
        -- Pass through identifiers
        student_id,
        record_id,
        advisor_id,
        major_code,
        academic_standing,
        at_risk_flag,
        
        -- Pass through metrics for downstream use
        current_gpa,
        course_completion_rate,
        engagement_score,
        days_since_last_login,
        total_course_views,
        assignment_submissions,
        discussion_posts,
        financial_aid_amount,
        intervention_count,
        plagiarism_incidents,
        writing_quality_score,
        enrollment_date,
        last_login_date,
        last_updated,
        
        -- GPA Risk Level
        case
            when current_gpa < 2.0 then 'Critical'
            when current_gpa < 2.5 then 'High'
            when current_gpa < 3.0 then 'Moderate'
            else 'Low'
        end as gpa_risk_level,
        
        -- Completion Risk Level
        case
            when course_completion_rate < 0.50 then 'Critical'
            when course_completion_rate < 0.70 then 'High'
            when course_completion_rate < 0.85 then 'Moderate'
            else 'Low'
        end as completion_risk_level,
        
        -- Engagement Risk Level
        case
            when engagement_score < 30 then 'Critical'
            when engagement_score < 50 then 'High'
            when engagement_score < 70 then 'Moderate'
            else 'Low'
        end as engagement_risk_level,
        
        -- Login Recency Risk Level
        case
            when days_since_last_login > 14 then 'Critical'
            when days_since_last_login > 7 then 'High'
            when days_since_last_login > 3 then 'Moderate'
            else 'Low'
        end as login_recency_risk_level,
        
        -- Financial Aid Category
        case
            when financial_aid_amount = 0 then 'No Aid'
            when financial_aid_amount < 10000 then 'Partial Aid'
            else 'Full Support'
        end as financial_aid_category,
        
        -- Intervention Category
        case
            when intervention_count >= 5 then 'High Intervention'
            when intervention_count >= 2 then 'Moderate Intervention'
            when intervention_count > 0 then 'Low Intervention'
            else 'No Intervention'
        end as intervention_category

    from students
),

final as (
    select
        *,
        -- Overall Risk Assessment (composite of all risk dimensions)
        case
            -- Critical: ANY dimension is Critical
            when gpa_risk_level = 'Critical'
                or completion_risk_level = 'Critical'
                or engagement_risk_level = 'Critical'
                or login_recency_risk_level = 'Critical'
            then 'Critical - Immediate Intervention'
            
            -- High: ANY dimension is High (and no Critical)
            when gpa_risk_level = 'High'
                or completion_risk_level = 'High'
                or engagement_risk_level = 'High'
                or login_recency_risk_level = 'High'
            then 'High - Priority Attention'
            
            -- Moderate: ANY dimension is Moderate (and no Critical or High)
            when gpa_risk_level = 'Moderate'
                or completion_risk_level = 'Moderate'
                or engagement_risk_level = 'Moderate'
                or login_recency_risk_level = 'Moderate'
            then 'Moderate - Monitor Closely'
            
            -- Low: All dimensions are Low
            else 'Low - Standard Support'
        end as overall_risk_assessment,
        
        -- Recommended Actions based on risk profile
        case
            when gpa_risk_level = 'Critical'
                or completion_risk_level = 'Critical'
                or engagement_risk_level = 'Critical'
                or login_recency_risk_level = 'Critical'
            then 'Schedule mandatory advisor meeting; Review academic plan; Connect with tutoring/counseling; Verify financial aid status'
            
            when gpa_risk_level = 'High'
                or completion_risk_level = 'High'
                or engagement_risk_level = 'High'
                or login_recency_risk_level = 'High'
            then 'Advisor check-in within 1 week; Offer academic support resources; Review course load'
            
            when gpa_risk_level = 'Moderate'
                or completion_risk_level = 'Moderate'
                or engagement_risk_level = 'Moderate'
                or login_recency_risk_level = 'Moderate'
            then 'Monitor engagement metrics; Send supportive communication; Track attendance patterns'
            
            else 'Continue standard support; Celebrate successes; Maintain engagement'
        end as recommended_action
        
    from risk_calculations
)

select * from final
