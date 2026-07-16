{{
  config(
    materialized='view',
    tags=['hed', 'intermediate', 'engagement']
  )
}}

/*
  Intermediate Model: Student Engagement Categories
  
  Purpose: Centralized engagement categorization logic used by multiple downstream models
  
  Engagement Dimensions:
  - Login Recency Category
  - Course Views Category
  - Assignment Activity Category
  - Assignment Performance Category
  - Discussion Participation Category
  - Engagement Level
  - Engagement Balance Score
  
  Used By:
  - vw_hed_engagement_analytics
  - vw_hed_retention_risk_analysis
*/

with students as (
    select * from {{ ref('stg_hed__students') }}
),

engagement_calculations as (
    select
        -- Pass through identifiers
        student_id,
        record_id,
        advisor_id,
        major_code,
        academic_standing,
        at_risk_flag,
        
        -- Pass through metrics
        current_gpa,
        course_completion_rate,
        engagement_score,
        total_course_views,
        assignment_submissions,
        avg_assignment_score,
        discussion_posts,
        intervention_count,
        enrollment_date,
        last_login_date,
        last_updated,
        days_since_last_login,
        days_active_since_enrollment,
        
        -- Login Recency Category
        case
            when days_since_last_login = 0 then 'Today'
            when days_since_last_login <= 1 then 'Within 24 Hours'
            when days_since_last_login <= 3 then 'Within 3 Days'
            when days_since_last_login <= 7 then 'Within 1 Week'
            when days_since_last_login <= 14 then 'Within 2 Weeks'
            else 'Over 2 Weeks Ago'
        end as login_recency_category,
        
        -- Course Views Category
        case
            when total_course_views >= 300 then 'Very High'
            when total_course_views >= 200 then 'High'
            when total_course_views >= 100 then 'Moderate'
            when total_course_views >= 50 then 'Low'
            else 'Very Low'
        end as course_views_category,
        
        -- Assignment Activity Category
        case
            when assignment_submissions >= 18 then 'Very Active'
            when assignment_submissions >= 14 then 'Active'
            when assignment_submissions >= 10 then 'Moderate'
            when assignment_submissions >= 6 then 'Low'
            else 'Very Low'
        end as assignment_activity_category,
        
        -- Assignment Performance Category
        case
            when avg_assignment_score >= 85 then 'Excellent'
            when avg_assignment_score >= 75 then 'Good'
            when avg_assignment_score >= 65 then 'Satisfactory'
            when avg_assignment_score >= 50 then 'Needs Improvement'
            else 'Critical'
        end as assignment_performance_category,
        
        -- Discussion Participation Category
        case
            when discussion_posts >= 25 then 'Very Active'
            when discussion_posts >= 15 then 'Active'
            when discussion_posts >= 8 then 'Moderate'
            when discussion_posts >= 3 then 'Low'
            else 'Minimal'
        end as discussion_participation_category,
        
        -- Overall Engagement Level
        case
            when engagement_score >= 80 then 'Highly Engaged'
            when engagement_score >= 60 then 'Engaged'
            when engagement_score >= 40 then 'Moderately Engaged'
            when engagement_score >= 20 then 'Disengaged'
            else 'Critically Disengaged'
        end as engagement_level,
        
        -- Engagement Balance Score (measures diverse engagement across dimensions)
        round(
            (
                (total_course_views / 400.0 * 100) +  -- Normalize to 0-100
                (assignment_submissions / 25.0 * 100) +
                (discussion_posts / 35.0 * 100)
            ) / 3.0,
            1
        ) as engagement_balance_score

    from students
),

final as (
    select
        *,
        -- Engagement vs Performance Quadrant Analysis
        case
            when engagement_score >= 60 and current_gpa >= 3.0 
            then 'High Engagement / High Performance'
            
            when engagement_score >= 60 and current_gpa < 3.0 
            then 'High Engagement / Low Performance'
            
            when engagement_score < 60 and current_gpa >= 3.0 
            then 'Low Engagement / High Performance'
            
            else 'Low Engagement / Low Performance'
        end as engagement_performance_quadrant,
        
        -- Engagement Trend Concerns
        case
            when days_since_last_login > 14 
                and engagement_score < 40 
            then 'Immediate Concern - Student Dropout Risk'
            
            when days_since_last_login > 7 
                and engagement_score < 50 
            then 'Elevated Concern - Declining Engagement'
            
            when engagement_score < 30 
            then 'High Concern - Critically Disengaged'
            
            when assignment_submissions < 5 
                and discussion_posts < 3 
            then 'Moderate Concern - Minimal Participation'
            
            else 'No Immediate Concern'
        end as engagement_concern_level,
        
        -- Recommended Engagement Actions
        case
            when days_since_last_login > 14 
            then 'Immediate outreach required; Check student wellness'
            
            when engagement_score < 30 
            then 'Schedule advisor meeting; Review barriers to engagement'
            
            when assignment_submissions < 5 
            then 'Connect with instructor; Offer tutoring support'
            
            when discussion_posts < 3 
            then 'Encourage peer collaboration; Review discussion participation expectations'
            
            when engagement_score >= 80 
            then 'Acknowledge engagement; Consider peer mentor role'

            when engagement_score >= 30 and engagement_score < 60
            then 'Send email from advisor'
            
            else 'Monitor ongoing; Maintain regular touchpoints'
        end as recommended_engagement_action

        
    from engagement_calculations
)

select * from final
