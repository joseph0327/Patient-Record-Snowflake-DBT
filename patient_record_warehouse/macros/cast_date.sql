{% macro cast_date(column_name) %}
    CAST({{ column_name }} AS DATE)
{% endmacro %}