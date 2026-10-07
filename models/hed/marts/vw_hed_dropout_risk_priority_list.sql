{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'engagement', 'retention', 'outreach']
  )
}}

/*
  Dropout-Risk Outreach Priority List

  Purpose: Rank at-risk students by urgency for advisor outreach.

  Population:
  - at_risk_flag = true
  - engagement_concern_level = 'Immediate Concern - Student Dropout Risk'

  priority_score (0-100, higher = more urgent) is an analyst-defined blend,
  NOT a validated predictive model. Weights match the original "Scoring
  Weights" worksheet:
    engagement 30% | completion 25% | assignment score 20% | GPA 15% | interventions 10%

  Note: days_since_last_login is surfaced for context but is not scored.
  If this value is uniformly very high across the population, treat it as a
  signal to check login-data freshness before acting on it.

  Dependencies:
  - vw_hed_engagement_analytics (student-level grain; student_id is unique,
    so no re-aggregation is needed here)
*/

with engagement as (
    select * from {{ ref('vw_hed_engagement_analytics') }}
),

priority_population as (
    select
        student_id,
        major_code,
        academic_standing,
        engagement_score,
        current_gpa,
        avg_assignment_score,
        course_completion_rate,
        days_since_last_login,
        intervention_count,
        recommended_engagement_action
    from engagement
    where at_risk_flag = true
      and engagement_concern_level = 'Immediate Concern - Student Dropout Risk'
),

scored as (
    select
        *,
        100 * (
              0.30 * (1 - engagement_score / 100)
            + 0.25 * (1 - course_completion_rate)
            + 0.20 * (1 - avg_assignment_score / 100)
            + 0.15 * (1 - current_gpa / 4)
            + 0.10 * least(intervention_count, 8) / 8
        ) as priority_score
    from priority_population
)

select
    rank() over (order by priority_score desc) as priority_rank,
    student_id,
    major_code,
    academic_standing,
    round(engagement_score, 1)        as engagement_score,
    round(current_gpa, 2)             as current_gpa,
    round(avg_assignment_score, 1)    as avg_assignment_score,
    round(course_completion_rate, 2)  as course_completion_rate,
    days_since_last_login,
    intervention_count,
    round(priority_score, 1)          as priority_score,
    recommended_engagement_action
from scored
order by priority_rank, student_id
