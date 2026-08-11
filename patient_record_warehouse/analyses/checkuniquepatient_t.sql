SELECT
    VISIT_ID, 
    COUNT(*) AS count
FROM {{ref('stg_visit')}}
GROUP BY VISIT_ID   
HAVING COUNT(*) > 1