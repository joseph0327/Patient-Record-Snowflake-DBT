{% macro add_audit_columns() %}
CURRENT_TIMESTAMP() AS PROCESSED_AT
{% endmacro %}