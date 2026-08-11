
With patient_data AS (
 SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY PATIENT_ID
            ORDER BY INGESTION_TIMESTAMP DESC, SEQUENCE DESC
        ) AS RN

    FROM {{ source('PATIENT_RECORD_DB','BRONZE_PATIENT') }}
)
SELECT * from patient_data
WHERE RN = 1