WITH source AS (

    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}

),

cleaned AS (

    SELECT
        -- Identifiers
        CAST(objectid AS STRING) AS application_id,
        CAST(globalid AS STRING) AS global_id,

        -- Dates / times
        CAST(submitted_on AS TIMESTAMP) AS submitted_on,
        CAST(last_modified AS TIMESTAMP) AS last_modified,
        CAST(time_of_submission AS STRING) AS time_of_submission,

        -- Restaurant info
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        UPPER(TRIM(CAST(status AS STRING))) AS application_status,

        -- Seating / business flags
        CAST(seating_interest_sidewalk_roadway_both AS STRING) AS seating_interest_type,
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,
        CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
        CAST(qualify_alcohol AS STRING) AS qualify_alcohol,

        -- Address / location
        CAST(building_number AS STRING) AS building_number,
        CAST(street AS STRING) AS street,
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,
        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(CAST(zip_code AS STRING)) = 5 THEN CAST(zip_code AS STRING)
            WHEN LENGTH(CAST(zip_code AS STRING)) = 10
                 AND REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}$')
                THEN CAST(zip_code AS STRING)
            ELSE NULL
        END AS zip_code,
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,
        CAST(business_address AS STRING) AS business_address,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(nta AS STRING) AS nta,
        CAST(bbl AS STRING) AS bbl,
        CAST(bin AS STRING) AS bin,

        -- Dimensions
        CAST(roadway_dimensions_area AS STRING) AS roadway_dimensions_area,
        CAST(roadway_dimensions_length AS STRING) AS roadway_dimensions_length,
        CAST(roadway_dimensions_width AS STRING) AS roadway_dimensions_width,
        CAST(sidewalk_dimensions_area AS STRING) AS sidewalk_dimensions_area,
        CAST(sidewalk_dimensions_length AS STRING) AS sidewalk_dimensions_length,
        CAST(sidewalk_dimensions_width AS STRING) AS sidewalk_dimensions_width,

        -- Other attributes
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
        CAST(landmark_district_or_building AS STRING) AS landmark_district_or_building,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE objectid IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY last_modified DESC
    ) = 1

)

SELECT * FROM cleaned