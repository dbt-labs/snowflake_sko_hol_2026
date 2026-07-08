select *
from {{ source('hed', 'hed_records') }}
where last_login_date is not null
  and enrollment_date > last_login_date
