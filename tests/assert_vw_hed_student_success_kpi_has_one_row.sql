select *
from {{ ref('vw_hed_student_success_kpi') }}
qualify count(*) over () <> 1
