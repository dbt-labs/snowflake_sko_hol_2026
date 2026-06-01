select 1
from {{ ref('vw_hed_data_quality') }}
group by 1
having count(*) != 1
