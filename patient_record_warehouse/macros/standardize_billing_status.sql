{% macro standardize_billing_status(column_name) %}

CASE
    WHEN UPPER(TRIM({{ column_name }})) = 'PAID' THEN 'PAID'
    WHEN UPPER(TRIM({{ column_name }})) = 'PENDING' THEN 'PENDING'
    WHEN UPPER(TRIM({{ column_name }})) = 'DENIED' THEN 'DENIED'
    WHEN UPPER(TRIM({{ column_name }})) = 'CANCELLED' THEN 'CANCELLED'
    ELSE 'UNKNOWN'
END

{% endmacro %}