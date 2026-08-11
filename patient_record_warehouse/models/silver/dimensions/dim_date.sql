WITH date_spine AS (
    SELECT
        DATEADD(
            DAY,
            SEQ4(),
            '2020-01-01'::DATE
        ) AS DATE_DAY
    FROM TABLE(
        GENERATOR(
            ROWCOUNT => 3650
        )
    )
)

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['DATE_DAY']
    ) }} AS DATE_SK,

    DATE_DAY AS FULL_DATE,

    YEAR(DATE_DAY) AS YEAR,

    QUARTER(DATE_DAY) AS QUARTER,

    MONTH(DATE_DAY) AS MONTH,

    MONTHNAME(DATE_DAY) AS MONTH_NAME,

    DAY(DATE_DAY) AS DAY,

    DAYNAME(DATE_DAY) AS DAY_NAME,

    WEEKOFYEAR(DATE_DAY) AS WEEK_OF_YEAR,

    CASE
        WHEN DAYOFWEEK(DATE_DAY) IN (0,6)
        THEN TRUE
        ELSE FALSE
    END AS IS_WEEKEND,

    CURRENT_TIMESTAMP() AS LOAD_TIMESTAMP

FROM date_spine