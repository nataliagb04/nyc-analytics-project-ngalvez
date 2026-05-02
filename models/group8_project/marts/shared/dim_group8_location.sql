-- Location dimension shared by 311 service requests and motor vehicle collisions
-- Grain: one row per distinct (city, borough, zip_code) combination
-- Note: motor vehicle collisions do not carry a city field, so collision-side
-- rows have city = NULL and only contribute borough + zip_code combinations

WITH all_locations AS (

    SELECT DISTINCT
        city,
        borough,
        incident_zip AS zip_code
    FROM {{ ref('stg_group8_nyc_311_dot') }}

    UNION DISTINCT

    SELECT DISTINCT
        CAST(NULL AS STRING) AS city,
        borough,
        zip_code
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

),

location_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['city', 'borough', 'zip_code']) }} AS location_key,
        NULLIF(TRIM(city), '') AS city,
        NULLIF(TRIM(borough), '') AS borough,
        NULLIF(TRIM(zip_code), '') AS zip_code
    FROM all_locations

)

SELECT *
FROM location_dimension