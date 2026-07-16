select *
from {{ ref('vw_hed_retention_risk_analysis') }}
where overall_risk_assessment is null
   or trim(overall_risk_assessment) = ''
