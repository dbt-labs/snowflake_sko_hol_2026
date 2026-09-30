{{
  config(
    materialized='view',
    tags=['hed', 'engagement', 'retention', 'at_risk']
  )
}}

/*
  Immediate Dropout Risk Students

  Purpose: Surface students flagged as at-risk with an "Immediate Concern -
  Student Dropout Risk" engagement classification, ordered by urgency
  (lowest engagement score and GPA first) to prioritize outreach.

  Dependencies:
  - vw_hed_engagement_analytics
*/

with engagement_analytics as (
    select * from {{ ref('vw_hed_engagement_analytics') }}
),

at_risk_students as (
    select
        student_id,
        major_code,
        academic_standing,
        at_risk_flag,
        engagement_concern_level,
        engagement_level,
        engagement_performance_quadrant,
        recommended_engagement_action,
        engagement_score,
        engagement_balance_score,
        current_gpa,
        course_completion_rate,
        avg_assignment_score,
        assignment_submissions,
        discussion_posts,
        total_course_views,
        days_since_last_login,
        login_recency_category,
        days_active_since_enrollment,
        intervention_count,
        enrollment_date,
        last_login_date
    from engagement_analytics
    where at_risk_flag = 'TRUE'
      and engagement_concern_level = 'Immediate Concern - Student Dropout Risk'
)

select * from at_risk_students
order by
    engagement_score asc,
    current_gpa asc

