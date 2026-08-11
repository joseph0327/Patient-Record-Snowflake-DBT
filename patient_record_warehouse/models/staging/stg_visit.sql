{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='VISIT_ID'
) }}

WITH source_data AS (
    SELECT
        VISIT_ID,
        PATIENT_ID,
        APPOINTMENT_DATE,
        DOCTOR_ID,
        DEPARTMENT,
        DIAGNOSIS,
        VISIT_REASON,
        VISIT_STATUS,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_VISIT') }}
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
        VISIT_ID,
        PATIENT_ID,
        {{ cast_date('APPOINTMENT_DATE') }} AS APPOINTMENT_DATE,
        DOCTOR_ID,
        {{ clean_string('DEPARTMENT') }} AS DEPARTMENT,
        {{ clean_string('DIAGNOSIS') }} AS DIAGNOSIS,
        {{ clean_string('VISIT_REASON') }} AS VISIT_REASON,
        {{ clean_string('VISIT_STATUS') }} AS VISIT_STATUS,
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
        PARTITION BY VISIT_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)
SELECT *
FROM deduplicated