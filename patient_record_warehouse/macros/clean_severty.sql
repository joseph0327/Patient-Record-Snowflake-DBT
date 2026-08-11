{% macro clean_severity(column_name) %}

COALESCE(UPPER(TRIM({{ column_name }})), 'UNKNOWN')

{% endmacro %}