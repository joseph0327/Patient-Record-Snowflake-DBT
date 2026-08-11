{% macro null_if_blank(column_name) %}
    NULLIF(TRIM({{ column_name }}), '')
{% endmacro %}