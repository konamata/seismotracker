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
    (e.otime AT TIME ZONE 'UTC') AS otime,
    (e.updated AT TIME ZONE 'UTC') AS updated_date,
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
    e.mag::numeric AS mag
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