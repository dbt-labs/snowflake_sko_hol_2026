select *
from {{ ref('vw_hed_retention_risk_analysis') }}
where coalesce(upper(at_risk_flag::varchar), 'FALSE') <> 'TRUE'
