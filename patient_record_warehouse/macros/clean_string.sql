{% macro clean_string(column_name, uppercase=true) %}

    {% if uppercase %}
        UPPER(TRIM({{ column_name }}))
    {% else %}
        TRIM({{ column_name }})
    {% endif %}

{% endmacro %}