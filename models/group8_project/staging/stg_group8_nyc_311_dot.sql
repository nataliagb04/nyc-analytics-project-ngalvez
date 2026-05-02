-- Clean and standardize 311 DOT/NYPD service request data
-- One row per service request

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'raw_311_requests') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            unique_key,
            created_date,
            closed_date,
            due_date,
            resolution_action_updated_date,
            agency,
            agency_name,
            complaint_type,
            descriptor,
            descriptor_2,
            location_type,
            status,
            incident_zip,
            borough,
            incident_address,
            street_name,
            cross_street_1,
            cross_street_2,
            address_type,
            city,
            resolution_description,
            community_board,
            police_precinct,
            latitude,
            longitude,
            open_data_channel_type,
            vehicle_type
        ),

        CAST(unique_key AS STRING) AS unique_key,

        CAST(created_date AS TIMESTAMP) AS created_date,
        CAST(closed_date AS TIMESTAMP) AS closed_date,
        SAFE_CAST(due_date AS TIMESTAMP) AS due_date,
        CAST(resolution_action_updated_date AS TIMESTAMP) AS resolution_action_date,

        CAST(agency AS STRING) AS agency,
        CAST(agency_name AS STRING) AS agency_name,
        CAST(complaint_type AS STRING) AS complaint_type,
        CAST(descriptor AS STRING) AS problem_detail,
        CAST(descriptor_2 AS STRING) AS additional_details,
        CAST(location_type AS STRING) AS location_type,
        UPPER(TRIM(CAST(status AS STRING))) AS status,

        CASE
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN REGEXP_CONTAINS(CAST(incident_zip AS STRING), r'^\d{5}$') THEN CAST(incident_zip AS STRING)
            WHEN REGEXP_CONTAINS(CAST(incident_zip AS STRING), r'^\d{5}-\d{4}$') THEN CAST(incident_zip AS STRING)
            ELSE NULL
        END AS incident_zip,

        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CAST(incident_address AS STRING) AS incident_address,
        CAST(street_name AS STRING) AS street_name,
        CAST(cross_street_1 AS STRING) AS cross_street_1,
        CAST(cross_street_2 AS STRING) AS cross_street_2,
        CAST(address_type AS STRING) AS address_type,
        CAST(city AS STRING) AS city,

        CAST(resolution_description AS STRING) AS resolution_description,
        CAST(community_board AS STRING) AS community_board,
        CAST(police_precinct AS STRING) AS police_precinct,

        CAST(open_data_channel_type AS STRING) AS opendata_channel_type,
        NULLIF(TRIM(CAST(vehicle_type AS STRING)), '') AS vehicle_type,
        SAFE_CAST(latitude AS NUMERIC) AS latitude,
        SAFE_CAST(longitude AS NUMERIC) AS longitude,

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE unique_key IS NOT NULL
      AND created_date IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY unique_key
        ORDER BY created_date DESC
    ) = 1
)

SELECT *
FROM cleaned