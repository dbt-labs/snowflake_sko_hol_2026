{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'retention', 'risk']
  )
}}

/*
  Student Retention Risk Analysis
  
  Purpose: Identify and analyze students at risk of dropping out
  
  Risk Factors Analyzed:
  - Academic standing (probation, warning, suspension)
  - Low engagement (course views, assignment submissions)
  - Poor completion rates
  - Financial aid needs
  - Intervention history
  
  Use Cases:
  - Early warning system for advisors
  - Targeted intervention planning
  - Retention program effectiveness
  
  Dependencies:
  - int_hed__risk_levels (provides all risk categorizations)
*/

with risk_data as (
    select * from {{ ref('int_hed__risk_levels') }}
)

select
    student_id,
    major_code,
    advisor_id,
    academic_standing,
    at_risk_flag,
    
    -- Academic Risk Factors
    current_gpa,
    gpa_risk_level,
    course_completion_rate,
    completion_risk_level,
    
    -- Engagement Risk Factors
    engagement_score,
    engagement_risk_level,
    total_course_views,
    assignment_submissions,
    discussion_posts,
    days_since_last_login,
    login_recency_risk_level,
    
    -- Financial Risk Factors
    financial_aid_amount,
    financial_aid_category,
    
    -- Intervention History
    intervention_count,
    intervention_category,
    
    -- Academic Integrity
    plagiarism_incidents,
    writing_quality_score,
    
    -- Overall Risk Assessment
    overall_risk_assessment,
    recommended_action,
    
    -- Dates
    enrollment_date,
    last_login_date,
    last_updated
from risk_data
-- Filter to at-risk students only
-- Note: Adjust the WHERE clause based on how your data stores boolean values
--   Option 1 (boolean): WHERE at_risk_flag = true
--   Option 2 (string):  WHERE UPPER(at_risk_flag::VARCHAR) = 'TRUE'
--   Option 3 (all):     Remove WHERE clause to see all students with risk analysis
where at_risk_flag = true 
   or UPPER(at_risk_flag::VARCHAR) = 'TRUE'
order by 
  case overall_risk_assessment
    when 'Critical - Immediate Intervention' then 1
    when 'High - Priority Attention' then 2
    when 'Moderate - Monitor Closely' then 3
    else 4
  end,
  current_gpa asc,
  engagement_score asc