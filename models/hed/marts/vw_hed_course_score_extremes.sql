{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'course', 'academic-performance']
  )
}}

/*
  Course Score Extremes

  Purpose: Show the best and worst student average assignment scores for each
  academic program. The source does not include a course identifier, so
  major_code is used as the available course-level grouping.

  Grain: One row per major_code
*/

with student_scores as (
  select
    major_code,
    avg_assignment_score
  from {{ ref('stg_hed__students') }}
  where major_code is not null
    and avg_assignment_score is not null
),

course_score_extremes as (
  select
    major_code,
    round(max(avg_assignment_score), 1) as best_avg_assignment_score,
    round(min(avg_assignment_score), 1) as worst_avg_assignment_score
  from student_scores
  group by major_code
)

select
  major_code,
  best_avg_assignment_score,
  worst_avg_assignment_score
from course_score_extremes
