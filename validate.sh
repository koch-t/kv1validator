#!/bin/bash
# Validator for Arriva KV1 files
# Echo out all files in directory!

DBNAME="koppelvlak1"
DATAOWNERCODE="SYNTUS"

cp $DATAOWNERCODE.txt /tmp/agency.txt
mkdir gtfs

#Replace spaces in filenames by underscores
#find kv1 -depth -name "* *" -execdir rename 's/ /_/g' "{}" \;
renamexm -s"/ /_/g" kv1/*
for file in kv1/*.ZIP
do
mv ${file} ${file/.ZIP/.zip}
done

createdb $DBNAME
psql -d $DBNAME -c "create extension postgis;"
psql -d $DBNAME -f fix_rijksdriehoek.sql > /dev/null
rm -rf unzipped
for file in kv1/*.zip ; do
        psql -d $DBNAME -f clean.sql > /dev/null
        psql -d $DBNAME -f kv1.sql
        psql -d $DBNAME -f kv1_$DATAOWNERCODE.sql
        echo "Import " "$file"
        echo $file
        unzip "$file" -d unzipped
        echo "Import to Postgres"
        ./postgresql-import-$DATAOWNERCODE.sh unzipped | psql -d $DBNAME
        rm -rf unzipped
        echo "Make GTFS"
        psql -d $DBNAME -f gtfs-shapes-$DATAOWNERCODE.sql
        FILENAME=gtfs-$(basename "${file}")
        FILE="${FILENAME%.*}"
        mkdir gtfs/$FILE
        zip -j "gtfs/$FILE/$FILENAME" /tmp/*.txt
        python transitfeed-1.2.11/feedvalidator.py gtfs/$FILE/$FILENAME -o "gtfs/$FILE/$FILE.html" -l 50000 --error_types_ignore_list=ExpirationDate,FutureService
        python transitfeed-1.2.11/kmlwriter.py gtfs/$FILE/$FILENAME
        zip gtfs/$FILE/$FILE.kmz gtfs/$FILE/$FILE.kml
        rm gtfs/$FILE/$FILE.kml
done
dropdb $DBNAME
