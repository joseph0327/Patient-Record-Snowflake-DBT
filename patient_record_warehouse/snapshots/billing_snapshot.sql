{% snapshot billing_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='BILLING_ID',
        strategy='timestamp',
        updated_at='INGESTION_TIMESTAMP'
    )
}}

SELECT *
FROM {{ ref('stg_billing') }}

{% endsnapshot %}