{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'program', 'segmentation']
  )
}}

/*
  Academic Program Performance by Major
  
  Purpose: Analyze student outcomes across different academic programs
  
  Metrics by Program:
  - Enrollment numbers
  - Academic performance (GPA, completion rates)
  - Student engagement levels
  - Retention risk
  - Financial aid utilization
  
  Use Cases:
  - Program review and assessment
  - Resource allocation decisions
  - Curriculum improvement initiatives
  - Advisor workload balancing
*/

with source_data as (
  select *
  from {{ ref('stg_hed__students') }}
),

program_metrics as (
  select
    major_code,
    max(to_date(last_updated)) as snapshot_date,
    
    -- Enrollment Metrics
    count(distinct student_id) as total_students,
    count(distinct advisor_id) as advisors_assigned,
    round(
      count(distinct student_id)::decimal / nullif(count(distinct advisor_id), 0),
      1
    ) as avg_students_per_advisor,
    
    -- Academic Performance
    round(avg(current_gpa), 2) as avg_gpa,
    round(min(current_gpa), 2) as min_gpa,
    round(max(current_gpa), 2) as max_gpa,
    round(avg(course_completion_rate) * 100, 1) as avg_completion_rate_pct,
    round(avg(avg_assignment_score), 1) as avg_assignment_score,
    
    -- Credit Hour Analysis
    round(avg(credit_hours_attempted), 1) as avg_credits_attempted,
    round(avg(credit_hours_earned), 1) as avg_credits_earned,
    round(
      sum(credit_hours_earned)::decimal / nullif(sum(credit_hours_attempted), 0) * 100,
      1
    ) as credit_success_rate,
    
    -- Retention & Risk
    count(case when at_risk_flag = true then 1 end) as at_risk_students,
    round(
      count(case when at_risk_flag = true then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as at_risk_percentage,
    
    -- Academic Standing Distribution
    count(case when academic_standing in ('Dean''s List', 'Honor Roll', 'Excellent Standing', 'Distinguished Standing') 
      then 1 end) as high_achievers,
    count(case when academic_standing in ('Academic Probation', 'Academic Warning', 'Probationary Status', 'Academic Suspension') 
      then 1 end) as students_on_probation,
    round(
      count(case when academic_standing in ('Academic Probation', 'Academic Warning', 'Probationary Status', 'Academic Suspension') 
        then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as probation_rate,
    
    -- Engagement Metrics
    round(avg(engagement_score), 1) as avg_engagement_score,
    round(avg(total_course_views), 0) as avg_course_views,
    round(avg(assignment_submissions), 1) as avg_assignments,
    round(avg(discussion_posts), 1) as avg_discussion_posts,
    
    -- Academic Integrity
    sum(plagiarism_incidents) as total_plagiarism_incidents,
    round(avg(writing_quality_score), 1) as avg_writing_quality_score,
    
    -- Financial Aid
    sum(financial_aid_amount) as total_financial_aid,
    round(avg(financial_aid_amount), 2) as avg_financial_aid_per_student,
    count(case when financial_aid_amount > 0 then 1 end) as students_with_aid,
    round(
      count(case when financial_aid_amount > 0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as financial_aid_coverage_pct,
    
    -- Intervention Support
    sum(intervention_count) as total_interventions,
    round(avg(intervention_count), 1) as avg_interventions_per_student,
    count(case when intervention_count >= 3 then 1 end) as students_with_frequent_interventions,
    
    -- Program Health Score (composite metric)
    round(
      (
        (avg(current_gpa) / 4.0 * 25) +  -- 25% weight on GPA
        (avg(course_completion_rate) * 25) +  -- 25% weight on completion
        (avg(engagement_score) / 100 * 25) +  -- 25% weight on engagement
        ((1 - (count(case when at_risk_flag = true then 1 end)::decimal / nullif(count(*), 0))) * 25)  -- 25% weight on retention
      ),
      1
    ) as program_health_score
  from source_data
  group by major_code
),

ranked_programs as (
  select
    *,
    -- Rankings for comparison
    rank() over (order by avg_gpa desc) as gpa_rank,
    rank() over (order by avg_completion_rate_pct desc) as completion_rank,
    rank() over (order by at_risk_percentage asc) as retention_rank,
    rank() over (order by program_health_score desc) as overall_health_rank,
    
    -- Quartile classifications
    ntile(4) over (order by program_health_score desc) as performance_quartile
  from program_metrics
)

select
  major_code,
  snapshot_date,
  total_students,
  advisors_assigned,
  avg_students_per_advisor,
  
  -- Academic Metrics
  avg_gpa,
  avg_completion_rate_pct,
  avg_assignment_score,
  credit_success_rate,
  
  -- Risk & Retention
  at_risk_students,
  at_risk_percentage,
  high_achievers,
  students_on_probation,
  probation_rate,
  
  -- Engagement
  avg_engagement_score,
  avg_course_views,
  
  -- Support & Integrity
  total_plagiarism_incidents,
  avg_writing_quality_score,
  total_interventions,
  avg_interventions_per_student,
  
  -- Financial
  total_financial_aid,
  avg_financial_aid_per_student,
  financial_aid_coverage_pct,
  
  -- Overall Health
  program_health_score,
  overall_health_rank,
  performance_quartile,
  case performance_quartile
    when 1 then 'Top Performing'
    when 2 then 'Above Average'
    when 3 then 'Below Average'
    when 4 then 'Needs Improvement'
  end as performance_category
from ranked_programs
order by program_health_score desc, total_students desc
