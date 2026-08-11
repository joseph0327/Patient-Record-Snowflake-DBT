{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='DIAGNOSIS_ID'
) }}

WITH source_data AS (
    SELECT
        DIAGNOSIS_ID,
        PATIENT_ID,
        VISIT_ID,
        ICD10_CODE,
        DIAGNOSIS_NAME,
        SEVERITY,
        DIAGNOSIS_DATE,
        DOCTOR_ID,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_DIAGNOSIS') }}
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
        DIAGNOSIS_ID,
        PATIENT_ID,
        VISIT_ID,
        {{ clean_string('ICD10_CODE') }} AS ICD10_CODE,
        {{ clean_string('DIAGNOSIS_NAME') }} AS DIAGNOSIS_NAME,
        {{ clean_string('SEVERITY') }} AS SEVERITY,
        {{ cast_date('DIAGNOSIS_DATE') }} AS DIAGNOSIS_DATE,
        DOCTOR_ID,

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
        PARTITION BY DIAGNOSIS_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)

SELECT *
FROM deduplicated