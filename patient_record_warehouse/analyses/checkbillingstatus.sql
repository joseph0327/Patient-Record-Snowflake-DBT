SELECT
    department_name as department,
    COUNT(DISTINCT visit_id) AS number_of_visits
FROM {{ ref('fact_visit') }}
GROUP BY department
ORDER BY number_of_visits DESC;