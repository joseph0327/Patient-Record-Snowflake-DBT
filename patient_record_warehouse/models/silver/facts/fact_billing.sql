WITH billing AS (
    SELECT *
    FROM {{ ref('stg_billing') }}
),
patient AS (
    SELECT
        PATIENT_SK,
        PATIENT_ID
    FROM {{ ref('dim_patient_current') }}
),
insurance AS (
    SELECT
        INSURANCE_SK,
        INSURANCE_ID,
        INSURANCE_NUMBER,
        PATIENT_ID
    FROM {{ ref('dim_insurance_current') }}
),
date_dim AS (
    SELECT
        DATE_SK,
        FULL_DATE
    FROM {{ ref('dim_date') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['b.BILLING_ID']) }} AS BILLING_SK,
    b.BILLING_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    i.INSURANCE_SK,
    d.DATE_SK,
    b.CLAIM_NUMBER,
    b.SERVICE_TYPE,
    b.AMOUNT,
    b.BILLING_STATUS,
    b.BILLING_DATE,
    b.CREATED_TIMESTAMP,
    b.SOURCE_SYSTEM,
    b.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM billing b
LEFT JOIN patient p
ON b.PATIENT_ID = p.PATIENT_ID
LEFT JOIN insurance i
ON b.PATIENT_ID = i.PATIENT_ID
LEFT JOIN date_dim d
ON CAST(b.BILLING_DATE AS DATE) = d.FULL_DATE