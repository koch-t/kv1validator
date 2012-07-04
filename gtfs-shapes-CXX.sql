SELECT shape_id,
       CAST(Y(the_geom) AS NUMERIC(8,5)) AS shape_pt_lat,
       CAST(X(the_geom) AS NUMERIC(7,5)) AS shape_pt_lon,
       shape_pt_sequence,
       shape_dist_traveled
FROM
  (SELECT jopatili.dataownercode||'|'||jopatili.lineplanningnumber||'|'||jopatili.journeypatterncode AS shape_id,
   ST_Transform(setsrid(makepoint(locationx_ew, locationy_ns), 28992), 4326) AS the_geom,
   rank() over (ORDER BY jopatili.dataownercode, jopatili.lineplanningnumber, jopatili.journeypatterncode, jopatili.timinglinkorder, pool.distancesincestartoflink) AS shape_pt_sequence,
   pool.distancesincestartoflink AS shape_dist_traveled
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
   ORDER BY jopatili.dataownercode,
            jopatili.lineplanningnumber,
            jopatili.journeypatterncode,
            jopatili.timinglinkorder,
            pool.distancesincestartoflink) AS KV1 LIMIT 20;

-- GTFS: shapes.txt
--
-- Missing:
--  KV1 support for LinkValidFrom
--  GTFS support for shape_dist_traveled (summation of distancesincestartoflink) 

COPY (
SELECT DISTINCT shape_id,
       CAST(Y(the_geom) AS NUMERIC(8,5)) AS shape_pt_lat,
       CAST(X(the_geom) AS NUMERIC(7,5)) AS shape_pt_lon,
       shape_pt_sequence
FROM
  (SELECT jopatili.dataownercode||'|'||jopatili.lineplanningnumber||'|'||jopatili.journeypatterncode AS shape_id,
   ST_Transform(setsrid(makepoint(locationx_ew, locationy_ns), 28992), 4326) AS the_geom,
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
   ORDER BY jopatili.dataownercode,
            jopatili.lineplanningnumber,
            jopatili.journeypatterncode,
            jopatili.timinglinkorder,
            pool.distancesincestartoflink) AS KV1 ORDER BY shape_id, shape_pt_sequence
) TO '/tmp/shapes.txt' WITH CSV HEADER;


-- GTFS: stops.txt
--
-- Missing
--  KV1 support for filtering out for actually used stops.

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
               AND (u.getin = TRUE OR u.getout = TRUE)) AS KV1
) TO '/tmp/stops.txt' WITH CSV HEADER;


-- GTFS: routes.txt
COPY (
SELECT dataownercode||'|'||lineplanningnumber AS route_id,
       dataownercode AS agency_id,
       linepublicnumber AS route_short_name,
       linename AS route_long_name,
       3 AS route_type
FROM line
) TO '/tmp/routes.txt' WITH CSV HEADER;


-- GTFS: trips.txt (Geldigheden en rijtijdgroepen)
--
-- Missing:
--   KV1 doesn't disclose information about block_id (same busses used for the next trip)

COPY (
select
p.dataownercode||'|'||p.lineplanningnumber AS route_id,
p.dataownercode||'|'||p.timetableversioncode||'|'||p.organizationalunitcode||'|'||p.periodgroupcode||'|'||p.specificdaycode||'|'||p.daytype AS service_id,
p.dataownercode||'|'||p.periodgroupcode||'|'||p.lineplanningnumber||'|'||p.journeynumber AS trip_id,
d.destnamefull AS trip_headsign,
(j.direction - 1) AS direction_id,
jt.dataownercode||'|'||jt.lineplanningnumber||'|'||jt.journeypatterncode AS shape_id
FROM pujo AS p, jopa AS j, jopatili AS jt, dest AS d WHERE
p.dataownercode = j.dataownercode AND
p.lineplanningnumber = j.lineplanningnumber AND
p.journeypatterncode = j.journeypatterncode AND
j.dataownercode = jt.dataownercode AND
j.lineplanningnumber = jt.lineplanningnumber AND
j.journeypatterncode = jt.journeypatterncode AND
jt.dataownercode = d.dataownercode AND
jt.destcode = d.destcode AND
jt.timinglinkorder = 0
) TO '/tmp/trips.txt' WITH CSV HEADER;


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


-- GTFS: stop_times (Schedules en passeertijden)
--
-- Missing:
--   pickup/dropoff type (never used)
--   shape_dist_traveled (may give a false estimation of price, not yet)

COPY (
SELECT
p.dataownercode||'|'||p.organizationalunitcode||'|'||p.schedulecode||'|'||p.scheduletypecode||'|'||p.lineplanningnumber||'|'||p.journeynumber AS trip_id,
lpad(floor((EXTRACT( epoch from p.targetarrivaltime) / 3600) + 1)::text, 2, '0')||':'||lpad(EXTRACT( minutes from p.targetarrivaltime)::text, 2, '0')||':'||lpad(EXTRACT(seconds from p.targetarrivaltime)::text, 2, '0') AS arrival_time,
lpad(floor((EXTRACT( epoch from p.targetdeparturetime) / 3600) + 1)::text, 2, '0')||':'||lpad(EXTRACT( minutes from p.targetdeparturetime)::text, 2, '0')||':'||lpad(EXTRACT(seconds from p.targetdeparturetime)::text, 2, '0') AS departure_time,
p.dataownercode||'|'||p.userstopcode AS stop_id,
p.stoporder AS stop_sequence,
cast(not getin as integer) as pickup_type,
cast(not getout as integer) as drop_off_type
FROM pujopass AS p, usrstop as u
WHERE p.dataownercode = u.dataownercode
AND p.userstopcode = u.userstopcode
AND (u.getin = TRUE OR u.getout = TRUE)
) TO '/tmp/stop_times.txt' WITH CSV HEADER;

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
select distinct pv.dataownercode||'|'||pv.periodgroupcode||'|'||replace(cast(validfrom as text), '-', '')||'|'||daytype AS service_id, cast(substr(pj.daytype,1,1) = '1' as int) AS monday, cast(substr(pj.daytype,2,1) = '2' as int) AS tuesday, cast(substr(pj.daytype,3,1) = '3' as int) AS wednesday, cast(substr(pj.daytype,4,1) = '4' as int) AS thursday, cast(substr(pj.daytype,5,1) = '5' as int) AS friday, cast(substr(pj.daytype,6,1) = '6' as int) AS saturday, cast(substr(pj.daytype,7,1) = '7' as int) AS sunday, replace(cast(validfrom as text), '-', '') AS start_date, replace(cast(validthru as text), '-', '') AS end_date from pegrval as pv, pujo as pj where pv.dataownercode = pj.dataownercode and pv.organizationalunitcode = pj.organizationalunitcode and pv.periodgroupcode = pj.periodgroupcode
) TO '/tmp/calendar.txt' WITH CSV HEADER;
-- GTFS: calendar_dates (Schedules en passeertijden)

COPY (
SELECT
dataownercode||'|'||organizationalunitcode||'|'||schedulecode||'|'||scheduletypecode AS service_id,
replace(CAST(validdate AS TEXT), '-', '') AS "date",
1 AS exception_type
FROM
operday
) TO '/tmp/calendar_dates.txt' WITH CSV HEADER;
