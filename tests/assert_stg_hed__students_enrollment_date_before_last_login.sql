select
    record_id,
    student_id,
    enrollment_date,
    last_login_date
from {{ ref('stg_hed__students') }}
where last_login_date is not null
  and enrollment_date > cast(last_login_date as date)
