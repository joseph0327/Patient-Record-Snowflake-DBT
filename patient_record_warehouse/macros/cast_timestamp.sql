{% macro cast_timestamp(column_name) %}
    CAST({{ column_name }} AS TIMESTAMP)
{% endmacro %}