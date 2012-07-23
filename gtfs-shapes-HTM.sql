-- GTFS: feed_info.txt
copy (select 'openOV' as feed_publisher_name, 'http://openov.nl/' as feed_publisher_url, 'nl' as feed_lang, replace(cast(min(validdate) AS text), '-', '') as feed_start_date, replace(cast(max(validdate) AS text), '-', '') as feed_end_date, now() as feed_version from operday) TO '/tmp/feed_info.txt' WITH CSV HEADER;
-- Ik denk agency.txt gewoon statisch houden.
-- GTFS: shapes.txt
-- -- Missing:
--  KV1 support for LinkValidFrom
--  GTFS support for shape_dist_traveled (summation of distancesincestartoflink)
--  ** disabled transporttype **
COPY (
SELECT DISTINCT shape_id,
      CAST(ST_Y(the_geom) AS NUMERIC(8,5)) AS shape_pt_lat,
      CAST(ST_X(the_geom) AS NUMERIC(7,5)) AS shape_pt_lon,
      shape_pt_sequence
FROM
 (SELECT jopatili.dataownercode||'|'||jopatili.lineplanningnumber||'|'||jopatili.journeypatterncode AS shape_id,
  ST_Transform(st_setsrid(st_makepoint(locationx_ew, locationy_ns), 28992), 4326) AS the_geom,
  rank() over (PARTITION BY jopatili.dataownercode, jopatili.lineplanningnumber, jopatili.journeypatterncode ORDER BY jopatili.dataownercode, jopatili.lineplanningnumber, jopatili.journeypatterncode, jopatili.timinglinkorder, pool.distancesincestartoflink) AS shape_pt_sequence
  FROM jopatili,
       pool,
       point,
       line
  WHERE jopatili.dataownercode = pool.dataownercode
    AND jopatili.userstopcodebegin = pool.userstopcodebegin
    AND jopatili.userstopcodeend = pool.userstopcodeend
    AND jopatili.dataownercode = line.dataownercode
    AND jopatili.lineplanningnumber = line.lineplanningnumber
    AND pool.pointdataownercode = point.dataownercode
    AND pool.pointcode = point.pointcode
--     AND pool.transporttype = line.transporttype
    AND current_date > pool.LinkValidFrom
  ORDER BY jopatili.dataownercode,
           jopatili.lineplanningnumber,
           jopatili.journeypatterncode,
           jopatili.timinglinkorder,
           pool.distancesincestartoflink) AS KV1
) TO '/tmp/shapes.txt' WITH CSV HEADER;
-- GTFS: stops.txt
COPY (
SELECT stop_id || '|parent' as stop_id, a.name AS stop_name,
       CAST(Y(the_geom) AS NUMERIC(8,5)) AS stop_lat,
       CAST(X(the_geom) AS NUMERIC(7,5)) AS stop_lon,
       1      AS location_type,
       NULL   AS parent_station
FROM   (SELECT parent_station AS stop_id,
               ST_Transform(setsrid(makepoint(AVG(locationx_ew), AVG(locationy_ns)), 28992), 4326) AS the_geom
        FROM   (SELECT u.dataownercode || '|' || u.userstopareacode AS parent_station,
                       locationx_ew,
                       locationy_ns
                FROM   usrstop AS u,
                       point AS p
                WHERE  u.dataownercode = p.dataownercode
                       AND u.userstopcode = p.pointcode
                       AND u.userstopareacode IS NOT NULL) AS x
        GROUP  BY parent_station) AS y,
       usrstar AS a
WHERE  stop_id = a.dataownercode || '|' || a.userstopareacode
UNION
SELECT stop_id,
       stop_name,
       CAST(Y(the_geom) AS NUMERIC(8,5)) AS stop_lat,
       CAST(X(the_geom) AS NUMERIC(7,5)) AS stop_lon,
       location_type,
       parent_station
FROM   (SELECT u.dataownercode||'|'||u.userstopcode AS stop_id,
               u.name AS stop_name,
               ST_Transform(setsrid(makepoint(p.locationx_ew, p.locationy_ns), 28992), 4326) AS the_geom,
               0 AS location_type,
               u.dataownercode||'|'||u.userstopareacode||'|parent' AS parent_station
        FROM   usrstop AS u, point AS p
        WHERE  u.dataownercode = p.dataownercode
               AND u.userstopcode = p.pointcode
               AND (u.getin = TRUE OR u.getout = TRUE)
               AND u.userstopcode IN (SELECT userstopcodebegin FROM jopatili UNION SELECT userstopcodeend FROM jopatili)) AS KV1
) TO '/tmp/stops.txt' WITH CSV HEADER;
DROP TABLE gtfs_route_type;
CREATE TABLE gtfs_route_type (transporttype varchar(5) primary key, route_type int4);
INSERT INTO gtfs_route_type VALUES ('TRAM', 0);
INSERT INTO gtfs_route_type VALUES ('METRO', 1);
INSERT INTO gtfs_route_type VALUES ('RAIL', 2);
INSERT INTO gtfs_route_type VALUES ('BUS', 3);
INSERT INTO gtfs_route_type VALUES ('BOAT', 4);
-- GTFS: routes.txt
-- If line.transporttype isn't set, it should be added by:
-- ALTER TABLE line ADD COLUMN transporttype VARCHAR(5);
-- UPDATE line SET transporttype = 'BUS';
COPY (
SELECT dataownercode||'|'||lineplanningnumber AS route_id,
      dataownercode AS agency_id,
      linepublicnumber AS route_short_name,
      linename AS route_long_name,
      route_type AS route_type
FROM line, gtfs_route_type WHERE line.transporttype = gtfs_route_type.transporttype
) TO '/tmp/routes.txt' WITH CSV HEADER;

