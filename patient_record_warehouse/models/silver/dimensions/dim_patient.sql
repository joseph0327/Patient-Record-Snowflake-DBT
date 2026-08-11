WITH snapshot_data AS (

    SELECT *
    FROM {{ ref('patient_snapshot') }}

),

patient_history AS (

    SELECT

        {{ dbt_utils.generate_surrogate_key(
            [
                'PATIENT_ID',
                'DBT_VALID_FROM'
            ]
        ) }} AS PATIENT_SK,

        PATIENT_ID,
        FIRST_NAME,
        LAST_NAME,
        DATE_OF_BIRTH,
        GENDER,
        EMAIL,
        PHONE,
        ADDRESS,
        SSN,
        INSURANCE_NUMBER,
        INSURANCE_COMPANY,
        MEDICAL_HISTORY,
        DBT_VALID_FROM AS EFFECTIVE_START_DATE,
        DBT_VALID_TO AS EFFECTIVE_END_DATE,
        CASE
            WHEN DBT_VALID_TO IS NULL THEN TRUE
            ELSE FALSE
        END AS IS_CURRENT,
        SOURCE_SYSTEM,
        CREATED_TIMESTAMP,
        CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP

    FROM snapshot_data

)

SELECT *
FROM patient_history