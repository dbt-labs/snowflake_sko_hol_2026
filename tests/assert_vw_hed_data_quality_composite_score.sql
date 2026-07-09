with validation as (
    select
        completeness_score,
        validity_score,
        uniqueness_score,
        freshness_score,
        composite_quality_score,
        round(
            (
                completeness_score
                + validity_score
                + uniqueness_score
                + freshness_score
            ) / 4.0,
            1
        ) as expected_composite_quality_score
    from {{ ref('vw_hed_data_quality') }}
)

select *
from validation
where composite_quality_score != expected_composite_quality_score
