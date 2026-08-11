{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='PATIENT_ID'
) }}

WITH source_data AS (
    SELECT
        PATIENT_ID,
        FIRST_NAME,
        LAST_NAME,
        DATE_OF_BIRTH,
        GENDER,
        SSN,
        EMAIL,
        PHONE,
        ADDRESS,
        INSURANCE_NUMBER,
        INSURANCE_COMPANY,
        MEDICAL_HISTORY,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_PATIENT') }}
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
        PATIENT_ID,
        {{ clean_string('FIRST_NAME') }} AS FIRST_NAME,
        {{ clean_string('LAST_NAME') }} AS LAST_NAME,
        {{ cast_date('DATE_OF_BIRTH') }} AS DATE_OF_BIRTH,
        {{ clean_string('GENDER') }} AS GENDER,
        {{ clean_string('SSN') }} AS SSN,
        {{ clean_string('EMAIL') }} AS EMAIL,
        {{ clean_string('PHONE') }} AS PHONE,
        {{ clean_string('ADDRESS') }} AS ADDRESS,
        {{ clean_string('INSURANCE_NUMBER') }} AS INSURANCE_NUMBER,
        {{ clean_string('INSURANCE_COMPANY') }} AS INSURANCE_COMPANY,
        MEDICAL_HISTORY,
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
        PARTITION BY PATIENT_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)
SELECT *
FROM deduplicated