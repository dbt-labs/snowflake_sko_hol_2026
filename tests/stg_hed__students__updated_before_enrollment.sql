select
    record_id,
    student_id,
    enrollment_date,
    last_updated
from {{ ref('stg_hed__students') }}
where enrollment_date is not null
  and last_updated is not null
  and last_updated::date < enrollment_date
