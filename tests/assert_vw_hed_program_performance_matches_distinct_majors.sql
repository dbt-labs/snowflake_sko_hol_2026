with source_majors as (
    select distinct major_code
    from {{ ref('stg_hed__students') }}
    where major_code is not null
),

mart_majors as (
    select major_code
    from {{ ref('vw_hed_program_performance') }}
),

missing_from_mart as (
    select source_majors.major_code
    from source_majors
    left join mart_majors
        on source_majors.major_code = mart_majors.major_code
    where mart_majors.major_code is null
),

duplicated_in_mart as (
    select major_code
    from mart_majors
    group by major_code
    having count(*) > 1
)

select major_code, 'missing_from_mart' as failure_reason
from missing_from_mart

union all

select major_code, 'duplicated_in_mart' as failure_reason
from duplicated_in_mart
