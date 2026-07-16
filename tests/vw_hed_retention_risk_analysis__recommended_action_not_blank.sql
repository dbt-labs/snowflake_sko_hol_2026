select *
from {{ ref('vw_hed_retention_risk_analysis') }}
where recommended_action is null
   or trim(recommended_action) = ''
