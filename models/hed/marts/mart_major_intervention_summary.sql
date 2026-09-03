{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'interventions', 'program']
  )
}}

/*
  Major Intervention Summary

  Purpose: Summarize intervention volume and assignment performance by major.

  Grain:
  - One row per major_code

  Metrics:
  - intervention_count: Total interventions across students in the major
  - avg_assignment_score: Average student assignment score in the major
*/

with engagement as (

    select
        major_code,
        avg_assignment_score,
        intervention_count
    from {{ ref('vw_hed_engagement_analytics') }}

),

major_summary as (

    select
        major_code,
        avg(avg_assignment_score) as avg_assignment_score,
        sum(intervention_count) as intervention_count
    from engagement
    group by major_code

)

select
    major_code,
    avg_assignment_score,
    intervention_count
from major_summary
order by intervention_count desc
