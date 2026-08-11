WITH medications AS (

    SELECT
        MEDICATION_ID,
        PATIENT_ID,
        MEDICATION_NAME,
        DOSAGE,
        FREQUENCY,
        DOCTOR_ID AS PRESCRIBED_BY,
        START_DATE,
        STATUS

    FROM {{ ref('fact_medication') }}

    WHERE START_DATE IS NOT NULL

),

medication_activity AS (

    SELECT
        *,

        DATEDIFF(
            DAY,
            START_DATE,
            CURRENT_DATE()
        ) AS DAYS_SINCE_START

    FROM medications

),

medication_status AS (

    SELECT
        *,

        CASE
            WHEN UPPER(STATUS) = 'ACTIVE'
            THEN 1
            ELSE 0
        END AS IS_ACTIVE

    FROM medication_activity

),

patient_summary AS (

    SELECT
        PATIENT_ID,

        COUNT(DISTINCT MEDICATION_ID)
            AS TOTAL_MEDICATIONS,

        COUNT(DISTINCT CASE
            WHEN IS_ACTIVE = 1
            THEN MEDICATION_ID
        END) AS ACTIVE_MEDICATIONS,

        COUNT(DISTINCT CASE
            WHEN IS_ACTIVE = 0
            THEN MEDICATION_ID
        END) AS INACTIVE_MEDICATIONS

    FROM medication_status

    GROUP BY PATIENT_ID

)

SELECT
    PATIENT_ID,

    TOTAL_MEDICATIONS,

    ACTIVE_MEDICATIONS,

    INACTIVE_MEDICATIONS,

    ROUND(
        ACTIVE_MEDICATIONS
        / NULLIF(TOTAL_MEDICATIONS, 0)
        * 100,
        2
    ) AS ACTIVE_MEDICATION_RATE,

    CASE
        WHEN ACTIVE_MEDICATIONS = TOTAL_MEDICATIONS
            THEN 'GOOD'

        WHEN ACTIVE_MEDICATIONS > 0
             AND ACTIVE_MEDICATIONS < TOTAL_MEDICATIONS
            THEN 'AT_RISK'

        WHEN ACTIVE_MEDICATIONS = 0
            THEN 'NO_ACTIVE_MEDICATIONS'

        ELSE 'UNKNOWN'

    END AS ADHERENCE_CATEGORY,

    CURRENT_TIMESTAMP() AS CALCULATED_AT

FROM patient_summary