select *
from {{ ref('vw_hed_retention_risk_analysis') }}
where not (
    at_risk_flag = true
    or upper(at_risk_flag::varchar) = 'TRUE'
)
