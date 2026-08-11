{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='BILLING_ID'
) }}

WITH source_data AS (
    SELECT
        BILLING_ID,
        PATIENT_ID,
        INSURANCE_NUMBER,
        CLAIM_NUMBER,
        SERVICE_TYPE,
        AMOUNT,
        BILLING_STATUS,
        BILLING_DATE,
        CREATED_TIMESTAMP,
        SEQUENCE,
        SOURCE_SYSTEM,
        INGESTION_TIMESTAMP
    FROM {{ source('PATIENT_RECORD_DB', 'BRONZE_BILLING') }}
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
        BILLING_ID,
        PATIENT_ID,
        {{ null_if_blank('INSURANCE_NUMBER') }} AS INSURANCE_NUMBER,
        {{ null_if_blank('CLAIM_NUMBER') }} AS CLAIM_NUMBER,
        {{ clean_string('SERVICE_TYPE') }} AS SERVICE_TYPE,
        {{ cast_number('AMOUNT', 'NUMBER(18,2)') }} AS AMOUNT,
        {{ clean_string('BILLING_STATUS') }} AS BILLING_STATUS,
        {{ cast_date('BILLING_DATE') }} AS BILLING_DATE,

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
        PARTITION BY BILLING_ID
        ORDER BY
            INGESTION_TIMESTAMP DESC,
            SEQUENCE DESC
    ) = 1
)

SELECT *
FROM deduplicated