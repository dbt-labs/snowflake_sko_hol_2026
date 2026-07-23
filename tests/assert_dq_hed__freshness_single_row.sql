select
    count(*) as row_count
from {{ ref('dq_hed__freshness') }}
having count(*) != 1
