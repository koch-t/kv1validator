ENCODING="UTF-8"
DATAPATH="`pwd`/$1"
cd $1

echo "DEST.csv
LINE.csv
CONAREA.csv
CONFINREL.csv
USRSTAR.csv
USRSTOP.csv
POINT.csv
TILI.csv
LINK.csv
POOL.csv
JOPA.csv
JOPATILI.csv
ORUN.csv
SCHEDVERS.csv
PUJOPASS.csv
OPERDAY.csv" | while read i; do
	TABLE=`basename $i .csv | sed 's/X//g'`
	echo "COPY ${TABLE} FROM '${DATAPATH}/${i}' WITH DELIMITER AS '|' NULL AS '' CSV ENCODING '${ENCODING}';"
done
