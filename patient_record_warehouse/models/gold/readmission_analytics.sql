WITH visits AS (

    SELECT
        VISIT_ID,
        PATIENT_ID,
        APPOINTMENT_DATE,
        DOCTOR_ID,
        DEPARTMENT_NAME,
        VISIT_STATUS

    FROM {{ ref('fact_visit') }}

    WHERE APPOINTMENT_DATE IS NOT NULL

),

visit_history AS (

    SELECT
        VISIT_ID,
        PATIENT_ID,
        APPOINTMENT_DATE,
        DOCTOR_ID,
        DEPARTMENT_NAME,
        VISIT_STATUS,

        LAG(APPOINTMENT_DATE) OVER (
            PARTITION BY PATIENT_ID
            ORDER BY APPOINTMENT_DATE, VISIT_ID
        ) AS PREVIOUS_VISIT_DATE

    FROM visits

),

readmission AS (

    SELECT
        VISIT_ID,
        PATIENT_ID,
        APPOINTMENT_DATE,
        DOCTOR_ID,
        DEPARTMENT_NAME,
        VISIT_STATUS,
        PREVIOUS_VISIT_DATE,

        DATEDIFF(
            DAY,
            PREVIOUS_VISIT_DATE,
            APPOINTMENT_DATE
        ) AS DAYS_SINCE_PREVIOUS_VISIT,

        CASE
            WHEN PREVIOUS_VISIT_DATE IS NOT NULL
                 AND DATEDIFF(
                     DAY,
                     PREVIOUS_VISIT_DATE,
                     APPOINTMENT_DATE
                 ) <= 30
            THEN TRUE
            ELSE FALSE
        END AS IS_READMISSION

    FROM visit_history

)

SELECT *
FROM readmission