{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='INSURANCE_ID'
) }}

WITH source_data AS (
    SELECT
        INSURANCE_ID,
        PATIENT_ID,
        INSURANCE_NUMBER,
        INSURANCE_COMPANY,
        PLAN_NAME,
        COVERAGE_AMOUNT,
        EFFECTIVE_DATE,
        EXPIRATION_DATE,
        STATUS,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_INSURANCE') }}
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
        INSURANCE_ID,
        PATIENT_ID,
        {{ clean_string('INSURANCE_NUMBER') }} AS INSURANCE_NUMBER,
        {{ clean_string('INSURANCE_COMPANY') }} AS INSURANCE_COMPANY,
        {{ clean_string('PLAN_NAME') }} AS PLAN_NAME,
        {{ cast_number('COVERAGE_AMOUNT') }} AS COVERAGE_AMOUNT,
        {{ cast_date('EFFECTIVE_DATE') }} AS EFFECTIVE_DATE,
        {{ cast_date('EXPIRATION_DATE') }} AS EXPIRATION_DATE,
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
        PARTITION BY INSURANCE_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)

SELECT *
FROM deduplicated