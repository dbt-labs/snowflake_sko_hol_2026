select
    major_code,
    performance_quartile,
    performance_category
from {{ ref('vw_hed_program_performance') }}
where performance_quartile not in (1, 2, 3, 4)
   or (
        performance_quartile = 1
        and performance_category != 'Top Performing'
   )
   or (
        performance_quartile = 2
        and performance_category != 'Above Average'
   )
   or (
        performance_quartile = 3
        and performance_category != 'Below Average'
   )
   or (
        performance_quartile = 4
        and performance_category != 'Needs Improvement'
   )
