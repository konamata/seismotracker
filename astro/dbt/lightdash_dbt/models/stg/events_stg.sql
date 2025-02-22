{{
  config(
    materialized='incremental',
    target_schema='stg',
    unique_key='event_id',
    incremental_strategy = 'merge'
  )
}}

SELECT
    e.event_id,
    ((e.otime AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/Istanbul') AS otime,
    ((e.updated AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/Istanbul') AS updated_date,
    e.lat,
    e.lon,
    e.agency,
    e.region,
    e.mag_type,
    e.etldate AS etl_date,
    c.name AS country_name,
    g.name AS nearest_place,
    g.alternatenames AS alternate_names,
    g.distance_meters / 1000 AS distance_km,
    e.depth::numeric AS depth,
    CASE
        WHEN e.depth <= 0 THEN 0
        WHEN e.depth > 0 AND e.depth <= 5 THEN 5
        WHEN e.depth > 5 AND e.depth <= 10 THEN 10
        WHEN e.depth > 10 AND e.depth <= 25 THEN 25
        WHEN e.depth > 25 AND e.depth <= 50 THEN 50
        WHEN e.depth > 50 AND e.depth <= 100 THEN 100
        WHEN e.depth > 100 AND e.depth <= 250 THEN 250
        WHEN e.depth > 250 AND e.depth <= 600 THEN 600
        WHEN e.depth > 600 THEN 601
        ELSE null
    END AS depth_category,
    e.mag::numeric AS mag,
    CASE 
        WHEN e.mag < 1.0 THEN '0 mag'
        WHEN e.mag >= 1.0 AND e.mag < 2.0 THEN '1 mag'
        WHEN e.mag >= 2.0 AND e.mag < 3.0 THEN '2 mag'
        WHEN e.mag >= 3.0 AND e.mag < 4.0 THEN '3 mag'
        WHEN e.mag >= 4.0 AND e.mag < 5.0 THEN '4 mag'
        WHEN e.mag >= 5.0 AND e.mag < 6.0 THEN '5 mag'
        WHEN e.mag >= 6.0 AND e.mag < 7.0 THEN '6 mag'
        WHEN e.mag >= 7.0 AND e.mag < 8.0 THEN '7 mag'
        WHEN e.mag >= 8.0 AND e.mag < 9.0 THEN '8 mag'
        ELSE 'Unknown'
    END AS mag_category
FROM {{ source('seismotracker', 'events') }} AS e
JOIN LATERAL (
    SELECT
        g2.name,
        g2.country,
        g2.alternatenames,
        ST_Distance(e.the_geom::geography, g2.the_geom::geography) AS distance_meters
    FROM {{ source('seismotracker', 'geoname') }} AS g2
    ORDER BY e.the_geom <-> g2.the_geom
    LIMIT 1
) AS g ON TRUE
LEFT JOIN {{ source('seismotracker', 'countryinfo') }} AS c
       ON c.iso_alpha2 = g.country

{% if is_incremental() %}
WHERE e.updated >= NOW() - INTERVAL '1 hour'
{% endif %}

ORDER BY e.otime DESC