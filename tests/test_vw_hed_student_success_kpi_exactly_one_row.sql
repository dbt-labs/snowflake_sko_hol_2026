select 1
from {{ ref('vw_hed_student_success_kpi') }}
having count(*) != 1
