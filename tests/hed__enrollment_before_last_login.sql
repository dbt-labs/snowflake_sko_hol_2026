select *
from {{ ref('stg_hed__students') }}
where last_login_date is not null
  and enrollment_date > last_login_date
