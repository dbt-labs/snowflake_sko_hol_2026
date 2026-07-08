select
    record_id,
    student_id,
    credit_hours_attempted,
    credit_hours_earned
from {{ ref('stg_hed__students') }}
where credit_hours_attempted is not null
  and credit_hours_earned is not null
  and credit_hours_earned > credit_hours_attempted
