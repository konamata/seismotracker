CREATE EXTENSION postgis;
CREATE DATABASE lightdash;

CREATE TABLE events (
    event_id  TEXT PRIMARY KEY,
    otime     TIMESTAMP,
    updated   TIMESTAMP,
    mag       DOUBLE PRECISION,
    mag_type  TEXT,
    lat       DOUBLE PRECISION,
    lon       DOUBLE PRECISION,
    depth     DOUBLE PRECISION,
    agency    TEXT,
    status    TEXT,
    estatus   TEXT,
    emode     TEXT,
    felt      BOOLEAN,
    region    TEXT,
    etldate   TIMESTAMP,
    the_geom  geometry(Point, 4326) generated always as (ST_SetSRID(ST_MakePoint(lon, lat), 4326)) stored
);

CREATE INDEX idx_events_region_mag ON events(region, mag);
CREATE INDEX idx_events_date ON events(otime);
CREATE INDEX brin_events_date ON events USING brin(otime);

CREATE VIEW vw_events_santorini_date_time_summary AS
SELECT
    date_trunc('day', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::date AS date,
    to_char(date_trunc('hour', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::time, 'HH24:MI') AS time,
    MAX(otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::time AS max_time,
    COUNT(*) AS count,
    ROUND(AVG(mag)::numeric, 2) AS mag_avg,
    ROUND(MIN(mag)::numeric, 2) AS mag_min,
    ROUND(MAX(mag)::numeric, 2) AS mag_max,
    ROUND(AVG(depth)::numeric, 2) AS depth_avg,
    ROUND(MIN(depth)::numeric, 2) AS depth_min,
    ROUND(MAX(depth)::numeric, 2) AS depth_max,
    SUM(CASE WHEN mag >= 0 AND mag < 1 THEN 1 ELSE 0 END) AS mag_0_count,
    SUM(CASE WHEN mag >= 1 AND mag < 2 THEN 1 ELSE 0 END) AS mag_1_count,
    SUM(CASE WHEN mag >= 2 AND mag < 3 THEN 1 ELSE 0 END) AS mag_2_count,
    SUM(CASE WHEN mag >= 3 AND mag < 4 THEN 1 ELSE 0 END) AS mag_3_count,
    SUM(CASE WHEN mag >= 4 AND mag < 5 THEN 1 ELSE 0 END) AS mag_4_count,
    SUM(CASE WHEN mag >= 5 AND mag < 6 THEN 1 ELSE 0 END) AS mag_5_count,
    SUM(CASE WHEN mag >= 6 AND mag < 7 THEN 1 ELSE 0 END) AS mag_6_count,
    SUM(CASE WHEN mag >= 7 AND mag < 8 THEN 1 ELSE 0 END) AS mag_7_count,
    SUM(CASE WHEN mag >= 8 AND mag < 9 THEN 1 ELSE 0 END) AS mag_8_count,
    SUM(CASE WHEN mag >= 9 AND mag < 10 THEN 1 ELSE 0 END) AS mag_9_count,
    SUM(CASE WHEN depth <= 5 THEN 1 ELSE 0 END) AS depth_5_count,
    SUM(CASE WHEN depth > 5 AND depth <= 10 THEN 1 ELSE 0 END) AS depth_5_10_count,
    SUM(CASE WHEN depth > 10 AND depth <= 25 THEN 1 ELSE 0 END) AS depth_10_25_count,
    SUM(CASE WHEN depth > 25 AND depth <= 50 THEN 1 ELSE 0 END) AS depth_25_50_count,
    SUM(CASE WHEN depth > 50 AND depth <= 100 THEN 1 ELSE 0 END) AS depth_50_100_count,
    SUM(CASE WHEN depth > 100 AND depth <= 250 THEN 1 ELSE 0 END) AS depth_100_250_count,
    SUM(CASE WHEN depth > 250 AND depth <= 600 THEN 1 ELSE 0 END) AS depth_250_600_count,
    SUM(CASE WHEN depth > 600 THEN 1 ELSE 0 END) AS depth_600_count
FROM events
WHERE
    lat >= 34.593601508431156 AND lat <= 37.14584148759743
    AND lon >= 23.1381670721369 AND lon <= 27.578825262999466
GROUP BY
    date_trunc('day', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::date,
    to_char(date_trunc('hour', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::time, 'HH24:MI')
ORDER BY date DESC, time DESC;

CREATE VIEW vw_events_santorini_date_summary AS
SELECT
    date_trunc('day', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::date AS date,
    MAX(otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::time AS max_time,
    COUNT(*) AS count,
    ROUND(AVG(mag)::numeric, 2) AS mag_avg,
    ROUND(MIN(mag)::numeric, 2) AS mag_min,
    ROUND(MAX(mag)::numeric, 2) AS mag_max,
    ROUND(AVG(depth)::numeric, 2) AS depth_avg,
    ROUND(MIN(depth)::numeric, 2) AS depth_min,
    ROUND(MAX(depth)::numeric, 2) AS depth_max,
    SUM(CASE WHEN mag >= 0 AND mag < 1 THEN 1 ELSE 0 END) AS mag_0_count,
    SUM(CASE WHEN mag >= 1 AND mag < 2 THEN 1 ELSE 0 END) AS mag_1_count,
    SUM(CASE WHEN mag >= 2 AND mag < 3 THEN 1 ELSE 0 END) AS mag_2_count,
    SUM(CASE WHEN mag >= 3 AND mag < 4 THEN 1 ELSE 0 END) AS mag_3_count,
    SUM(CASE WHEN mag >= 4 AND mag < 5 THEN 1 ELSE 0 END) AS mag_4_count,
    SUM(CASE WHEN mag >= 5 AND mag < 6 THEN 1 ELSE 0 END) AS mag_5_count,
    SUM(CASE WHEN mag >= 6 AND mag < 7 THEN 1 ELSE 0 END) AS mag_6_count,
    SUM(CASE WHEN mag >= 7 AND mag < 8 THEN 1 ELSE 0 END) AS mag_7_count,
    SUM(CASE WHEN mag >= 8 AND mag < 9 THEN 1 ELSE 0 END) AS mag_8_count,
    SUM(CASE WHEN mag >= 9 AND mag < 10 THEN 1 ELSE 0 END) AS mag_9_count,
    SUM(CASE WHEN depth <= 5 THEN 1 ELSE 0 END) AS depth_5_count,
    SUM(CASE WHEN depth > 5 AND depth <= 10 THEN 1 ELSE 0 END) AS depth_5_10_count,
    SUM(CASE WHEN depth > 10 AND depth <= 25 THEN 1 ELSE 0 END) AS depth_10_25_count,
    SUM(CASE WHEN depth > 25 AND depth <= 50 THEN 1 ELSE 0 END) AS depth_25_50_count,
    SUM(CASE WHEN depth > 50 AND depth <= 100 THEN 1 ELSE 0 END) AS depth_50_100_count,
    SUM(CASE WHEN depth > 100 AND depth <= 250 THEN 1 ELSE 0 END) AS depth_100_250_count,
    SUM(CASE WHEN depth > 250 AND depth <= 600 THEN 1 ELSE 0 END) AS depth_250_600_count,
    SUM(CASE WHEN depth > 600 THEN 1 ELSE 0 END) AS depth_600_count
FROM events
WHERE
    lat >= 34.593601508431156 AND lat <= 37.14584148759743
    AND lon >= 23.1381670721369 AND lon <= 27.578825262999466
GROUP BY
    date_trunc('day', otime AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Istanbul')::date
ORDER BY date DESC;

CREATE TABLE geoname (
    geonameid       INT,
    name            VARCHAR(200),
    asciiname       VARCHAR(200),
    alternatenames  TEXT,
    latitude        FLOAT,
    longitude       FLOAT,
    fclass          CHAR(1),
    fcode           VARCHAR(10),
    country         VARCHAR(2),
    cc2             TEXT,
    admin1          VARCHAR(20),
    admin2          VARCHAR(80),
    admin3          VARCHAR(20),
    admin4          VARCHAR(20),
    population      BIGINT,
    elevation       INT,
    gtopo30         INT,
    timezone        VARCHAR(40),
    moddate         DATE
);

CREATE TABLE alternatename (
    alternatenameId INT,
    geonameid       INT,
    isoLanguage     VARCHAR(7),
    alternateName   VARCHAR(200),
    isPreferredName BOOLEAN,
    isShortName     BOOLEAN,
    isColloquial    BOOLEAN,
    isHistoric      BOOLEAN
);

CREATE TABLE countryinfo (
    iso_alpha2      CHAR(2),
    iso_alpha3      CHAR(3),
    iso_numeric     INTEGER,
    fips_code       VARCHAR(3),
    name            VARCHAR(200),
    capital         VARCHAR(200),
    areainsqkm      DOUBLE PRECISION,
    population      INTEGER,
    continent       VARCHAR(2),
    tld             VARCHAR(10),
    currencycode    VARCHAR(3),
    currencyname    VARCHAR(20),
    phone           VARCHAR(20),
    postalcode      VARCHAR(100),
    postalcoderegex VARCHAR(200),
    languages       VARCHAR(200),
    geonameId       INT,
    neighbors       VARCHAR(50),
    equivfipscode   VARCHAR(3)
);

ALTER TABLE public.geoname SET (autovacuum_enabled = false);
ALTER TABLE public.alternatename SET (autovacuum_enabled = false);

COPY geoname (geonameid, name, asciiname, alternatenames, latitude, longitude, fclass, fcode, country, cc2, admin1, admin2, admin3, admin4, population, elevation, gtopo30, timezone, moddate)
    FROM '/geonames/allCountries.txt' NULL AS '';

COPY alternatename (alternatenameid, geonameid, isolanguage, alternatename, ispreferredname, isshortname, iscolloquial, ishistoric)
    FROM '/geonames/alternateNames.txt' NULL AS '';

COPY countryinfo (iso_alpha2, iso_alpha3, iso_numeric, fips_code, name, capital, areainsqkm, population, continent, tld, currencycode, currencyname, phone, postalcode, postalcoderegex, languages, geonameid, neighbors, equivfipscode)
    FROM '/geonames/countryInfo.txt' NULL AS '';

ALTER TABLE ONLY alternatename
    ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);

ALTER TABLE ONLY geoname
    ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);

ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);

ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);

ALTER TABLE ONLY alternatename
    ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);

SELECT AddGeometryColumn ('public', 'geoname', 'the_geom', 4326, 'POINT', 2);

UPDATE geoname 
    SET the_geom = ST_PointFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);

CREATE INDEX idx_geoname_the_geom ON public.geoname USING gist(the_geom);

ALTER TABLE public.geoname SET (autovacuum_enabled = true);
ALTER TABLE public.alternatename SET (autovacuum_enabled = true);

CREATE VIEW vw_events_santorini_list AS
SELECT
    e.event_id,
    ((e.otime AT TIME ZONE 'UTC') AT TIME ZONE 'Europe/Istanbul') AS otime,
    e.lat,
    e.lon,
    c.name AS country_name,
    g.name AS nearest_place,
    g.distance_meters,
    ROUND(e.depth::numeric, 0) AS depth,
    ROUND(e.mag::numeric, 1) AS mag
FROM events AS e
JOIN LATERAL (
    SELECT
        g2.name,
        g2.country,
        ST_Distance(e.the_geom::geography, g2.the_geom::geography) AS distance_meters
    FROM geoname AS g2
    ORDER BY e.the_geom <-> g2.the_geom
    LIMIT 1
) AS g ON TRUE
LEFT JOIN countryinfo AS c
       ON c.iso_alpha2 = g.country
WHERE e.lat BETWEEN 34.593601508431156 AND 37.14584148759743
  AND e.lon BETWEEN 23.1381670721369 AND 27.578825262999466
ORDER BY e.otime DESC;