-- Agency dimension for 311 service requests
-- Grain: one row per distinct (agency_code, agency_name) pair
-- Renames staging.agency -> agency_code to match the warehouse model

WITH agencies AS (

    SELECT DISTINCT
        agency AS agency_code,
        agency_name
    FROM {{ ref('stg_group8_nyc_311_dot') }}

    UNION DISTINCT

    SELECT
        CAST(NULL AS STRING) AS agency_code,
        CAST(NULL AS STRING) AS agency_name

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['agency_code', 'agency_name']) }} AS agency_key,
    agency_code,
    agency_name
FROM agencies