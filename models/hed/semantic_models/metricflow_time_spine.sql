-- models/metricflow_time_spine.sql
-- This model creates a time spine table required by the dbt Semantic Layer
-- It generates a row for each day/hour/etc to support time-based metric queries

{{
  config(
    materialized='table',
    tags=['metricflow']
  )
}}

WITH date_spine AS (
  {{ dbt_utils.date_spine(
      datepart="day",
      
      start_date="cast('2020-01-01' as date)",
      end_date="cast('2030-12-31' as date)"
  ) }}
)

SELECT
  date_day AS date_day
FROM date_spine