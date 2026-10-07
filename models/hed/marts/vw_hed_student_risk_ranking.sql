{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'risk', 'ranking']
  )
}}

/*
  Student Risk Ranking

  Purpose: Rank students by relative academic and engagement risk indicators.

  Grain: One row per student, limited to the 20 highest relative risk scores.
*/

with engagement_analytics as (
    select * from {{ ref('vw_hed_engagement_analytics') }}
),

base as (
    select
        student_id,
        major_code,
        academic_standing,
        at_risk_flag,
        engagement_concern_level,
        current_gpa as gpa,
        course_completion_rate as completion,
        engagement_score as engagement,
        avg_assignment_score as asg_score,
        datediff(
            'day',
            last_login_date,
            max(last_login_date) over ()
        ) as days_idle_at_snapshot
    from engagement_analytics
),

scored as (
    select
        *,
        (
            percent_rank() over (order by gpa desc)
            + percent_rank() over (order by completion desc)
            + percent_rank() over (order by engagement desc)
            + percent_rank() over (order by asg_score desc)
            + percent_rank() over (order by days_idle_at_snapshot)
        ) / 5 as risk_score
    from base
)

select
    student_id,
    major_code,
    academic_standing,
    round(risk_score, 3) as risk_score,
    gpa,
    completion,
    engagement,
    asg_score,
    days_idle_at_snapshot,
    at_risk_flag,
    engagement_concern_level
from scored
order by risk_score desc
limit 20
