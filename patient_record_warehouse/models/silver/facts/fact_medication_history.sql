{{ config(materialized='table',schema='SILVER') }}
WITH billing_history AS (
    SELECT *
    FROM {{ ref('billing_snapshot') }}
),
patient AS (
    SELECT PATIENT_SK,PATIENT_ID
    FROM {{ ref('dim_patient_current') }}
),
insurance AS (
    SELECT INSURANCE_SK,INSURANCE_NUMBER, PATIENT_ID
    FROM {{ ref('dim_insurance_current') }}
),
date_dim AS (
    SELECT DATE_SK,FULL_DATE
    FROM {{ ref('dim_date') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['b.BILLING_ID','b.DBT_VALID_FROM']) }} AS BILLING_HISTORY_SK,
    b.BILLING_ID,
    p.PATIENT_SK,
    p.PATIENT_ID,
    i.INSURANCE_SK,
    CASE
        WHEN i.INSURANCE_SK IS NULL THEN FALSE
        ELSE TRUE
    END AS HAS_INSURANCE,
    d.DATE_SK,
    b.CLAIM_NUMBER,
    b.SERVICE_TYPE,
    b.AMOUNT,
    b.BILLING_STATUS,
    b.BILLING_DATE,
    b.DBT_VALID_FROM AS EFFECTIVE_START_DATE,
    b.DBT_VALID_TO AS EFFECTIVE_END_DATE,
    CASE 
        WHEN b.DBT_VALID_TO IS NULL THEN TRUE 
        ELSE FALSE 
    END AS IS_CURRENT,
    b.CREATED_TIMESTAMP,
    b.SOURCE_SYSTEM,
    b.INGESTION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM billing_history b
LEFT JOIN patient p
ON b.PATIENT_ID = p.PATIENT_ID
LEFT JOIN insurance i
ON TRIM(b.PATIENT_ID) = TRIM(i.PATIENT_ID)
LEFT JOIN date_dim d
ON CAST(b.BILLING_DATE AS DATE) = d.FULL_DATE