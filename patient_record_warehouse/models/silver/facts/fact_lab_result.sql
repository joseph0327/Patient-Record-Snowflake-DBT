WITH lab_result AS (
    SELECT *
    FROM {{ ref('stg_lab_result') }}
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
    {{ dbt_utils.generate_surrogate_key(['l.LAB_ID']) }} AS LAB_RESULT_SK,
    l.LAB_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    d.DOCTOR_SK,
    d.DOCTOR_ID,
    dt.DATE_SK,
    l.LAB_CATEGORY,
    l.TEST_NAME,
    l.RESULT_VALUE,
    l.RESULT_UNIT,
    l.REFERENCE_RANGE,
    l.RESULT_STATUS,
    l.LAB_LOCATION,
    l.TEST_DATE,
    l.CREATED_TIMESTAMP,
    l.SOURCE_SYSTEM,
    l.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM lab_result l
LEFT JOIN patient p
ON l.PATIENT_ID = p.PATIENT_ID
LEFT JOIN doctor d
ON l.ORDERING_DOCTOR_ID = d.DOCTOR_ID
LEFT JOIN date_dim dt
ON l.TEST_DATE = dt.FULL_DATE