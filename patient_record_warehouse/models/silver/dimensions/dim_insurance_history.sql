SELECT *
FROM {{ ref('dim_insurance') }}
WHERE IS_CURRENT = FALSE