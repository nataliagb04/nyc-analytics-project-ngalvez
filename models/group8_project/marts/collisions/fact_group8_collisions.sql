-- Fact table for motor vehicle collisions
-- Grain: one row per collision (collision_id)

WITH stg AS (

    SELECT *
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

),

dim_date AS (
    SELECT date_key, full_date
    FROM {{ ref('dim_group8_date') }}
),

dim_time AS (
    SELECT time_key, hour, minute
    FROM {{ ref('dim_group8_time') }}
),

dim_location AS (
    SELECT location_key, city, borough, zip_code
    FROM {{ ref('dim_group8_location') }}
),

dim_cf AS (
    SELECT contributing_factor_vehicle_key, contributing_factor_for_vehicle
    FROM {{ ref('dim_group8_contributing_factors') }}
),

dim_veh AS (
    SELECT vehicle_key, vehicle_type
    FROM {{ ref('dim_group8_vehicle') }}
),

joined AS (

    SELECT
        stg.collision_id,

        dd.date_key,
        dt.time_key,
        dl.location_key,

        cf1.contributing_factor_vehicle_key AS contributing_factor_key_v1,
        cf2.contributing_factor_vehicle_key AS contributing_factor_key_v2,
        cf3.contributing_factor_vehicle_key AS contributing_factor_key_v3,
        cf4.contributing_factor_vehicle_key AS contributing_factor_key_v4,
        cf5.contributing_factor_vehicle_key AS contributing_factor_key_v5,

        vt1.vehicle_key AS vehicle_key_v1,
        vt2.vehicle_key AS vehicle_key_v2,
        vt3.vehicle_key AS vehicle_key_v3,
        vt4.vehicle_key AS vehicle_key_v4,
        vt5.vehicle_key AS vehicle_key_v5,

        stg.number_of_persons_injured,
        stg.number_of_persons_killed,
        stg.number_of_pedestrians_injured,
        stg.number_of_pedestrians_killed,
        stg.number_of_cyclist_injured,
        stg.number_of_cyclist_killed,
        stg.number_of_motorist_injured,
        stg.number_of_motorist_killed,

        COALESCE(stg.number_of_persons_injured, 0) +
        COALESCE(stg.number_of_persons_killed, 0) AS total_victims,

        stg.on_street_name,
        stg.off_street_name,
        stg.cross_street_name,
        stg.latitude,
        stg.longitude,

        stg._stg_loaded_at

    FROM stg

    LEFT JOIN dim_date dd
        ON stg.crash_date = dd.full_date

    LEFT JOIN dim_time dt
        ON EXTRACT(HOUR FROM stg.crash_time) = dt.hour
       AND EXTRACT(MINUTE FROM stg.crash_time) = dt.minute

    LEFT JOIN dim_location dl
        ON dl.city IS NULL
       AND stg.borough = dl.borough
       AND stg.zip_code = dl.zip_code

    LEFT JOIN dim_cf cf1
        ON stg.contributing_factor_vehicle_1 = cf1.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf2
        ON stg.contributing_factor_vehicle_2 = cf2.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf3
        ON stg.contributing_factor_vehicle_3 = cf3.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf4
        ON stg.contributing_factor_vehicle_4 = cf4.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf5
        ON stg.contributing_factor_vehicle_5 = cf5.contributing_factor_for_vehicle

    LEFT JOIN dim_veh vt1
        ON stg.vehicle_type_1 = vt1.vehicle_type
    LEFT JOIN dim_veh vt2
        ON stg.vehicle_type_2 = vt2.vehicle_type
    LEFT JOIN dim_veh vt3
        ON stg.vehicle_type_3 = vt3.vehicle_type
    LEFT JOIN dim_veh vt4
        ON stg.vehicle_type_4 = vt4.vehicle_type
    LEFT JOIN dim_veh vt5
        ON stg.vehicle_type_5 = vt5.vehicle_type

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['collision_id']) }} AS collision_fact_key,
    *
FROM joined