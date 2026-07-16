with row_count as (
    select count(*) as row_count
    from {{ ref('vw_hed_data_quality') }}
)

select *
from row_count
where row_count != 1
