select 1
from (
    select count(*) as row_count
    from {{ ref('vw_hed_data_quality') }}
) as counts
where row_count != 1
