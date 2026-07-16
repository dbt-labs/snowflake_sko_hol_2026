select *
from {{ ref('vw_hed_data_quality') }}
group by total_records, unique_students
having count(*) != 1
   or unique_students > total_records
