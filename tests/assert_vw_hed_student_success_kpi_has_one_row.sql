select 1
from (
    select count(*) as row_count
    from {{ ref('vw_hed_student_success_kpi') }}
) as counts
where row_count != 1
