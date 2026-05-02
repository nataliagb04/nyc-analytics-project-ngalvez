-- Contributing factor dimension for motor vehicle collisions
-- Grain: one row per distinct contributing-factor value

WITH factors AS (

    SELECT contributing_factor_vehicle_1 AS contributing_factor_for_vehicle
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_2
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_3
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_4
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_5
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

),

distinct_factors AS (

    SELECT DISTINCT
        NULLIF(TRIM(contributing_factor_for_vehicle), '') AS contributing_factor_for_vehicle
    FROM factors

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['contributing_factor_for_vehicle']) }} AS contributing_factor_vehicle_key,
    contributing_factor_for_vehicle
FROM distinct_factors