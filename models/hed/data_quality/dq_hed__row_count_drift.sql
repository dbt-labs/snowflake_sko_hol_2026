{{
  config(
    materialized='view',
    tags=['hed', 'data_quality', 'monitoring', 'row_count_drift']
  )
}}

with source_data as (
    select
        cast(last_updated as date) as updated_date,
        record_id
    from {{ ref('stg_hed__students') }}
    where last_updated is not null
),

daily_counts as (
    select
        updated_date,
        count(*) as records_updated_count
    from source_data
    group by 1
),

latest_day as (
    select max(updated_date) as latest_updated_date
    from daily_counts
),

current_day_count as (
    select
        d.updated_date as latest_updated_date,
        d.records_updated_count as current_row_count
    from daily_counts d
    inner join latest_day l
        on d.updated_date = l.latest_updated_date
),

baseline_window as (
    select
        d.records_updated_count
    from daily_counts d
    inner join latest_day l
        on d.updated_date between dateadd(day, -7, l.latest_updated_date)
                            and dateadd(day, -1, l.latest_updated_date)
),

baseline_metrics as (
    select
        count(*) as baseline_days,
        avg(records_updated_count) as avg_row_count_previous_7_days,
        min(records_updated_count) as min_row_count_previous_7_days,
        max(records_updated_count) as max_row_count_previous_7_days
    from baseline_window
)

select
    'Row Count Drift' as quality_dimension,
    c.latest_updated_date,
    c.current_row_count,
    b.baseline_days,
    round(b.avg_row_count_previous_7_days, 2) as avg_row_count_previous_7_days,
    b.min_row_count_previous_7_days,
    b.max_row_count_previous_7_days,
    round(
        case
            when nullif(b.avg_row_count_previous_7_days, 0) is null then null
            else ((c.current_row_count - b.avg_row_count_previous_7_days) / b.avg_row_count_previous_7_days) * 100
        end,
        2
    ) as row_count_drift_pct,
    case
        when b.baseline_days = 0 then 'Insufficient History'
        when abs((c.current_row_count - b.avg_row_count_previous_7_days) / nullif(b.avg_row_count_previous_7_days, 0)) <= 0.1 then 'Stable'
        when abs((c.current_row_count - b.avg_row_count_previous_7_days) / nullif(b.avg_row_count_previous_7_days, 0)) <= 0.25 then 'Moderate Drift'
        else 'Significant Drift'
    end as row_count_drift_status
from current_day_count c
cross join baseline_metrics b
