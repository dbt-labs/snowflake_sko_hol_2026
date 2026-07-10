select
    record_id,
    student_id,
    enrollment_date,
    last_login_date
from {{ ref('stg_hed__students') }}
where enrollment_date is not null
  and last_login_date is not null
  and enrollment_date > last_login_date