-- GTFS: calendar_dates (Schedules en passeertijden)
COPY (
SELECT
dataownercode||'|'||organizationalunitcode||'|'||schedulecode||'|'||scheduletypecode AS service_id,
replace(CAST(validdate AS TEXT), '-', '') AS "date",
1 AS exception_type
FROM
operday
) TO '/tmp/calendar_dates.txt' WITH CSV HEADER;
-- GTFS: trips.txt (Schedules en passeertijden)
--
-- Missing:
--   KV1 doesn't disclose information about block_id (same busses used for the next trip)
-- 
-- Cornercases:
--   StopOrder and TimingLinkOrder expect a stable minimum.
COPY (
select
p.dataownercode||'|'||p.lineplanningnumber AS route_id,
p.dataownercode||'|'||p.organizationalunitcode||'|'||p.schedulecode||'|'||p.scheduletypecode AS service_id,
p.dataownercode||'|'||p.organizationalunitcode||'|'||p.schedulecode||'|'||p.scheduletypecode||'|'||p.lineplanningnumber||'|'||p.journeynumber AS trip_id,
d.destnamefull AS trip_headsign,
(cast(j.direction AS int4) - 1) AS direction_id,
jt.dataownercode||'|'||jt.lineplanningnumber||'|'||jt.journeypatterncode AS shape_id
FROM pujopass AS p, jopa AS j, jopatili AS jt, dest AS d WHERE
p.dataownercode = j.dataownercode AND
p.lineplanningnumber = j.lineplanningnumber AND
p.journeypatterncode = j.journeypatterncode AND
j.dataownercode = jt.dataownercode AND
j.lineplanningnumber = jt.lineplanningnumber AND
j.journeypatterncode = jt.journeypatterncode AND
jt.dataownercode = d.dataownercode AND
jt.destcode = d.destcode AND
jt.timinglinkorder = 1 AND
p.stoporder = 1
) TO '/tmp/trips.txt' WITH CSV HEADER;

update pujopass set  targetdeparturetime = targetarrivaltime where targetdeparturetime is null;
update pujopass set targetarrivaltime = targetdeparturetime where targetarrivaltime is null;

COPY (
SELECT
p.dataownercode||'|'||p.organizationalunitcode||'|'||p.schedulecode||'|'||p.scheduletypecode||'|'||p.lineplanningnumber||'|'||p.journeynumber AS trip_id, p.targetarrivaltime AS arrival_time, p.targetdeparturetime AS departure_time,
p.dataownercode||'|'||p.userstopcode AS stop_id,
p.stoporder AS stop_sequence,
cast(not getin as integer) as pickup_type,
cast(not getout as integer) as drop_off_type
FROM pujopass AS p, usrstop as u
WHERE p.dataownercode = u.dataownercode
AND p.userstopcode = u.userstopcode
AND (u.getin = TRUE OR u.getout = TRUE)
) TO '/tmp/stop_times.txt' WITH CSV HEADER;

-- GTFS: calendar (Schedules en passeertijden)
COPY (
SELECT
dataownercode||'|'||organizationalunitcode||'|'||schedulecode||'|'||scheduletypecode AS service_id,
cast(1 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS monday,
cast(2 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS tuesday,
cast(3 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS wednesday,
cast(4 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS thursday,
cast(5 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS friday,
cast(6 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS saturday,
cast(7 in (select extract(dow from generate_series(validfrom, validthru, interval '1 day'))) AS int4) AS sunday,
replace(CAST(validfrom AS TEXT), '-', '') AS start_date,
replace(CAST(validthru AS TEXT), '-', '') AS end_date
FROM
schedvers
) TO '/tmp/calendar.txt' WITH CSV HEADER;
