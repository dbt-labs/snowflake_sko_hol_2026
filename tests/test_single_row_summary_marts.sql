with violations as (
    select 'vw_hed_student_success_kpi' as model_name, count(*) as row_count
    from {{ ref('vw_hed_student_success_kpi') }}
    having count(*) != 1

    union all

    select 'vw_hed_data_quality' as model_name, count(*) as row_count
    from {{ ref('vw_hed_data_quality') }}
    having count(*) != 1
)

select *
from violations
