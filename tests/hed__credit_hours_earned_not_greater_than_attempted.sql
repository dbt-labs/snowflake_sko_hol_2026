select *
from {{ ref('stg_hed__students') }}
where credit_hours_earned > credit_hours_attempted
