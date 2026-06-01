select *
from {{ ref('vw_hed_data_quality') }}
where unique_students > total_records
   or quality_check_timestamp < most_recent_data_update
