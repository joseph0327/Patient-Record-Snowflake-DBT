{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='MEDICATION_ID'
) }}

WITH source_data AS (
    SELECT
        MEDICATION_ID,
        PATIENT_ID,
        MEDICATION_NAME,
        DOSAGE,
        FREQUENCY,
        PRESCRIBED_BY,
        START_DATE,
        STATUS,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_MEDICATION') }}
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
        MEDICATION_ID,
        PATIENT_ID,
        {{ clean_string('MEDICATION_NAME') }} AS MEDICATION_NAME,
        {{ clean_string('DOSAGE') }} AS DOSAGE,
        {{ clean_string('FREQUENCY') }} AS FREQUENCY,
        PRESCRIBED_BY,
        {{ cast_date('START_DATE') }} AS START_DATE,
        {{ clean_string('STATUS') }} AS STATUS,
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
        PARTITION BY MEDICATION_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)
SELECT *
FROM deduplicated