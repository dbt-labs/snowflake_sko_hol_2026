with invalid_rows as (
    select *
    from {{ ref('stg_hed__students') }}
    where (
        last_login_date is not null
        and enrollment_date is not null
        and last_login_date < enrollment_date
    )
    or days_since_last_login < 0
    or days_active_since_enrollment < 0
)

select *
from invalid_rows
