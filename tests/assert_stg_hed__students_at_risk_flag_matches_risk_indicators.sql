select
    record_id,
    student_id,
    at_risk_flag,
    current_gpa,
    course_completion_rate,
    engagement_score
from {{ ref('stg_hed__students') }}
where at_risk_flag = true
  and coalesce(current_gpa, 4.0) >= 2.0
  and coalesce(course_completion_rate, 1.0) >= 0.70
  and coalesce(engagement_score, 100) >= 50
