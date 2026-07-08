with validation as (
    select count(*) as row_count
    from {{ ref('vw_hed_student_success_kpi') }}
)

select *
from validation
where row_count <> 1
