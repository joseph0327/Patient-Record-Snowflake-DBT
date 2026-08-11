{% macro cast_number(column_name, data_type='BIGINT') %}
    CAST({{ column_name }} AS {{ data_type }})
{% endmacro %}
