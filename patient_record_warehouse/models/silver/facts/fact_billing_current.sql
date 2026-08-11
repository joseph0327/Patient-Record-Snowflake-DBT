
WITH billing_current AS (
    SELECT *
    FROM {{ ref('fact_billing_history') }}
    WHERE IS_CURRENT = TRUE
),
insurance_current as (
    SELECT
        INSURANCE_SK,
        INSURANCE_NUMBER,
        PATIENT_ID
    FROM {{ ref('dim_insurance_current') }}
)
SELECT
    b.BILLING_HISTORY_SK AS BILLING_SK,
    b.BILLING_ID,
    b.PATIENT_SK,
    b.patient_id,
    i.INSURANCE_SK,
    b.DATE_SK,
    CASE
        WHEN i.INSURANCE_SK IS NULL THEN FALSE
        ELSE TRUE
    END AS HAS_INSURANCE,
    b.CLAIM_NUMBER,
    b.SERVICE_TYPE,
    b.AMOUNT,
    b.BILLING_STATUS,
    b.BILLING_DATE,
    b.CREATED_TIMESTAMP,
    b.SOURCE_SYSTEM,
    b.INGESTION_TIMESTAMP,
    b.EFFECTIVE_START_DATE,
    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP
FROM billing_current b
LEFT JOIN insurance_current i
ON b.PATIENT_ID = i.PATIENT_ID