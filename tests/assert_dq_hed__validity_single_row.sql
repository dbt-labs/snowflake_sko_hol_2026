select
    count(*) as row_count
from {{ ref('dq_hed__validity') }}
having count(*) != 1
