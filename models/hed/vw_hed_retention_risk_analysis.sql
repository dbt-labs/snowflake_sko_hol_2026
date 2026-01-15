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
*/

with source_data as (
  select *
  from {{ source('hed', 'hed_records') }}
),

risk_analysis as (
  select
    student_id,
    major_code,
    advisor_id,
    academic_standing,
    at_risk_flag,
    
    -- Academic Risk Factors
    current_gpa,
    case
      when current_gpa < 2.0 then 'Critical'
      when current_gpa < 2.5 then 'High'
      when current_gpa < 3.0 then 'Moderate'
      else 'Low'
    end as gpa_risk_level,
    
    course_completion_rate,
    case
      when course_completion_rate < 0.50 then 'Critical'
      when course_completion_rate < 0.70 then 'High'
      when course_completion_rate < 0.85 then 'Moderate'
      else 'Low'
    end as completion_risk_level,
    
    -- Engagement Risk Factors
    engagement_score,
    case
      when engagement_score < 30 then 'Critical'
      when engagement_score < 50 then 'High'
      when engagement_score < 70 then 'Moderate'
      else 'Low'
    end as engagement_risk_level,
    
    total_course_views,
    assignment_submissions,
    discussion_posts,
    datediff('day', last_login_date, current_date()) as days_since_last_login,
    case
      when datediff('day', last_login_date, current_date()) > 14 then 'Critical'
      when datediff('day', last_login_date, current_date()) > 7 then 'High'
      when datediff('day', last_login_date, current_date()) > 3 then 'Moderate'
      else 'Low'
    end as login_recency_risk_level,
    
    -- Financial Risk Factors
    financial_aid_amount,
    case
      when financial_aid_amount = 0 then 'No Aid'
      when financial_aid_amount < 10000 then 'Partial Aid'
      else 'Full Support'
    end as financial_aid_category,
    
    -- Intervention History
    intervention_count,
    case
      when intervention_count >= 5 then 'High Intervention'
      when intervention_count >= 2 then 'Moderate Intervention'
      when intervention_count > 0 then 'Low Intervention'
      else 'No Intervention'
    end as intervention_category,
    
    -- Academic Integrity
    plagiarism_incidents,
    writing_quality_score,
    
    -- Overall Risk Score (composite of all risk dimensions)
    -- FIXED: Now considers ALL risk levels, not just GPA and engagement
    case
      -- Critical: ANY dimension is Critical
      when gpa_risk_level = 'Critical'
        or completion_risk_level = 'Critical'
        or engagement_risk_level = 'Critical'
        or login_recency_risk_level = 'Critical'
      then 'Critical - Immediate Intervention'
      
      -- High: ANY dimension is High (and no Critical)
      when gpa_risk_level = 'High'
        or completion_risk_level = 'High'
        or engagement_risk_level = 'High'
        or login_recency_risk_level = 'High'
      then 'High - Priority Attention'
      
      -- Moderate: ANY dimension is Moderate (and no Critical or High)
      when gpa_risk_level = 'Moderate'
        or completion_risk_level = 'Moderate'
        or engagement_risk_level = 'Moderate'
        or login_recency_risk_level = 'Moderate'
      then 'Moderate - Monitor Closely'
      
      -- Low: All dimensions are Low
      else 'Low - Standard Support'
    end as overall_risk_assessment,
    
    enrollment_date,
    last_login_date,
    last_updated
  from source_data
),

final as (
  select
    *,
    -- Recommended Actions based on risk profile
    case
      when overall_risk_assessment = 'Critical - Immediate Intervention'
      then 'Schedule mandatory advisor meeting; Review academic plan; Connect with tutoring/counseling; Verify financial aid status'
      
      when overall_risk_assessment = 'High - Priority Attention'
      then 'Advisor check-in within 1 week; Offer academic support resources; Review course load'
      
      when overall_risk_assessment = 'Moderate - Monitor Closely'
      then 'Monitor engagement metrics; Send supportive communication; Track attendance patterns'
      
      else 'Continue standard support; Celebrate successes; Maintain engagement'
    end as recommended_action
  from risk_analysis
)

select * from final
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