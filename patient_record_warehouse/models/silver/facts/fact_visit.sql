WITH visit AS (
    SELECT *
    FROM {{ ref('stg_visit') }}
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
department AS (
    SELECT
        DEPARTMENT_SK,
        DEPARTMENT_NAME,
    FROM {{ ref('dim_department') }}
),
date AS (
    SELECT
        DATE_SK,
        FULL_DATE
    FROM {{ ref('dim_date') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['v.VISIT_ID']) }} AS VISIT_SK,
    v.VISIT_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    d.DOCTOR_SK,
    d.DOCTOR_ID,
    dt.DATE_SK,
    dep.DEPARTMENT_SK,
    dep.DEPARTMENT_NAME,
    v.DIAGNOSIS,
    v.VISIT_REASON,
    v.VISIT_STATUS,
    v.APPOINTMENT_DATE,
    v.CREATED_TIMESTAMP,
    v.SOURCE_SYSTEM,
    v.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM visit v
LEFT JOIN patient p
ON v.PATIENT_ID = p.PATIENT_ID
LEFT JOIN doctor d
ON v.DOCTOR_ID = d.DOCTOR_ID
LEFT JOIN date dt
ON v.APPOINTMENT_DATE = dt.FULL_DATE
LEFT JOIN department dep
ON UPPER(v.DEPARTMENT) = UPPER(dep.DEPARTMENT_NAME)