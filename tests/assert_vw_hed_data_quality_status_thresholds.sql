with validation as (
    select
        composite_quality_score,
        overall_quality_status,
        case
            when composite_quality_score >= 95 then 'Excellent'
            when composite_quality_score >= 85 then 'Good'
            when composite_quality_score >= 70 then 'Acceptable'
            else 'Needs Improvement'
        end as expected_overall_quality_status
    from {{ ref('vw_hed_data_quality') }}
)

select *
from validation
where overall_quality_status != expected_overall_quality_status
