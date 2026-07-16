{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'performance', 'high-performing']
  )
}}

/*
  High Performing Students

  Purpose: Filter to students demonstrating strong academic performance and engagement.

  Selection Criteria:
  - High Engagement / High Performance quadrant
  - Current GPA >= 3.0
  - Engagement score >= 60

  Dependencies:
  - vw_hed_engagement_analytics
*/

with engagement_data as (
    select * from {{ ref('vw_hed_engagement_analytics') }}
)

select
    student_id,
    major_code,
    academic_standing,
    at_risk_flag,
    last_login_date,
    days_since_last_login,
    days_active_since_enrollment,
    login_recency_category,
    total_course_views,
    course_views_category,
    assignment_submissions,
    avg_assignment_score,
    assignment_activity_category,
    assignment_performance_category,
    discussion_posts,
    discussion_participation_category,
    engagement_score,
    engagement_level,
    engagement_balance_score,
    current_gpa,
    course_completion_rate,
    intervention_count,
    engagement_performance_quadrant,
    engagement_concern_level,
    recommended_engagement_action,
    enrollment_date,
    last_updated
from engagement_data
where engagement_performance_quadrant = 'High Engagement / High Performance'
  and current_gpa >= 3.0
  and engagement_score >= 60
order by
    current_gpa desc,
    engagement_score desc,
    total_course_views desc
