-- Time-of-day dimension shared by 311 service requests and motor vehicle collisions
-- Grain: one row per distinct (hour, minute) observed across both fact streams

WITH all_times AS (

    SELECT DISTINCT
        EXTRACT(HOUR FROM created_date) AS hour,
        EXTRACT(MINUTE FROM created_date) AS minute
    FROM {{ ref('stg_group8_nyc_311_dot') }}

    UNION DISTINCT

    SELECT DISTINCT
        EXTRACT(HOUR FROM crash_time) AS hour,
        EXTRACT(MINUTE FROM crash_time) AS minute
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT NULL AS hour, NULL AS minute

),

time_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['hour', 'minute']) }} AS time_key,
        hour,
        minute,
        CASE
            WHEN hour BETWEEN 5 AND 11 THEN 'Morning'
            WHEN hour BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN hour BETWEEN 17 AND 20 THEN 'Evening'
            ELSE 'Night'
        END AS time_period
    FROM all_times

)

SELECT *
FROM time_dimension