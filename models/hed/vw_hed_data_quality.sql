{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'monitoring']
  )
}}

/*
  Higher Education Data Quality Monitor
  
  Purpose: Monitor data completeness, validity, and freshness for HED records
  
  Quality Checks:
  - Record completeness (null values)
  - Data validity (range checks, logical consistency)
  - Duplicate detection
  - Data freshness tracking
  - Anomaly identification
  
  Use Cases:
  - Daily data quality monitoring
  - Integration health checks
  - Data governance reporting
  - Issue detection and alerting
*/

with source_data as (
  select *
  from {{ source('hed', 'hed_records') }}
),

completeness_checks as (
  select
    'Record Completeness' as quality_dimension,
    count(*) as total_records,
    count(distinct student_id) as unique_students,
    count(distinct record_id) as unique_record_ids,
    
    -- Check for required field completeness
    count(*) - count(student_id) as missing_student_ids,
    count(*) - count(enrollment_date) as missing_enrollment_dates,
    count(*) - count(academic_standing) as missing_academic_standing,
    count(*) - count(current_gpa) as missing_gpa,
    count(*) - count(major_code) as missing_major_codes,
    count(*) - count(advisor_id) as missing_advisor_ids,
    
    -- Calculate completeness percentages
    round((count(student_id)::decimal / count(*)) * 100, 2) as student_id_completeness_pct,
    round((count(enrollment_date)::decimal / count(*)) * 100, 2) as enrollment_date_completeness_pct,
    round((count(academic_standing)::decimal / count(*)) * 100, 2) as academic_standing_completeness_pct,
    round((count(current_gpa)::decimal / count(*)) * 100, 2) as gpa_completeness_pct,
    round((count(major_code)::decimal / count(*)) * 100, 2) as major_completeness_pct,
    
    -- Overall completeness score
    round(
      (
        (count(student_id)::decimal / count(*)) +
        (count(enrollment_date)::decimal / count(*)) +
        (count(academic_standing)::decimal / count(*)) +
        (count(current_gpa)::decimal / count(*)) +
        (count(major_code)::decimal / count(*))
      ) / 5.0 * 100,
      1
    ) as overall_completeness_score
  from source_data
),

