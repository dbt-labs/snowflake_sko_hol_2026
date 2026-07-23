select
    count(*) as row_count
from {{ ref('dq_hed__completeness') }}
having count(*) != 1
