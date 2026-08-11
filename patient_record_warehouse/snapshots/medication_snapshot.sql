{% snapshot medication_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='MEDICATION_ID',
        strategy='timestamp',
        updated_at='INGESTION_TIMESTAMP'
    )
}}

SELECT *
FROM {{ ref('stg_medication') }}

{% endsnapshot %}