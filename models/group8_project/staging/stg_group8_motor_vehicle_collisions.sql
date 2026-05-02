-- Clean and standardize motor vehicle collisions data
-- One row per collision

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'raw_motor_vehicle_collisions') }}
),

cleaned AS (
    SELECT
        CAST(collision_id AS STRING) AS collision_id,

        SAFE_CAST(crash_date AS DATE) AS crash_date,
        SAFE_CAST(crash_time AS TIME) AS crash_time,

        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}$') THEN CAST(zip_code AS STRING)
            WHEN REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}$') THEN CAST(zip_code AS STRING)
            ELSE NULL
        END AS zip_code,

        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CAST(on_street_name AS STRING) AS on_street_name,
        CAST(off_street_name AS STRING) AS off_street_name,
        CAST(cross_street_name AS STRING) AS cross_street_name,
        SAFE_CAST(latitude AS NUMERIC) AS latitude,
        SAFE_CAST(longitude AS NUMERIC) AS longitude,

        NULLIF(TRIM(CAST(vehicle_type_code1 AS STRING)), '') AS vehicle_type_1,
        NULLIF(TRIM(CAST(vehicle_type_code2 AS STRING)), '') AS vehicle_type_2,
        NULLIF(TRIM(CAST(vehicle_type_code_3 AS STRING)), '') AS vehicle_type_3,
        NULLIF(TRIM(CAST(vehicle_type_code_4 AS STRING)), '') AS vehicle_type_4,
        NULLIF(TRIM(CAST(vehicle_type_code_5 AS STRING)), '') AS vehicle_type_5,

        NULLIF(TRIM(CAST(contributing_factor_vehicle_1 AS STRING)), '') AS contributing_factor_vehicle_1,
        NULLIF(TRIM(CAST(contributing_factor_vehicle_2 AS STRING)), '') AS contributing_factor_vehicle_2,
        NULLIF(TRIM(CAST(contributing_factor_vehicle_3 AS STRING)), '') AS contributing_factor_vehicle_3,
        NULLIF(TRIM(CAST(contributing_factor_vehicle_4 AS STRING)), '') AS contributing_factor_vehicle_4,
        NULLIF(TRIM(CAST(contributing_factor_vehicle_5 AS STRING)), '') AS contributing_factor_vehicle_5,

        SAFE_CAST(number_of_persons_injured AS INT64) AS number_of_persons_injured,
        SAFE_CAST(number_of_persons_killed AS INT64) AS number_of_persons_killed,
        SAFE_CAST(number_of_pedestrians_injured AS INT64) AS number_of_pedestrians_injured,
        SAFE_CAST(number_of_pedestrians_killed AS INT64) AS number_of_pedestrians_killed,
        SAFE_CAST(number_of_cyclist_injured AS INT64) AS number_of_cyclist_injured,
        SAFE_CAST(number_of_cyclist_killed AS INT64) AS number_of_cyclist_killed,
        SAFE_CAST(number_of_motorist_injured AS INT64) AS number_of_motorist_injured,
        SAFE_CAST(number_of_motorist_killed AS INT64) AS number_of_motorist_killed,

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE collision_id IS NOT NULL
      AND crash_date IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY collision_id
        ORDER BY SAFE_CAST(crash_date AS DATE) DESC
    ) = 1
)

SELECT *
FROM cleaned