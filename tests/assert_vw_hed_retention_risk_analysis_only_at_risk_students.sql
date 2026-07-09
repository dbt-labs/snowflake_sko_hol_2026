select
    student_id,
    at_risk_flag,
    overall_risk_assessment
from {{ ref('vw_hed_retention_risk_analysis') }}
where at_risk_flag is distinct from true
