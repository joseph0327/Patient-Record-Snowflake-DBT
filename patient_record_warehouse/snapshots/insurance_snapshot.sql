{% snapshot insurance_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='INSURANCE_ID',
        strategy='timestamp',
        updated_at='INGESTION_TIMESTAMP'
    )
}}

SELECT *
FROM {{ ref('stg_insurance') }}

{% endsnapshot %}