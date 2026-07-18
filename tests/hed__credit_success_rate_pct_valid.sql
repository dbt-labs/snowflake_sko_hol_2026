select *
from {{ ref('stg_hed__students') }}
where credit_success_rate_pct < 0
   or credit_success_rate_pct > 100
