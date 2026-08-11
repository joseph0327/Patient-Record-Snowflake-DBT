WITH doctors AS (
    SELECT DOCTOR_ID
    FROM {{ ref('stg_visit') }}
    WHERE DOCTOR_ID IS NOT NULL

    UNION

    SELECT DOCTOR_ID
    FROM {{ ref('stg_diagnosis') }}
    WHERE DOCTOR_ID IS NOT NULL

    UNION

    SELECT ORDERING_DOCTOR_ID AS DOCTOR_ID
    FROM {{ ref('stg_lab_result') }}
    WHERE ORDERING_DOCTOR_ID IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['DOCTOR_ID']
    ) }} AS DOCTOR_SK,

    DOCTOR_ID,

    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP

FROM doctors