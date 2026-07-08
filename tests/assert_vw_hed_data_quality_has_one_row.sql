select *
from {{ ref('vw_hed_data_quality') }}
qualify count(*) over () <> 1
