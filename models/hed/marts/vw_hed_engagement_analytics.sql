{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'engagement', 'trends']
  )
}}

/*
  Student Engagement Analytics
  
  Purpose: Analyze patterns in student learning management system (LMS) engagement
  
  Engagement Dimensions:
  - Login frequency and recency
  - Course material interaction (views)
  - Assignment completion behavior
  - Discussion forum participation
  - Composite engagement scoring
  
  Use Cases:
  - Identify disengaged students early
  - Measure online learning effectiveness
  - Support evidence-based intervention timing
  - Track engagement trends by cohort/major
  
  Dependencies:
  - int_hed__engagement_categories (provides all engagement categorizations)
*/

with engagement_data as (
    select * from {{ ref('int_hed__engagement_categories') }}
)

select
    student_id,
    major_code,
    academic_standing,
    at_risk_flag,
    
    -- Login Behavior
    last_login_date,
    days_since_last_login,
    days_active_since_enrollment,
    login_recency_category,
    
    -- Course Content Engagement
    total_course_views,
    course_views_category,
    
    -- Assignment Engagement
    assignment_submissions,
    avg_assignment_score,
    assignment_activity_category,
    assignment_performance_category,
    
    -- Discussion Forum Participation
    discussion_posts,
    discussion_participation_category,
    round(discussion_posts::float / nullif(assignment_submissions, 0), 2) as discussion_posts_per_assignment_submission,
    
    -- Overall Engagement Metrics
    engagement_score,
    engagement_level,
    engagement_balance_score,
    
    -- Academic Context
    current_gpa,
    course_completion_rate,
    
    -- Support Context
    intervention_count,
    
    -- Engagement Analysis
    engagement_performance_quadrant,
    engagement_concern_level,
    recommended_engagement_action,
    
    -- Dates
    enrollment_date,
    last_updated

from engagement_data
order by
    case engagement_concern_level
        when 'Immediate Concern - Student Dropout Risk' then 1
        when 'High Concern - Critically Disengaged' then 2
        when 'Elevated Concern - Declining Engagement' then 3
        when 'Moderate Concern - Minimal Participation' then 4
        else 5
    end,
    days_since_last_login desc,
    engagement_score asc
