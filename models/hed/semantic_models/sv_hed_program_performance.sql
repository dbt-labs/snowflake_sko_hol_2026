{{ config(
    materialized="semantic_view",
    enabled=true,
    static_analysis="off",
    docs={'node_color': 'blue'}
) }}
  tables (
    PROGRAM_PERFORMANCE as {{ ref('vw_hed_program_performance') }} unique (MAJOR_CODE) comment='Program-level semantic view for academic performance by major. One row per academic program with enrollment, academic outcomes, retention, engagement, financial aid, and overall health metrics.'
  )
  facts (
    PROGRAM_PERFORMANCE.TOTAL_STUDENTS as TOTAL_STUDENTS comment='Number of students enrolled in this major',
    PROGRAM_PERFORMANCE.ADVISORS_ASSIGNED as ADVISORS_ASSIGNED comment='Number of advisors assigned to this major',
    PROGRAM_PERFORMANCE.AVG_STUDENTS_PER_ADVISOR as AVG_STUDENTS_PER_ADVISOR comment='Average student-to-advisor ratio',
    PROGRAM_PERFORMANCE.AVG_GPA as AVG_GPA comment='Average GPA for students in this major on a 4.0 scale',
    PROGRAM_PERFORMANCE.AVG_COMPLETION_RATE_PCT as AVG_COMPLETION_RATE_PCT comment='Average course completion rate as a percentage',
    PROGRAM_PERFORMANCE.AVG_ASSIGNMENT_SCORE as AVG_ASSIGNMENT_SCORE comment='Average assignment score for students in this major',
    PROGRAM_PERFORMANCE.CREDIT_SUCCESS_RATE as CREDIT_SUCCESS_RATE comment='Percentage of attempted credits successfully earned',
    PROGRAM_PERFORMANCE.AT_RISK_STUDENTS as AT_RISK_STUDENTS comment='Number of students flagged as at-risk in this major',
    PROGRAM_PERFORMANCE.AT_RISK_PERCENTAGE as AT_RISK_PERCENTAGE comment='Percentage of students at retention risk',
    PROGRAM_PERFORMANCE.HIGH_ACHIEVERS as HIGH_ACHIEVERS comment='Number of students in high academic standing categories',
    PROGRAM_PERFORMANCE.STUDENTS_ON_PROBATION as STUDENTS_ON_PROBATION comment='Number of students on academic probation or warning',
    PROGRAM_PERFORMANCE.PROBATION_RATE as PROBATION_RATE comment='Percentage of students on probation or warning',
    PROGRAM_PERFORMANCE.AVG_ENGAGEMENT_SCORE as AVG_ENGAGEMENT_SCORE comment='Average engagement score for students in this major on a 0-100 scale',
    PROGRAM_PERFORMANCE.AVG_COURSE_VIEWS as AVG_COURSE_VIEWS comment='Average course material views per student',
    PROGRAM_PERFORMANCE.TOTAL_PLAGIARISM_INCIDENTS as TOTAL_PLAGIARISM_INCIDENTS comment='Total academic integrity violations in this major',
    PROGRAM_PERFORMANCE.AVG_WRITING_QUALITY_SCORE as AVG_WRITING_QUALITY_SCORE comment='Average writing quality score on a 0-100 scale',
    PROGRAM_PERFORMANCE.TOTAL_INTERVENTIONS as TOTAL_INTERVENTIONS comment='Total academic interventions for students in this major',
    PROGRAM_PERFORMANCE.AVG_INTERVENTIONS_PER_STUDENT as AVG_INTERVENTIONS_PER_STUDENT comment='Average interventions per student',
    PROGRAM_PERFORMANCE.TOTAL_FINANCIAL_AID as TOTAL_FINANCIAL_AID comment='Total financial aid allocated to this major',
    PROGRAM_PERFORMANCE.AVG_FINANCIAL_AID_PER_STUDENT as AVG_FINANCIAL_AID_PER_STUDENT comment='Average financial aid per student',
    PROGRAM_PERFORMANCE.FINANCIAL_AID_COVERAGE_PCT as FINANCIAL_AID_COVERAGE_PCT comment='Percentage of students receiving financial aid',
    PROGRAM_PERFORMANCE.PROGRAM_HEALTH_SCORE as PROGRAM_HEALTH_SCORE comment='Composite program health score from 0-100 combining GPA, completion, engagement, and retention',
    PROGRAM_PERFORMANCE.OVERALL_HEALTH_RANK as OVERALL_HEALTH_RANK comment='Rank of the program by overall health score',
    PROGRAM_PERFORMANCE.PERFORMANCE_QUARTILE as PERFORMANCE_QUARTILE comment='Performance quartile where 1 is top-performing and 4 is lowest-performing'
  )
  dimensions (
    PROGRAM_PERFORMANCE.MAJOR_CODE as MAJOR_CODE comment='Academic major code identifying the program',
    PROGRAM_PERFORMANCE.PERFORMANCE_CATEGORY as PERFORMANCE_CATEGORY comment='Qualitative program performance classification derived from quartile'
  )
  comment='Program Performance semantic view for analyzing academic program outcomes by major. Exposes aggregated KPIs for enrollment, student success, retention risk, engagement, academic integrity, financial aid, and overall program health.'
