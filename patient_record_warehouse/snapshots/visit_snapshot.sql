{% snapshot visit_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='VISIT_ID',
        strategy='timestamp',
        updated_at='INGESTION_TIMESTAMP'
    )
}}

SELECT *
FROM {{ ref('stg_visit') }}

{% endsnapshot %}