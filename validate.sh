#!/bin/bash
# Validator for Arriva KV1 files
# Echo out all files in directory!

DBNAME="koppelvlak1"
DATAOWNERCODE="EBS"

mv $DATAOWNERCODE.txt /tmp/agency.txt

createdb $DBNAME
psql -d $DBNAME -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql > /dev/null
psql -d $DBNAME -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql > /dev/null
psql -d $DBNAME -f fix_rijksdriehoek.sql > /dev/null
rm -rf unzipped
for file in kv1/*.ZIP ; do
        psql -d $DBNAME -f clean.sql > /dev/null
        psql -d $DBNAME -f kv1.sql > /dev/null
        psql -d $DBNAME -f kv1_$DATAOWNERCODE.sql > /dev/null
        echo "Import " "$file"
        echo $file
        unzip "$file" -d unzipped
        ./postgresql-import-$DATAOWNERCODE.sh unzipped | psql -d $DBNAME
        rm -rf unzipped
        echo "Make GTFS"
        if [ $DATAOWNERCODE = "EBS" ] ; then
             psql -d $DBNAME -f gtfs-shapes-EBS.sql
        else                   
             psql -d $DBNAME -f gtfs-shapes.sql
        fi
        echo gtfs-$(basename "${file}")
        zip -j "gtfs/gtfs-$(basename "${file}")" /tmp/*.txt
        python transitfeed-1.2.11/feedvalidator.py "gtfs/gtfs-$(basename "${file}")" -o "gtfs/gtfs-$(basename "${file}").html" -l 50000 --error_types_ignore_list=ExpirationDate,FutureService
        python transitfeed-1.2.11/kmlwriter.py "gtfs/gtfs-$(basename "${file}")"
done
dropdb $DBNAME
