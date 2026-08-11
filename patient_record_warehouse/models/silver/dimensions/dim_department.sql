WITH departments AS (

    SELECT DISTINCT
        TRIM(UPPER(DEPARTMENT)) AS DEPARTMENT_NAME
    FROM {{ ref('stg_visit') }}
    WHERE DEPARTMENT IS NOT NULL

)

SELECT

    {{ dbt_utils.generate_surrogate_key(
        ['DEPARTMENT_NAME']
    ) }} AS DEPARTMENT_SK,

    DEPARTMENT_NAME,

    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP

FROM departments