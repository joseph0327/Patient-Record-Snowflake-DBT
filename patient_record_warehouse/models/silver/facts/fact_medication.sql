WITH medication AS (
    SELECT *
    FROM {{ ref('stg_medication') }}
),
patient AS (
    SELECT
        PATIENT_SK,
        PATIENT_ID
    FROM {{ ref('dim_patient_current') }}
),
doctor AS (
    SELECT
        DOCTOR_SK,
        DOCTOR_ID
    FROM {{ ref('dim_doctor') }}
),
date_dim AS (
    SELECT
        DATE_SK,
        FULL_DATE
    FROM {{ ref('dim_date') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['m.MEDICATION_ID']) }} AS MEDICATION_SK,

    m.MEDICATION_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    d.DOCTOR_SK,
    d.DOCTOR_ID,
    dt.DATE_SK,
    m.MEDICATION_NAME,
    m.DOSAGE,
    m.FREQUENCY,
    m.START_DATE,
    m.STATUS,
    m.CREATED_TIMESTAMP,
    m.SOURCE_SYSTEM,
    m.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM medication m
LEFT JOIN patient p
ON m.PATIENT_ID = p.PATIENT_ID
LEFT JOIN doctor d
ON m.PRESCRIBED_BY = d.DOCTOR_ID
LEFT JOIN date_dim dt
ON m.START_DATE = dt.FULL_DATE