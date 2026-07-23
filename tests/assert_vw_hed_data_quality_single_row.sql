select
    count(*) as row_count
from {{ ref('vw_hed_data_quality') }}
having count(*) != 1
