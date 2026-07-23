select
    count(*) as row_count
from {{ ref('dq_hed__duplicates') }}
having count(*) != 1
