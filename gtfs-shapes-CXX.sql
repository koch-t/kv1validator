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
      shape_pt_sequence,shape_dist_traveled
FROM
 (SELECT jopatili.dataownercode||'|'||jopatili.lineplanningnumber||'|'||jopatili.journeypatterncode AS shape_id,
  ST_Transform(st_setsrid(st_makepoint(locationx_ew, locationy_ns), 28992), 4326) AS the_geom,
  rank() over (PARTITION BY jopatili.dataownercode, jopatili.lineplanningnumber, jopatili.journeypatterncode ORDER BY jopatili.dataownercode, jopatili.lineplanningnumber, jopatili.journeypatterncode, jopatili.timinglinkorder, pool.distancesincestartoflink) AS shape_pt_sequence, dist_traveled as shape_dist_traveled
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

-- GTFS: routes.txt
DROP TABLE gtfs_route_type;
CREATE TABLE gtfs_route_type (transporttype varchar(5) primary key, route_type int4);
INSERT INTO gtfs_route_type VALUES ('TRAM', 0);
INSERT INTO gtfs_route_type VALUES ('METRO', 1);
INSERT INTO gtfs_route_type VALUES ('RAIL', 2);
INSERT INTO gtfs_route_type VALUES ('BUS', 3);
INSERT INTO gtfs_route_type VALUES ('BOAT', 4);
COPY (
SELECT dataownercode||'|'||lineplanningnumber AS route_id,
      dataownercode AS agency_id,
      linepublicnumber AS route_short_name,
      linename AS route_long_name,
      route_type AS route_type
FROM line, gtfs_route_type WHERE line.transporttype = gtfs_route_type.transporttype
) TO '/tmp/routes.txt' WITH CSV HEADER;

COPY (
select distinct pv.dataownercode||'|'||pv.periodgroupcode||'|'||replace(cast(validfrom as text), '-', '')||'|'||daytype AS service_id,
cast(substr(pj.daytype,1,1) = '1' as int) AS monday,
cast(substr(pj.daytype,2,1) = '2' as int) AS tuesday,
cast(substr(pj.daytype,3,1) = '3' as int) AS wednesday,
cast(substr(pj.daytype,4,1) = '4' as int) AS thursday,
cast(substr(pj.daytype,5,1) = '5' as int) AS friday,
cast(substr(pj.daytype,6,1) = '6' as int) AS saturday,
cast(substr(pj.daytype,7,1) = '7' as int) AS sunday,
replace(cast(validfrom as text), '-', '') AS start_date,
replace(cast(validthru as text), '-', '') AS end_date
from pegrval as pv, pujo as pj
where
pv.dataownercode = pj.dataownercode and
pv.organizationalunitcode = pj.organizationalunitcode and
pv.periodgroupcode = pj.periodgroupcode
) TO '/tmp/calendar.txt' WITH CSV HEADER;
