with validation as (
    select count(*) as row_count
    from {{ ref('vw_hed_data_quality') }}
)

select *
from validation
where row_count <> 1
