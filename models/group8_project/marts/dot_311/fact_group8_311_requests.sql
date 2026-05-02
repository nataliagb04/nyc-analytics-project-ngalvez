-- Fact table for 311 DOT/NYPD service requests
-- Grain: one row per service request (unique_key)

WITH stg AS (

    SELECT *
    FROM {{ ref('stg_group8_nyc_311_dot') }}

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

dim_agency AS (
    SELECT agency_key, agency_code, agency_name
    FROM {{ ref('dim_group8_agency') }}
),

dim_complaint AS (
    SELECT complaint_key, complaint_type, location_type
    FROM {{ ref('dim_group8_complaint') }}
),

dim_status AS (
    SELECT status_key, status_text
    FROM {{ ref('dim_group8_status') }}
),

joined AS (

    SELECT
        stg.unique_key,

        dd_created.date_key AS created_date_key,
        dd_closed.date_key AS closed_date_key,

        dt.time_key AS created_time_key,

        dl.location_key,

        da.agency_key,
        dc.complaint_key,
        ds.status_key,

        stg.incident_address,
        stg.street_name,
        stg.cross_street_1,
        stg.cross_street_2,
        stg.address_type,
        stg.community_board,
        stg.police_precinct,
        stg.opendata_channel_type,
        stg.problem_detail,
        stg.additional_details,
        stg.resolution_description,
        stg.latitude,
        stg.longitude,

        stg.created_date,
        stg.closed_date,
        stg.due_date,
        stg.resolution_action_date,

        CASE
            WHEN stg.closed_date IS NOT NULL
            THEN TIMESTAMP_DIFF(stg.closed_date, stg.created_date, HOUR)
            ELSE NULL
        END AS resolution_hours,

        CASE
            WHEN stg.closed_date IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS is_resolved,

        CASE
            WHEN stg.due_date IS NOT NULL AND stg.closed_date > stg.due_date THEN TRUE
            ELSE FALSE
        END AS is_overdue,

        stg._stg_loaded_at

    FROM stg

    LEFT JOIN dim_date dd_created
        ON CAST(stg.created_date AS DATE) = dd_created.full_date

    LEFT JOIN dim_date dd_closed
        ON CAST(stg.closed_date AS DATE) = dd_closed.full_date

    LEFT JOIN dim_time dt
        ON EXTRACT(HOUR FROM stg.created_date) = dt.hour
       AND EXTRACT(MINUTE FROM stg.created_date) = dt.minute

    LEFT JOIN dim_location dl
        ON stg.city = dl.city
       AND stg.borough = dl.borough
       AND stg.incident_zip = dl.zip_code

    LEFT JOIN dim_agency da
        ON stg.agency = da.agency_code
       AND stg.agency_name = da.agency_name

    LEFT JOIN dim_complaint dc
        ON stg.complaint_type = dc.complaint_type
       AND stg.location_type = dc.location_type

    LEFT JOIN dim_status ds
        ON stg.status = ds.status_text

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['unique_key']) }} AS request_fact_key,
    *
FROM joined