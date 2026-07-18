select *
from {{ ref('stg_hed__students') }}
where last_updated > current_timestamp()
