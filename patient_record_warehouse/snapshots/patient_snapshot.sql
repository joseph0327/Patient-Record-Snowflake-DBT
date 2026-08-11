{% snapshot patient_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='PATIENT_ID',
        strategy='timestamp',
        updated_at='INGESTION_TIMESTAMP'
    )
}}

SELECT *
FROM {{ ref('stg_patient') }}

{% endsnapshot %}