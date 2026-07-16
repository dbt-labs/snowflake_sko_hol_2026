{{ config(
    materialized="semantic_view",
    enabled=true,
    static_analysis="off",
    docs={'node_color': 'blue'}
) }}
  tables (
    HIGH_PERFORMING_STUDENTS as {{ ref('vw_hed_high_performing_students') }} unique (STUDENT_ID) comment='View of students performing well based on strong academic outcomes and engagement. Filters to students in the High Engagement / High Performance quadrant with GPA at or above 3.0 and engagement score at or above 60.'
  )
  facts (
    HIGH_PERFORMING_STUDENTS.ASSIGNMENT_SUBMISSIONS as ASSIGNMENT_SUBMISSIONS comment='Number of assignments submitted',
    HIGH_PERFORMING_STUDENTS.COURSE_COMPLETION_RATE as COURSE_COMPLETION_RATE comment='Percentage of courses completed (0.0-1.0 decimal). Multiply by 100 for percentage.',
    HIGH_PERFORMING_STUDENTS.CURRENT_GPA as CURRENT_GPA comment='Current cumulative GPA on 4.0 scale. Higher values indicate stronger academic performance.',
    HIGH_PERFORMING_STUDENTS.DAYS_ACTIVE_SINCE_ENROLLMENT as DAYS_ACTIVE_SINCE_ENROLLMENT comment='Days between enrollment and last login.',
    HIGH_PERFORMING_STUDENTS.DAYS_SINCE_LAST_LOGIN as DAYS_SINCE_LAST_LOGIN comment='Days elapsed since last LMS login. Lower values indicate more recent engagement.',
    HIGH_PERFORMING_STUDENTS.DISCUSSION_POSTS as DISCUSSION_POSTS comment='Number of discussion forum posts',
    HIGH_PERFORMING_STUDENTS.ENGAGEMENT_BALANCE_SCORE as ENGAGEMENT_BALANCE_SCORE comment='Normalized score measuring diversity of engagement across learning activities.',
    HIGH_PERFORMING_STUDENTS.ENGAGEMENT_SCORE as ENGAGEMENT_SCORE comment='Composite engagement metric on 0-100 scale. Higher is better.',
    HIGH_PERFORMING_STUDENTS.INTERVENTION_COUNT as INTERVENTION_COUNT comment='Number of academic interventions received',
    HIGH_PERFORMING_STUDENTS.TOTAL_COURSE_VIEWS as TOTAL_COURSE_VIEWS comment='Total number of course material views'
  )
  dimensions (
    HIGH_PERFORMING_STUDENTS.ACADEMIC_STANDING as ACADEMIC_STANDING comment='Current academic status. High-performing students typically include Good Standing, Excellent Standing, Dean''s List, or Honor Roll values.',
    HIGH_PERFORMING_STUDENTS.ASSIGNMENT_ACTIVITY_CATEGORY as ASSIGNMENT_ACTIVITY_CATEGORY comment='Categorical classification of assignment submission activity',
    HIGH_PERFORMING_STUDENTS.ASSIGNMENT_PERFORMANCE_CATEGORY as ASSIGNMENT_PERFORMANCE_CATEGORY comment='Categorical classification of assignment performance',
    HIGH_PERFORMING_STUDENTS.AT_RISK_FLAG as AT_RISK_FLAG comment='Boolean indicating retention risk status. High-performing students should generally not be flagged as at-risk.',
    HIGH_PERFORMING_STUDENTS.DISCUSSION_PARTICIPATION_CATEGORY as DISCUSSION_PARTICIPATION_CATEGORY comment='Categorical classification of discussion participation',
    HIGH_PERFORMING_STUDENTS.ENGAGEMENT_CONCERN_LEVEL as ENGAGEMENT_CONCERN_LEVEL comment='Urgency classification for engagement-related concerns',
    HIGH_PERFORMING_STUDENTS.ENGAGEMENT_LEVEL as ENGAGEMENT_LEVEL comment='Qualitative engagement level classification',
    HIGH_PERFORMING_STUDENTS.ENGAGEMENT_PERFORMANCE_QUADRANT as ENGAGEMENT_PERFORMANCE_QUADRANT comment='Combined engagement and academic performance classification. This view is filtered to High Engagement / High Performance.',
    HIGH_PERFORMING_STUDENTS.ENROLLMENT_DATE as ENROLLMENT_DATE comment='Student enrollment date',
    HIGH_PERFORMING_STUDENTS.LAST_LOGIN_DATE as LAST_LOGIN_DATE comment='Most recent LMS login timestamp',
    HIGH_PERFORMING_STUDENTS.LAST_UPDATED as LAST_UPDATED comment='Timestamp of last record update',
    HIGH_PERFORMING_STUDENTS.LOGIN_RECENCY_CATEGORY as LOGIN_RECENCY_CATEGORY comment='Categorical description of login recency',
    HIGH_PERFORMING_STUDENTS.MAJOR_CODE as MAJOR_CODE comment='Academic major code (e.g., ENGR, BUSN, NURS, PSYC)',
    HIGH_PERFORMING_STUDENTS.RECOMMENDED_ENGAGEMENT_ACTION as RECOMMENDED_ENGAGEMENT_ACTION comment='Recommended action associated with the student''s engagement profile',
    HIGH_PERFORMING_STUDENTS.STUDENT_ID as STUDENT_ID comment='Unique student identifier (e.g., STU_202400001)'
  )
  comment='Student performance semantic view for analyzing high-performing students. Contains academic outcomes, engagement metrics, participation signals, and supporting dimensions for students who are thriving academically and behaviorally.'
  with extension (CA='{"tables":[{"name":"high_performing_students","dimensions":[{"name":"academic_standing"},{"name":"assignment_activity_category"},{"name":"assignment_performance_category"},{"name":"at_risk_flag"},{"name":"discussion_participation_category"},{"name":"engagement_concern_level"},{"name":"engagement_level"},{"name":"engagement_performance_quadrant"},{"name":"enrollment_date"},{"name":"last_login_date"},{"name":"last_updated"},{"name":"login_recency_category"},{"name":"major_code"},{"name":"recommended_engagement_action"},{"name":"student_id"}],"facts":[{"name":"assignment_submissions"},{"name":"course_completion_rate"},{"name":"current_gpa"},{"name":"days_active_since_enrollment"},{"name":"days_since_last_login"},{"name":"discussion_posts"},{"name":"engagement_balance_score"},{"name":"engagement_score"},{"name":"intervention_count"},{"name":"total_course_views"}]}]}')

