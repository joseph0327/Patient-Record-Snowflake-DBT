WITH labs AS (

    SELECT
        LAB_ID,
        PATIENT_ID,
        LAB_CATEGORY,
        TEST_NAME,
        RESULT_VALUE,
        RESULT_UNIT,
        REFERENCE_RANGE,
        RESULT_STATUS,
        LAB_LOCATION,
        TEST_DATE,
        DOCTOR_ID as ORDERING_DOCTOR_ID

    FROM {{ ref('fact_lab_result') }}

    WHERE TEST_DATE IS NOT NULL

),

numeric_labs AS (

    SELECT
        *,

        TRY_TO_DECIMAL(
            RESULT_VALUE
        ) AS NUMERIC_RESULT

    FROM labs

),

lab_history AS (

    SELECT
        *,

        LAG(NUMERIC_RESULT) OVER (
            PARTITION BY PATIENT_ID, TEST_NAME
            ORDER BY TEST_DATE, LAB_ID
        ) AS PREVIOUS_RESULT

    FROM numeric_labs

),

lab_trends AS (

    SELECT
        *,

        NUMERIC_RESULT - PREVIOUS_RESULT
            AS RESULT_CHANGE,

        CASE
            WHEN PREVIOUS_RESULT IS NULL
                THEN 'FIRST_RESULT'

            WHEN NUMERIC_RESULT > PREVIOUS_RESULT
                THEN 'INCREASED'

            WHEN NUMERIC_RESULT < PREVIOUS_RESULT
                THEN 'DECREASED'

            ELSE 'NO_CHANGE'

        END AS TREND,

        CASE
            WHEN PREVIOUS_RESULT IS NOT NULL
                 AND PREVIOUS_RESULT <> 0

            THEN ROUND(
                (
                    NUMERIC_RESULT - PREVIOUS_RESULT
                )
                / ABS(PREVIOUS_RESULT)
                * 100,
                2
            )

            ELSE NULL

        END AS PERCENT_CHANGE

    FROM lab_history

)

SELECT
    LAB_ID,
    PATIENT_ID,
    LAB_CATEGORY,
    TEST_NAME,
    RESULT_VALUE,
    NUMERIC_RESULT,
    RESULT_UNIT,
    REFERENCE_RANGE,
    RESULT_STATUS,
    LAB_LOCATION,
    TEST_DATE,
    ORDERING_DOCTOR_ID,

    PREVIOUS_RESULT,
    RESULT_CHANGE,
    PERCENT_CHANGE,
    TREND,

    CURRENT_TIMESTAMP() AS CALCULATED_AT

FROM lab_trends