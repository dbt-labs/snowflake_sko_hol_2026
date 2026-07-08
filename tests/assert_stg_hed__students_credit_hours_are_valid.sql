with invalid_rows as (
    select *
    from {{ ref('stg_hed__students') }}
    where credit_hours_earned > credit_hours_attempted
)

select *
from invalid_rows
