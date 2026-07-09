select
    record_count
from (
    select count(*) as record_count
    from {{ ref('vw_hed_data_quality') }}
) validation_errors
where record_count != 1
