select *
from {{ ref('stg_hed__students') }}
where total_course_views < 0
   or assignment_submissions < 0
   or discussion_posts < 0
   or plagiarism_incidents < 0
   or intervention_count < 0
