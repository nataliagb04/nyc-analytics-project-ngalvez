-- Vehicle dimension for motor vehicle collisions
-- Grain: one row per distinct vehicle type
-- Source: collisions staging has five vehicle_type columns (one per vehicle in the crash)

WITH vehicle_types AS (

    SELECT vehicle_type_1 AS vehicle_type
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT vehicle_type_2
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT vehicle_type_3
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT vehicle_type_4
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT vehicle_type_5
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

),

distinct_types AS (

    SELECT DISTINCT
        NULLIF(TRIM(vehicle_type), '') AS vehicle_type
    FROM vehicle_types

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['vehicle_type']) }} AS vehicle_key,
    CASE
        WHEN vehicle_type IS NULL THEN NULL
        WHEN UPPER(TRIM(vehicle_type)) IN ('', 'UNKNOWN', 'UNKNOW', 'UNK') THEN 'Unknown'
        ELSE INITCAP(TRIM(vehicle_type))
    END AS vehicle_type
FROM distinct_types