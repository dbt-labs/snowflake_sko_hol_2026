{{
  config(
    materialized='view',
    tags=['hed', 'analytics', 'kpi', 'executive']
  )
}}

/*
  Higher Education KPI Dashboard
  
  Purpose: Executive-level summary of key student success metrics
  
  Metrics:
  - Total student enrollment
  - Retention risk overview (at-risk %)
  - Academic performance (avg GPA, completion rates)
  - Student engagement levels
  - Financial aid distribution
  - Academic integrity incidents
*/

with source_data as (
  select *
  from {{ ref('stg_hed__student') }}
),

kpi_summary as (
  select
    -- Enrollment Metrics
    count(distinct student_id) as total_students,
    count(distinct case when at_risk_flag = true then student_id end) as at_risk_students,
    round(
      count(distinct case when at_risk_flag = true then student_id end)::decimal 
      / nullif(count(distinct student_id), 0) * 100, 
      1
    ) as at_risk_percentage,
    
    -- Academic Performance Metrics
    round(avg(current_gpa), 2) as avg_gpa,
    round(avg(course_completion_rate) * 100, 1) as avg_completion_rate_pct,
    round(avg(avg_assignment_score), 1) as avg_assignment_score,
    round(
      sum(credit_hours_earned)::decimal / nullif(sum(credit_hours_attempted), 0) * 100,
      1
    ) as credit_hour_success_rate,
    
    -- Engagement Metrics
    round(avg(engagement_score), 1) as avg_engagement_score,
    round(avg(total_course_views), 0) as avg_course_views,
    round(avg(assignment_submissions), 1) as avg_assignments_submitted,
    round(avg(discussion_posts), 1) as avg_discussion_posts,
    
    -- Quality & Integrity Metrics
    sum(plagiarism_incidents) as total_plagiarism_incidents,
    round(
      sum(case when plagiarism_incidents > 0 then 1 else 0 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as students_with_incidents_pct,
    round(avg(writing_quality_score), 1) as avg_writing_quality_score,
    
    -- Financial Aid Metrics
    sum(financial_aid_amount) as total_financial_aid,
    round(avg(financial_aid_amount), 2) as avg_financial_aid_per_student,
    count(case when financial_aid_amount > 0 then 1 end) as students_receiving_aid,
    round(
      count(case when financial_aid_amount > 0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as financial_aid_coverage_pct,
    
    -- Intervention Metrics
    sum(intervention_count) as total_interventions,
    round(avg(intervention_count), 1) as avg_interventions_per_student,
    count(case when intervention_count > 0 then 1 end) as students_with_interventions,
    
    -- Data Freshness
    max(last_updated) as last_data_refresh,
    current_timestamp() as report_generated_at
  from source_data
)

select * from kpi_summary
