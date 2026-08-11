{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='LAB_ID'
) }}

WITH source_data AS (
    SELECT
        LAB_ID,
        PATIENT_ID,
        LAB_CATEGORY,
        TEST_NAME,
        RESULT_VALUE,
        UNIT,
        REFERENCE_RANGE,
        RESULT_STATUS,
        LAB_LOCATION,
        TEST_DATE,
        ORDERING_DOCTOR_ID,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_LAB_RESULT') }}
    {% if is_incremental() %}
    WHERE (
        INGESTION_TIMESTAMP > (
            SELECT COALESCE(MAX(INGESTION_TIMESTAMP), '1900-01-01'::TIMESTAMP)
            FROM {{ this }}
        )
        OR (
            INGESTION_TIMESTAMP = (
                SELECT COALESCE(MAX(INGESTION_TIMESTAMP), '1900-01-01'::TIMESTAMP)
                FROM {{ this }}
            )
            AND SEQUENCE > (
                SELECT COALESCE(MAX(SEQUENCE), 0)
                FROM {{ this }}
                WHERE INGESTION_TIMESTAMP = (
                    SELECT COALESCE(MAX(INGESTION_TIMESTAMP), '1900-01-01'::TIMESTAMP)
                    FROM {{ this }}
                )
            )
        )
    )
    {% endif %}
),
transformed AS (
    SELECT
        -- Business Columns
        LAB_ID,
        PATIENT_ID,
        {{ clean_string('LAB_CATEGORY') }} AS LAB_CATEGORY,
        {{ clean_string('TEST_NAME') }} AS TEST_NAME,
        {{ clean_string('RESULT_VALUE') }} AS RESULT_VALUE,
        {{ clean_string('UNIT') }} AS RESULT_UNIT,
        {{ clean_string('REFERENCE_RANGE') }} AS REFERENCE_RANGE,
        {{ clean_string('RESULT_STATUS') }} AS RESULT_STATUS,
        {{ clean_string('LAB_LOCATION') }} AS LAB_LOCATION,
        {{ cast_date('TEST_DATE') }} AS TEST_DATE,
        ORDERING_DOCTOR_ID,
        -- Metadata
        {{ cast_timestamp('CREATED_TIMESTAMP') }} AS CREATED_TIMESTAMP,
        {{ cast_number('SEQUENCE') }} AS SEQUENCE,
        {{ clean_string('SOURCE_SYSTEM') }} AS SOURCE_SYSTEM,
        {{ cast_timestamp('INGESTION_TIMESTAMP') }} AS INGESTION_TIMESTAMP,
        -- Audit Columns
        {{ add_audit_columns() }}
    FROM source_data
),
deduplicated AS (
    SELECT *
    FROM transformed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LAB_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)
SELECT *
FROM deduplicated