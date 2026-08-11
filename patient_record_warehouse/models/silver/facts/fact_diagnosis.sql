WITH diagnosis AS (
    SELECT *
    FROM {{ ref('stg_diagnosis') }}
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
    {{ dbt_utils.generate_surrogate_key(['d.DIAGNOSIS_ID']) }} AS DIAGNOSIS_SK,
    d.DIAGNOSIS_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    doc.DOCTOR_SK,
    dt.DATE_SK,
    d.VISIT_ID,
    d.ICD10_CODE,
    d.DIAGNOSIS_NAME,
    d.SEVERITY,
    d.DIAGNOSIS_DATE,
    d.CREATED_TIMESTAMP,
    d.SOURCE_SYSTEM,
    d.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM diagnosis d

LEFT JOIN patient p
ON d.PATIENT_ID = p.PATIENT_ID

LEFT JOIN doctor doc
ON d.DOCTOR_ID = doc.DOCTOR_ID

LEFT JOIN date_dim dt
ON d.DIAGNOSIS_DATE = dt.FULL_DATE