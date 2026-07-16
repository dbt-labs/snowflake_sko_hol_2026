{{ config(
    materialized="semantic_view",
    enabled=true,
    static_analysis="off",
    docs={'node_color': 'blue'}
) }}
  tables (
    AT_RISK_STUDENTS as {{ ref('vw_hed_retention_risk_analysis') }} unique (STUDENT_ID) comment='View of students flagged as at-risk based on multiple retention indicators including GPA, course completion, engagement scores, login activity, and academic standing. Data flows from PostgreSQL through Fivetran to this Snowflake view via dbt transformations'
  )
  facts (
    AT_RISK_STUDENTS.ASSIGNMENT_SUBMISSIONS as ASSIGNMENT_SUBMISSIONS comment='Number of assignments submitted',
    AT_RISK_STUDENTS.COURSE_COMPLETION_RATE as COURSE_COMPLETION_RATE comment='Percentage of courses completed (0.0-1.0 decimal). Multiply by 100 for percentage.',
    AT_RISK_STUDENTS.CURRENT_GPA as CURRENT_GPA comment='Current cumulative GPA on 4.0 scale. Below 2.0 is critical threshold.',
    AT_RISK_STUDENTS.DAYS_SINCE_LAST_LOGIN as DAYS_SINCE_LAST_LOGIN comment='Days elapsed since last LMS login. 21+ days is critical threshold.',
    AT_RISK_STUDENTS.DISCUSSION_POSTS as DISCUSSION_POSTS comment='Number of discussion forum posts',
    (AT_RISK_STUDENTS.DISCUSSION_POSTS / nullif(AT_RISK_STUDENTS.ASSIGNMENT_SUBMISSIONS, 0)) as DISCUSSION_POSTS_PER_ASSIGNMENT_SUBMISSION comment='Ratio of discussion posts to assignment submissions; null when assignment submissions is zero',
    AT_RISK_STUDENTS.ENGAGEMENT_SCORE as ENGAGEMENT_SCORE comment='Composite engagement metric on 0-100 scale. Higher is better.',
    AT_RISK_STUDENTS.FINANCIAL_AID_AMOUNT as FINANCIAL_AID_AMOUNT comment='Total financial aid received in USD',
    AT_RISK_STUDENTS.INTERVENTION_COUNT as INTERVENTION_COUNT comment='Number of academic interventions received',
    AT_RISK_STUDENTS.PLAGIARISM_INCIDENTS as PLAGIARISM_INCIDENTS comment='Number of academic integrity violations',
    AT_RISK_STUDENTS.TOTAL_COURSE_VIEWS as TOTAL_COURSE_VIEWS comment='Total number of course material views',
    AT_RISK_STUDENTS.WRITING_QUALITY_SCORE as WRITING_QUALITY_SCORE comment='Writing assessment score (0-100 scale)'
  )
  dimensions (
    AT_RISK_STUDENTS.ACADEMIC_STANDING as ACADEMIC_STANDING comment='Current academic status. Critical values include Probation, Warning, and Suspension.',
    AT_RISK_STUDENTS.ADVISOR_ID as ADVISOR_ID comment='Assigned academic advisor identifier',
    AT_RISK_STUDENTS.AT_RISK_FLAG as AT_RISK_FLAG comment='Boolean indicating if student is flagged as at-risk (always TRUE in this view)',
    AT_RISK_STUDENTS.COMPLETION_RISK_LEVEL as COMPLETION_RISK_LEVEL comment='Risk categorization based on course completion rate',
    AT_RISK_STUDENTS.ENGAGEMENT_RISK_LEVEL as ENGAGEMENT_RISK_LEVEL comment='Risk categorization based on engagement score',
    AT_RISK_STUDENTS.ENROLLMENT_DATE as ENROLLMENT_DATE comment='Student enrollment date',
    AT_RISK_STUDENTS.GPA_RISK_LEVEL as GPA_RISK_LEVEL comment='Risk categorization based on GPA (Critical/High/Moderate/Low)',
    AT_RISK_STUDENTS.LAST_LOGIN_DATE as LAST_LOGIN_DATE comment='Most recent LMS login timestamp',
    AT_RISK_STUDENTS.LAST_UPDATED as LAST_UPDATED comment='Timestamp of last Fivetran sync',
    AT_RISK_STUDENTS.LOGIN_RECENCY_RISK_LEVEL as LOGIN_RECENCY_RISK_LEVEL comment='Risk categorization based on days since last login',
    AT_RISK_STUDENTS.MAJOR_CODE as MAJOR_CODE comment='Academic major code (e.g., ENGR, BUSN, NURS, PSYC)',
    AT_RISK_STUDENTS.OVERALL_RISK_ASSESSMENT as OVERALL_RISK_ASSESSMENT comment='Composite risk level with severity classification combining multiple risk factors. Critical and High levels require immediate intervention.',
    AT_RISK_STUDENTS.RECOMMENDED_ACTION as RECOMMENDED_ACTION comment='Specific recommended interventions based on student''s risk profile',
    AT_RISK_STUDENTS.STUDENT_ID as STUDENT_ID comment='Unique student identifier (e.g., STU_202400001)'
  )
  comment='Student Retention semantic model for analyzing at-risk students. Contains multi-factor risk assessments, academic performance metrics, engagement analytics, financial aid information, and recommended interventions. Used for identifying students requiring support and routing retention alerts to appropriate academic staff.'
  with extension (CA='{"tables":[{"name":"at_risk_students","dimensions":[{"name":"academic_standing","sample_values":["Dean''s List","Excellent Standing","Good Standing","Satisfactory Progress","Conditional Standing","Academic Warning","Warning Status","Probationary Status","Academic Probation","Academic Suspension"]},{"name":"advisor_id"},{"name":"at_risk_flag"},{"name":"completion_risk_level","sample_values":["Critical","High","Moderate","Low"]},{"name":"engagement_risk_level","sample_values":["Critical","High","Moderate","Low"]},{"name":"enrollment_date"},{"name":"gpa_risk_level","sample_values":["Critical","High","Moderate","Low"]},{"name":"last_login_date"},{"name":"last_updated"},{"name":"login_recency_risk_level","sample_values":["Critical","High","Moderate","Low"]},{"name":"major_code","sample_values":["ENGR","BUSN","NURS","PSYC","COMP","BIOL"]},{"name":"overall_risk_assessment","sample_values":["Critical - Immediate Intervention","High - Priority Attention","Moderate - Monito...[truncated]
