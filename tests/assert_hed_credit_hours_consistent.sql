select *
from {{ source('hed', 'hed_records') }}
where credit_hours_earned > credit_hours_attempted
