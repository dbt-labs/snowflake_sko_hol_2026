select *
from {{ ref('stg_hed__students') }}
where days_since_last_login < 0
   or days_active_since_enrollment < 0