validity_checks as (
  select
    'Data Validity' as quality_dimension,
    
    -- GPA validity (should be between 0.0 and 4.0)
    count(case when current_gpa < 0.0 or current_gpa > 4.0 then 1 end) as invalid_gpa_records,
    round(
      count(case when current_gpa >= 0.0 and current_gpa <= 4.0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as gpa_validity_pct,
    
    -- Credit hours validity (earned should not exceed attempted)
    count(case when credit_hours_earned > credit_hours_attempted then 1 end) as invalid_credit_hour_records,
    round(
      count(case when credit_hours_earned <= credit_hours_attempted then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as credit_hours_validity_pct,
    
    -- Course completion rate validity (should be between 0.0 and 1.0)
    count(case when course_completion_rate < 0.0 or course_completion_rate > 1.0 then 1 end) as invalid_completion_rate_records,
    round(
      count(case when course_completion_rate >= 0.0 and course_completion_rate <= 1.0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as completion_rate_validity_pct,
    
    -- Engagement score validity (should be between 0 and 100)
    count(case when engagement_score < 0 or engagement_score > 100 then 1 end) as invalid_engagement_score_records,
    round(
      count(case when engagement_score >= 0 and engagement_score <= 100 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as engagement_score_validity_pct,
    
    -- Assignment score validity (should be between 0 and 100)
    count(case when avg_assignment_score < 0 or avg_assignment_score > 100 then 1 end) as invalid_assignment_score_records,
    round(
      count(case when avg_assignment_score >= 0 and avg_assignment_score <= 100 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as assignment_score_validity_pct,
    
    -- Financial aid validity (should be non-negative)
    count(case when financial_aid_amount < 0 then 1 end) as invalid_financial_aid_records,
    round(
      count(case when financial_aid_amount >= 0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as financial_aid_validity_pct,
    
    -- Date logic validity (enrollment should be before last login)
    count(case when enrollment_date > last_login_date then 1 end) as invalid_date_logic_records,
    round(
      count(case when enrollment_date <= last_login_date then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as date_logic_validity_pct,
    
    -- Overall validity score
    round(
      (
        (count(case when current_gpa >= 0.0 and current_gpa <= 4.0 then 1 end)::decimal / nullif(count(*), 0)) +
        (count(case when credit_hours_earned <= credit_hours_attempted then 1 end)::decimal / nullif(count(*), 0)) +
        (count(case when course_completion_rate >= 0.0 and course_completion_rate <= 1.0 then 1 end)::decimal / nullif(count(*), 0)) +
        (count(case when engagement_score >= 0 and engagement_score <= 100 then 1 end)::decimal / nullif(count(*), 0)) +
        (count(case when financial_aid_amount >= 0 then 1 end)::decimal / nullif(count(*), 0))
      ) / 5.0 * 100,
      1
    ) as overall_validity_score
  from source_data
),

duplicate_checks as (
  select
    'Duplicate Detection' as quality_dimension,
    count(*) as total_records,
    count(distinct student_id) as unique_students,
    count(*) - count(distinct student_id) as duplicate_student_records,
    count(distinct record_id) as unique_record_ids,
    count(*) - count(distinct record_id) as duplicate_record_ids,
    
    round(
      (count(distinct student_id)::decimal / count(*)) * 100,
      2
    ) as student_uniqueness_pct,
    round(
      (count(distinct record_id)::decimal / count(*)) * 100,
      2
    ) as record_id_uniqueness_pct
  from source_data
),

freshness_checks as (
  select
    'Data Freshness' as quality_dimension,
    max(last_updated) as most_recent_update,
    min(last_updated) as oldest_update,
    datediff('hour', max(last_updated), current_timestamp()) as hours_since_last_update,
    datediff('day', max(last_updated), current_timestamp()) as days_since_last_update,
    
    case
      when datediff('hour', max(last_updated), current_timestamp()) <= 1 then 'Excellent'
      when datediff('hour', max(last_updated), current_timestamp()) <= 6 then 'Good'
      when datediff('hour', max(last_updated), current_timestamp()) <= 24 then 'Acceptable'
      when datediff('day', max(last_updated), current_timestamp()) <= 3 then 'Needs Attention'
      else 'Stale Data'
    end as freshness_status,
    
    -- Check for stale individual records
    count(case when datediff('day', last_updated, current_timestamp()) > 7 then 1 end) as records_over_7_days_old,
    round(
      count(case when datediff('day', last_updated, current_timestamp()) <= 7 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      2
    ) as records_current_pct
  from source_data
),

anomaly_checks as (
  select
    'Anomaly Detection' as quality_dimension,
    
    -- Unusual academic standing with high GPA
    count(case 
      when academic_standing in ('Academic Probation', 'Academic Warning', 'Academic Suspension') 
        and current_gpa >= 3.5 
      then 1 
    end) as high_gpa_on_probation_anomalies,
    
    -- At-risk flag doesn't match poor performance
    count(case 
      when at_risk_flag = false 
        and (current_gpa < 2.0 or course_completion_rate < 0.5 or engagement_score < 30)
      then 1 
    end) as at_risk_flag_inconsistencies,
    
    -- High financial aid with zero amounts
    count(case when financial_aid_amount = 0 then 1 end) as students_without_financial_aid,
    round(
      count(case when financial_aid_amount > 0 then 1 end)::decimal 
      / nullif(count(*), 0) * 100,
      1
    ) as financial_aid_coverage_pct,
    
    -- Very low engagement with high completion rates
    count(case 
      when engagement_score < 30 
        and course_completion_rate > 0.85 
      then 1 
    end) as low_engagement_high_completion_anomalies,
    
    -- Plagiarism incidents
    sum(plagiarism_incidents) as total_plagiarism_incidents,
    count(case when plagiarism_incidents > 0 then 1 end) as students_with_incidents,
    count(case when plagiarism_incidents >= 5 then 1 end) as students_with_multiple_incidents
  from source_data
),

summary as (
  select
    current_timestamp() as quality_check_timestamp,
    'Overall Data Quality Summary' as report_section,
    
    -- Aggregate quality metrics from completeness_checks
    (select overall_completeness_score from completeness_checks) as completeness_score,
    (select overall_validity_score from validity_checks) as validity_score,
    (select student_uniqueness_pct from duplicate_checks) as uniqueness_score,
    (select records_current_pct from freshness_checks) as freshness_score,
    
    -- Calculate composite quality score
    round(
      (
        (select overall_completeness_score from completeness_checks) +
        (select overall_validity_score from validity_checks) +
        (select student_uniqueness_pct from duplicate_checks) +
        (select records_current_pct from freshness_checks)
      ) / 4.0,
      1
    ) as composite_quality_score,
    
    case
      when round(
        (
          (select overall_completeness_score from completeness_checks) +
          (select overall_validity_score from validity_checks) +
          (select student_uniqueness_pct from duplicate_checks) +
          (select records_current_pct from freshness_checks)
        ) / 4.0,
        1
      ) >= 95 then 'Excellent'
      when round(
        (
          (select overall_completeness_score from completeness_checks) +
          (select overall_validity_score from validity_checks) +
          (select student_uniqueness_pct from duplicate_checks) +
          (select records_current_pct from freshness_checks)
        ) / 4.0,
        1
      ) >= 85 then 'Good'
      when round(
        (
          (select overall_completeness_score from completeness_checks) +
          (select overall_validity_score from validity_checks) +
          (select student_uniqueness_pct from duplicate_checks) +
          (select records_current_pct from freshness_checks)
        ) / 4.0,
        1
      ) >= 70 then 'Acceptable'
      else 'Needs Improvement'
    end as overall_quality_status,
    
    (select total_records from completeness_checks) as total_records,
    (select unique_students from completeness_checks) as unique_students,
    (select most_recent_update from freshness_checks) as most_recent_data_update,
    (select hours_since_last_update from freshness_checks) as hours_since_last_update
)

select * from summary
