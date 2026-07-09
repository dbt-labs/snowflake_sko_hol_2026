with validation_errors as (
    select
        record_id,
        student_id,
        credit_hours_attempted,
        credit_hours_earned
    from {{ source('hed', 'hed_records') }}
    where credit_hours_earned > credit_hours_attempted
)

select * from validation_errors
