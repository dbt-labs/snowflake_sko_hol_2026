{{ config(
    materialized="semantic_view",
    enabled=true,
    static_analysis="off",
    docs={'node_color': 'blue'}
) }}
  tables (
    STUDENT_SUCCESS_KPI as {{ ref('vw_hed_student_success_kpi') }} comment='Executive-level student success KPI summary view. Contains one-row aggregates for enrollment, retention risk, academic performance, engagement, financial aid, interventions, and data freshness.'
  )
  facts (
    STUDENT_SUCCESS_KPI.TOTAL_STUDENTS as TOTAL_STUDENTS comment='Total count of unique students',
    STUDENT_SUCCESS_KPI.AT_RISK_STUDENTS as AT_RISK_STUDENTS comment='Number of students flagged as at-risk for retention',
    STUDENT_SUCCESS_KPI.AT_RISK_PERCENTAGE as AT_RISK_PERCENTAGE comment='Percentage of students at retention risk',
    STUDENT_SUCCESS_KPI.AVG_GPA as AVG_GPA comment='Average GPA across all students',
    STUDENT_SUCCESS_KPI.AVG_COMPLETION_RATE_PCT as AVG_COMPLETION_RATE_PCT comment='Average course completion rate as percentage',
    STUDENT_SUCCESS_KPI.AVG_ASSIGNMENT_SCORE as AVG_ASSIGNMENT_SCORE comment='Average assignment score across all students',
    STUDENT_SUCCESS_KPI.CREDIT_HOUR_SUCCESS_RATE as CREDIT_HOUR_SUCCESS_RATE comment='Percentage of attempted credit hours successfully earned',
    STUDENT_SUCCESS_KPI.AVG_ENGAGEMENT_SCORE as AVG_ENGAGEMENT_SCORE comment='Average student engagement score (0-100)',
    STUDENT_SUCCESS_KPI.AVG_COURSE_VIEWS as AVG_COURSE_VIEWS comment='Average number of course material views per student',
    STUDENT_SUCCESS_KPI.AVG_ASSIGNMENTS_SUBMITTED as AVG_ASSIGNMENTS_SUBMITTED comment='Average number of assignments submitted per student',
    STUDENT_SUCCESS_KPI.AVG_DISCUSSION_POSTS as AVG_DISCUSSION_POSTS comment='Average number of discussion posts per student',
    STUDENT_SUCCESS_KPI.TOTAL_PLAGIARISM_INCIDENTS as TOTAL_PLAGIARISM_INCIDENTS comment='Total academic integrity violations across all students',
    STUDENT_SUCCESS_KPI.STUDENTS_WITH_INCIDENTS_PCT as STUDENTS_WITH_INCIDENTS_PCT comment='Percentage of students with at least one plagiarism incident',
    STUDENT_SUCCESS_KPI.AVG_WRITING_QUALITY_SCORE as AVG_WRITING_QUALITY_SCORE comment='Average writing quality assessment score',
    STUDENT_SUCCESS_KPI.TOTAL_FINANCIAL_AID as TOTAL_FINANCIAL_AID comment='Total financial aid distributed to all students',
    STUDENT_SUCCESS_KPI.AVG_FINANCIAL_AID_PER_STUDENT as AVG_FINANCIAL_AID_PER_STUDENT comment='Average financial aid amount per student',
    STUDENT_SUCCESS_KPI.STUDENTS_RECEIVING_AID as STUDENTS_RECEIVING_AID comment='Number of students receiving financial aid',
    STUDENT_SUCCESS_KPI.FINANCIAL_AID_COVERAGE_PCT as FINANCIAL_AID_COVERAGE_PCT comment='Percentage of students receiving financial aid',
    STUDENT_SUCCESS_KPI.TOTAL_INTERVENTIONS as TOTAL_INTERVENTIONS comment='Total academic interventions/support sessions',
    STUDENT_SUCCESS_KPI.AVG_INTERVENTIONS_PER_STUDENT as AVG_INTERVENTIONS_PER_STUDENT comment='Average number of interventions per student',
    STUDENT_SUCCESS_KPI.STUDENTS_WITH_INTERVENTIONS as STUDENTS_WITH_INTERVENTIONS comment='Number of students who have received interventions'
  )
  dimensions (
    STUDENT_SUCCESS_KPI.LAST_DATA_REFRESH as LAST_DATA_REFRESH comment='Timestamp of most recent data update',
    STUDENT_SUCCESS_KPI.REPORT_GENERATED_AT as REPORT_GENERATED_AT comment='Timestamp when this KPI summary was generated'
  )
  comment='Snowflake semantic view over vw_hed_student_success_kpi exposing executive KPI summary facts and freshness dimensions for student success reporting.'
