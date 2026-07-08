select *
from {{ ref('stg_hed__students') }}
where last_login_date < enrollment_date
