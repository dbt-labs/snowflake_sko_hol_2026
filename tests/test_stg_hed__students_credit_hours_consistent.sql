select *
from {{ ref('stg_hed__students') }}
where credit_hours_attempted is not null
  and credit_hours_earned is not null
  and credit_hours_earned > credit_hours_attempted
