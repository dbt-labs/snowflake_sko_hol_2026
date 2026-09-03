{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'engagement', 'assignment_performance']
  )
}}

with engagement_analytics as (
    select * from {{ ref('vw_hed_engagement_analytics') }}
)

select
    student_id as student,
    assignment_performance_category as student__assignment_performance_category,
    avg(avg_assignment_score) as avg_assignment_score
from engagement_analytics
group by
    student_id,
    assignment_performance_category
