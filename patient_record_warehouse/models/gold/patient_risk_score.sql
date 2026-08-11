WITH patient_visits AS (

    SELECT
        PATIENT_ID,

        COUNT(DISTINCT VISIT_ID) AS TOTAL_VISITS,

        COUNT(DISTINCT CASE
            WHEN APPOINTMENT_DATE >= DATEADD(
                DAY,
                -30,
                CURRENT_DATE()
            )
            THEN VISIT_ID
        END) AS VISITS_LAST_30_DAYS

    FROM {{ ref('fact_visit') }}

    WHERE VISIT_STATUS = 'COMPLETED'

    GROUP BY PATIENT_ID

),

readmissions AS (

    SELECT
        PATIENT_ID,

        COUNT(DISTINCT CASE
            WHEN IS_READMISSION = TRUE
            THEN VISIT_ID
        END) AS READMISSIONS_30_DAY

    FROM {{ ref('readmission_analytics') }}

    GROUP BY PATIENT_ID

),

medications AS (

    SELECT
        PATIENT_ID,

        COUNT(DISTINCT CASE
            WHEN STATUS = 'ACTIVE'
            THEN MEDICATION_ID
        END) AS ACTIVE_MEDICATIONS

    FROM {{ ref('fact_medication') }}

    GROUP BY PATIENT_ID

),

diagnoses AS (

    SELECT
        PATIENT_ID,

        MAX(
            CASE
                WHEN UPPER(SEVERITY) = 'SEVERE'
                THEN 1
                ELSE 0
            END
        ) AS HAS_SEVERE_DIAGNOSIS

    FROM {{ ref('fact_diagnosis') }}

    GROUP BY PATIENT_ID

),

labs AS (

    SELECT
        PATIENT_ID,

        COUNT(DISTINCT CASE
            WHEN UPPER(RESULT_STATUS) = 'ABNORMAL'
            THEN LAB_ID
        END) AS ABNORMAL_LABS

    FROM {{ ref('fact_lab_result') }}

    GROUP BY PATIENT_ID

),

patient_features AS (

    SELECT
        p.PATIENT_ID,

        COALESCE(v.TOTAL_VISITS, 0)
            AS TOTAL_VISITS,

        COALESCE(v.VISITS_LAST_30_DAYS, 0)
            AS VISITS_LAST_30_DAYS,

        COALESCE(r.READMISSIONS_30_DAY, 0)
            AS READMISSIONS_30_DAY,

        COALESCE(m.ACTIVE_MEDICATIONS, 0)
            AS ACTIVE_MEDICATIONS,

        COALESCE(d.HAS_SEVERE_DIAGNOSIS, 0)
            AS HAS_SEVERE_DIAGNOSIS,

        COALESCE(l.ABNORMAL_LABS, 0)
            AS ABNORMAL_LABS

    FROM {{ ref('dim_patient') }} p

    LEFT JOIN patient_visits v
        ON p.PATIENT_ID = v.PATIENT_ID

    LEFT JOIN readmissions r
        ON p.PATIENT_ID = r.PATIENT_ID

    LEFT JOIN medications m
        ON p.PATIENT_ID = m.PATIENT_ID

    LEFT JOIN diagnoses d
        ON p.PATIENT_ID = d.PATIENT_ID

    LEFT JOIN labs l
        ON p.PATIENT_ID = l.PATIENT_ID

),

scored AS (

    SELECT
        *,

        (
            CASE
                WHEN VISITS_LAST_30_DAYS >= 3 THEN 20
                ELSE 0
            END

            +

            CASE
                WHEN READMISSIONS_30_DAY >= 2 THEN 25
                ELSE 0
            END

            +

            CASE
                WHEN TOTAL_VISITS >= 5 THEN 10
                ELSE 0
            END

            +

            CASE
                WHEN ACTIVE_MEDICATIONS >= 3 THEN 10
                ELSE 0
            END

            +

            CASE
                WHEN HAS_SEVERE_DIAGNOSIS = 1 THEN 20
                ELSE 0
            END

            +

            CASE
                WHEN ABNORMAL_LABS > 0 THEN 15
                ELSE 0
            END

        ) AS RISK_SCORE

    FROM patient_features

)

SELECT
    PATIENT_ID,
    RISK_SCORE,

    CASE
        WHEN RISK_SCORE >= 60 THEN 'HIGH'
        WHEN RISK_SCORE >= 30 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS RISK_CATEGORY,

    TOTAL_VISITS,
    VISITS_LAST_30_DAYS,
    READMISSIONS_30_DAY,
    ACTIVE_MEDICATIONS,
    HAS_SEVERE_DIAGNOSIS,
    ABNORMAL_LABS,

    CURRENT_TIMESTAMP() AS RISK_CALCULATED_AT

FROM scored