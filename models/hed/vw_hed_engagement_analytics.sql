{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'engagement', 'trends']
  )
}}

/*
  Student Engagement Analytics
  
  Purpose: Analyze patterns in student learning management system (LMS) engagement
  
  Engagement Dimensions:
  - Login frequency and recency
  - Course material interaction (views)
  - Assignment completion behavior
  - Discussion forum participation
  - Composite engagement scoring
  
  Use Cases:
  - Identify disengaged students early
  - Measure online learning effectiveness
  - Support evidence-based intervention timing
  - Track engagement trends by cohort/major
*/

with source_data as (
  select *
  from {{ source('hed', 'hed_records') }}
),

engagement_analysis as (
  select
    student_id,
    major_code,
    academic_standing,
    at_risk_flag,
    
    -- Login Behavior
    last_login_date,
    datediff('day', last_login_date, current_date()) as days_since_last_login,
    datediff('day', enrollment_date, last_login_date) as days_active_since_enrollment,
    case
      when datediff('day', last_login_date, current_date()) = 0 then 'Today'
      when datediff('day', last_login_date, current_date()) <= 1 then 'Within 24 Hours'
      when datediff('day', last_login_date, current_date()) <= 3 then 'Within 3 Days'
      when datediff('day', last_login_date, current_date()) <= 7 then 'Within 1 Week'
      when datediff('day', last_login_date, current_date()) <= 14 then 'Within 2 Weeks'
      else 'Over 2 Weeks Ago'
    end as login_recency_category,
    
    -- Course Content Engagement
    total_course_views,
    case
      when total_course_views >= 300 then 'Very High'
      when total_course_views >= 200 then 'High'
      when total_course_views >= 100 then 'Moderate'
      when total_course_views >= 50 then 'Low'
      else 'Very Low'
    end as course_views_category,
    
    -- Assignment Engagement
    assignment_submissions,
    avg_assignment_score,
    case
      when assignment_submissions >= 18 then 'Very Active'
      when assignment_submissions >= 14 then 'Active'
      when assignment_submissions >= 10 then 'Moderate'
      when assignment_submissions >= 6 then 'Low'
      else 'Very Low'
    end as assignment_activity_category,
    case
      when avg_assignment_score >= 85 then 'Excellent'
      when avg_assignment_score >= 75 then 'Good'
      when avg_assignment_score >= 65 then 'Satisfactory'
      when avg_assignment_score >= 50 then 'Needs Improvement'
      else 'Critical'
    end as assignment_performance_category,
    
    -- Discussion Forum Participation
    discussion_posts,
    case
      when discussion_posts >= 25 then 'Very Active'
      when discussion_posts >= 15 then 'Active'
      when discussion_posts >= 8 then 'Moderate'
      when discussion_posts >= 3 then 'Low'
      else 'Minimal'
    end as discussion_participation_category,
    
    -- Overall Engagement Metrics
    engagement_score,
    case
      when engagement_score >= 80 then 'Highly Engaged'
      when engagement_score >= 60 then 'Engaged'
      when engagement_score >= 40 then 'Moderately Engaged'
      when engagement_score >= 20 then 'Disengaged'
      else 'Critically Disengaged'
    end as engagement_level,
    
    -- Engagement Balance Score (measures diverse engagement across dimensions)
    round(
      (
        (total_course_views / 400.0 * 100) +  -- Normalize to 0-100
        (assignment_submissions / 25.0 * 100) +
        (discussion_posts / 35.0 * 100)
      ) / 3.0,
      1
    ) as engagement_balance_score,
    
    -- Academic Context
    current_gpa,
    course_completion_rate,
    
    -- Support Context
    intervention_count,
    
    enrollment_date,
    last_updated
  from source_data
),

engagement_segments as (
  select
    *,
    -- Engagement vs Performance Quadrant Analysis
    case
      when engagement_score >= 60 and current_gpa >= 3.0 
      then 'High Engagement / High Performance'
      
      when engagement_score >= 60 and current_gpa < 3.0 
      then 'High Engagement / Low Performance'
      
      when engagement_score < 60 and current_gpa >= 3.0 
      then 'Low Engagement / High Performance'
      
      else 'Low Engagement / Low Performance'
    end as engagement_performance_quadrant,
    
    -- Engagement Trend Concerns
    case
      when days_since_last_login > 14 
        and engagement_score < 40 
      then 'Immediate Concern - Student Dropout Risk'
      
      when days_since_last_login > 7 
        and engagement_score < 50 
      then 'Elevated Concern - Declining Engagement'
      
      when engagement_score < 30 
      then 'High Concern - Critically Disengaged'
      
      when assignment_submissions < 5 
        and discussion_posts < 3 
      then 'Moderate Concern - Minimal Participation'
      
      else 'No Immediate Concern'
    end as engagement_concern_level,
    
    -- Recommended Engagement Actions
    case
      when days_since_last_login > 14 
      then 'Immediate outreach required; Check student wellness'
      
      when engagement_score < 30 
      then 'Schedule advisor meeting; Review barriers to engagement'
      
      when assignment_submissions < 5 
      then 'Connect with instructor; Offer tutoring support'
      
      when discussion_posts < 3 
      then 'Encourage peer collaboration; Review discussion participation expectations'
      
      when engagement_score >= 80 
      then 'Acknowledge engagement; Consider peer mentor role'
      
      else 'Monitor ongoing; Maintain regular touchpoints'
    end as recommended_engagement_action
  from engagement_analysis
)

select * from engagement_segments
order by
  case engagement_concern_level
    when 'Immediate Concern - Student Dropout Risk' then 1
    when 'High Concern - Critically Disengaged' then 2
    when 'Elevated Concern - Declining Engagement' then 3
    when 'Moderate Concern - Minimal Participation' then 4
    else 5
  end,
  days_since_last_login desc,
  engagement_score asc
