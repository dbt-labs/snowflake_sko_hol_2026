{% test credit_hours_earned_lte_attempted(model) %}

select *
from {{ model }}
where credit_hours_earned > credit_hours_attempted

{% endtest %}

{% test last_login_on_or_after_enrollment(model) %}

select *
from {{ model }}
where last_login_date is not null
  and enrollment_date is not null
  and last_login_date < enrollment_date

{% endtest %}
{% test value_in_list(model, column_name, values) %}

with validation_errors as (
    select {{ column_name }} as invalid_value
    from {{ model }}
    where {{ column_name }} is not null
      and {{ column_name }} not in (
        {% for value in values %}
          '{{ value }}'{% if not loop.last %}, {% endif %}
        {% endfor %}
      )
)

select *
from validation_errors

{% endtest %}

