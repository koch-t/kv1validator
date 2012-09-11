CREATE TABLE "version" (
    "version" serial,
    "datownercode" VARCHAR(10)   NOT NULL,
    "validfrom"    DATE          NOT NULL,
    "validthru"    DATE,
    "filename"     VARCHAR(32)   NOT NULL,
    PRIMARY KEY ("version", "dataownercode")
);

CREATE TABLE "dest" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"destcode"               VARCHAR(10)   NOT NULL,
	"destnamefull"           VARCHAR(50)   NOT NULL,
	"destnamemain"           VARCHAR(24)   NOT NULL,
	"destnamedetail"         VARCHAR(24),
	"relevantdestnamedetail" VARCHAR(5),
	PRIMARY KEY ("version", "dataownercode", "destcode")
);
CREATE TABLE "line" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"            DECIMAL(2)    NOT NULL,
	"implicit"           CHAR(1)       NOT NULL,
	"dataownercode"      VARCHAR(10)   NOT NULL,
	"lineplanningnumber" VARCHAR(10)   NOT NULL,
	"linepublicnumber"   VARCHAR(4)    NOT NULL,
	"linename"           VARCHAR(50)   NOT NULL,
	"linevetagnumber"    DECIMAL(3)    NOT NULL,
	"description"        VARCHAR(255),
	"transporttype"        VARCHAR(5),
	PRIMARY KEY ("version", "dataownercode", "lineplanningnumber")
);
CREATE TABLE "conarea" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"            DECIMAL(2)    NOT NULL,
	"implicit"           CHAR(1)       NOT NULL,
	"dataownercode"      VARCHAR(10)   NOT NULL,
	"concessionareacode" VARCHAR(10)   NOT NULL,
	"description"        VARCHAR(255)  NOT NULL,
	PRIMARY KEY ("version", "dataownercode", "concessionareacode")
);
CREATE TABLE "confinrel" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"            DECIMAL(2)    NOT NULL,
	"implicit"           CHAR(1)       NOT NULL,
	"dataownercode"      VARCHAR(10)   NOT NULL,
	"confinrelcode"      VARCHAR(10)   NOT NULL,
	"concessionareacode" VARCHAR(10)   NOT NULL,
	"financercode"       VARCHAR(10),
	PRIMARY KEY ("version", "dataownercode", "confinrelcode"),
	FOREIGN KEY ("version", "dataownercode", "concessionareacode") REFERENCES "conarea" ("version", "dataownercode", "concessionareacode")
);
CREATE TABLE "usrstar" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                 DECIMAL(2)    NOT NULL,
	"implicit"                CHAR(1)       NOT NULL,
	"dataownercode"           VARCHAR(10)   NOT NULL,
	"userstopareacode"        VARCHAR(10)   NOT NULL,
	"name"                    VARCHAR(50)   NOT NULL,
	"town"                    VARCHAR(50)   NOT NULL,
	"roadsideeqdataownercode" VARCHAR(10),
	"roadsideequnitnumber"    DECIMAL(5),
	"description"             VARCHAR(255),
	 PRIMARY KEY ("version", "dataownercode", "userstopareacode")
);
CREATE TABLE "usrstop" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                 DECIMAL(2)    NOT NULL,
	"implicit"                CHAR(1)       NOT NULL,
	"dataownercode"           VARCHAR(10)   NOT NULL,
	"userstopcode"            VARCHAR(10)   NOT NULL,
	"timingpointcode"         VARCHAR(10),
	"getin"                   BOOLEAN       NOT NULL,
	"getout"                  BOOLEAN       NOT NULL,
	"deprecated"              CHAR(1),
	"name"                    VARCHAR(50)   NOT NULL,
	"town"                    VARCHAR(50)   NOT NULL,
	"userstopareacode"        VARCHAR(10),
	"stopsidecode"            VARCHAR(10),
	"roadsideeqdataownercode" VARCHAR(10),
	"roadsideequnitnumber"    DECIMAL(5),
	"minimalstoptime"         DECIMAL(5)    NOT NULL,
	"stopsidelength"          DECIMAL(3),
	"description"             VARCHAR(255),
	"userstoptype"            VARCHAR(10),
	PRIMARY KEY ("version", "dataownercode", "userstopcode")
);
CREATE TABLE "point" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"              DECIMAL(2)    NOT NULL,
	"implicit"             CHAR(1)       NOT NULL,
	"dataownercode"        VARCHAR(10)   NOT NULL,
	"pointcode"            VARCHAR(10)   NOT NULL,
	"validfrom"            DATE          NOT NULL,
	"pointtype"            VARCHAR(10)   NOT NULL,
	"coordinatesystemtype" VARCHAR(10)   NOT NULL,
	"locationx_ew"         DECIMAL(10)   NOT NULL,
	"locationy_ns"         DECIMAL(10)   NOT NULL,
	"locationz"            DECIMAL(3),
	"description"          VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "pointcode")
);
CREATE TABLE "tili" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"           DECIMAL(2)    NOT NULL,
	"implicit"          CHAR(1)       NOT NULL,
	"dataownercode"     VARCHAR(10)   NOT NULL,
	"userstopcodebegin" VARCHAR(10)   NOT NULL,
	"userstopcodeend"   VARCHAR(10)   NOT NULL,
	"minimaldrivetime"  DECIMAL(5),
	"description"       VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "userstopcodebegin", "userstopcodeend"),
	FOREIGN KEY ("version", "dataownercode", "userstopcodeend") REFERENCES "usrstop" ("version", "dataownercode", "userstopcode")
);
CREATE TABLE "link" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"           DECIMAL(2)    NOT NULL,
	"implicit"          CHAR(1)       NOT NULL,
	"dataownercode"     VARCHAR(10)   NOT NULL,
	"userstopcodebegin" VARCHAR(10)   NOT NULL,
	"userstopcodeend"   VARCHAR(10)   NOT NULL,
	"validfrom"         DATE          NOT NULL,
	"distance"          DECIMAL(6)    NOT NULL,
	"description"       VARCHAR(255),
	"transporttype"        VARCHAR(5),
	PRIMARY KEY ("version", "dataownercode", "userstopcodebegin", "userstopcodeend", "validfrom", "transporttype"),
	FOREIGN KEY ("version", "dataownercode", "userstopcodebegin", "userstopcodeend") REFERENCES "tili" ("version", "dataownercode", "userstopcodebegin", "userstopcodeend")
);
CREATE TABLE "pool" (
	"tablename"         VARCHAR(10)   NOT NULL,
	version DECIMAL(2) NOT NULL, 
	implicit CHAR(1) NOT NULL, 
	dataownercode VARCHAR(10) NOT NULL,
	userStopCodeBegin VARCHAR(10) NOT NULL,
	UserStopCodeEnd VARCHAR(10) NOT NULL,
	LinkValidFrom DATE NOT NULL,
	PointDataOwnerCode VARCHAR(10) NOT NULL,
	PointCode VARCHAR(10) NOT NULL,
	DistanceSinceStartOfLink NUMERIC(5) NOT NULL,
	SegmentSpeed DECIMAL(4),
	LocalPointSpeed DECIMAL(4),
	Description VARCHAR(255),
	"transporttype"        VARCHAR(5),
	PRIMARY KEY (DataOwnerCode, UserStopCodeBegin, UserStopCodeEnd, LinkValidFrom, PointDataOwnerCode, PointCode, TransportType),
	FOREIGN KEY (DataOwnerCode, UserStopCodeBegin, UserStopCodeEnd, LinkValidFrom, TransportType) REFERENCES link (Version, DataOwnerCode, 
UserStopCodeBegin, 
UserStopCodeEnd, ValidFrom, TransportType), FOREIGN KEY (PointDataOwnerCode, PointCode) REFERENCES point(Version, DataOwnerCode, PointCode));

CREATE TABLE "jopa" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"            DECIMAL(2)    NOT NULL,
	"implicit"           CHAR(1)       NOT NULL,
	"dataownercode"      VARCHAR(10)   NOT NULL,
	"lineplanningnumber" VARCHAR(10)   NOT NULL,
	"journeypatterncode" VARCHAR(10)   NOT NULL,
	"journeypatterntype" VARCHAR(10)   NOT NULL,
	"direction"          int4    NOT NULL,
	"description"        VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode"),
	FOREIGN KEY ("version", "dataownercode", "lineplanningnumber") REFERENCES "line" ("version", "dataownercode", "lineplanningnumber")
);
CREATE TABLE "jopatili" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"            DECIMAL(2)    NOT NULL,
	"implicit"           CHAR(1)       NOT NULL,
	"dataownercode"      VARCHAR(10)   NOT NULL,
	"lineplanningnumber" VARCHAR(10)   NOT NULL,
	"journeypatterncode" VARCHAR(10)   NOT NULL,
	"timinglinkorder"    DECIMAL(3)    NOT NULL,
	"userstopcodebegin"  VARCHAR(10)   NOT NULL,
	"userstopcodeend"    VARCHAR(10)   NOT NULL,
	"confinrelcode"      VARCHAR(10)   NOT NULL,
	"destcode"           VARCHAR(10)   NOT NULL,
	"deprecated"         VARCHAR(10),
	"istimingstop"       BOOLEAN        NOT NULL,
	"displaypublicline"  VARCHAR(4),
	"productformulatype"    DECIMAL(4),
	PRIMARY KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timinglinkorder"),
	FOREIGN KEY ("version", "dataownercode", "confinrelcode") REFERENCES "confinrel" ("version", "dataownercode", "confinrelcode"),
	FOREIGN KEY ("version", "dataownercode", "destcode") REFERENCES "dest" ("version", "dataownercode", "destcode"),
	FOREIGN KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode") REFERENCES "jopa" ("version", "dataownercode", "lineplanningnumber", "journeypatterncode"),
	FOREIGN KEY ("version", "dataownercode", "userstopcodebegin", "userstopcodeend") REFERENCES "tili" ("version", "dataownercode", "userstopcodebegin", "userstopcodeend")
);
CREATE TABLE "orun" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"organizationalunitcode" VARCHAR(10)   NOT NULL,
	"name"                   VARCHAR(50)   NOT NULL,
	"organizationalunittype" VARCHAR(10)   NOT NULL,
	"description"            VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "organizationalunitcode")
);
CREATE TABLE "orunorun" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                      DECIMAL(2)    NOT NULL,
	"implicit"                     CHAR(1)       NOT NULL,
	"dataownercode"                VARCHAR(10)   NOT NULL,
	"organizationalunitcodeparent" VARCHAR(10)   NOT NULL,
	"organizationalunitcodechild"  VARCHAR(10)   NOT NULL,
	"validfrom"                    DATE          NOT NULL,
	PRIMARY KEY ("version", "dataownercode", "organizationalunitcodeparent", "organizationalunitcodechild", "validfrom"),
	FOREIGN KEY ("version", "dataownercode", "organizationalunitcodechild") REFERENCES "orun" ("version", "dataownercode", "organizationalunitcode")
);
CREATE TABLE "specday" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"         DECIMAL(2)    NOT NULL,
	"implicit"        CHAR(1)       NOT NULL,
	"dataownercode"   VARCHAR(10)   NOT NULL,
	"specificdaycode" VARCHAR(10)   NOT NULL,
	"name"            VARCHAR(50)   NOT NULL,
	"description"     VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "specificdaycode")
);
CREATE TABLE "pegr" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"         DECIMAL(2)    NOT NULL,
	"implicit"        CHAR(1)       NOT NULL,
	"dataownercode"   VARCHAR(10)   NOT NULL,
	"periodgroupcode" VARCHAR(10)   NOT NULL,
	"description"     VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "periodgroupcode")
);
CREATE TABLE "excopday" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"organizationalunitcode" VARCHAR(10)   NOT NULL,
	"validdate"              TIMESTAMP     NOT NULL,
	"daytypeason"            DECIMAL(7)    NOT NULL,
	"specificdaycode"        VARCHAR(10)   NOT NULL,
	"periodgroupcode"        VARCHAR(10),
	"description"            VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "organizationalunitcode", "validdate"),
	FOREIGN KEY ("version", "dataownercode", "periodgroupcode") REFERENCES "pegr" ("version", "dataownercode", "periodgroupcode"),
	FOREIGN KEY ("version", "dataownercode", "specificdaycode") REFERENCES "specday" ("version", "dataownercode", "specificdaycode")
);
CREATE TABLE "pegrval" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"organizationalunitcode" VARCHAR(10)   NOT NULL,
	"periodgroupcode"        VARCHAR(10)   NOT NULL,
	"validfrom"              DATE          NOT NULL,
	"validthru"              DATE          NOT NULL,
	PRIMARY KEY ("version", "dataownercode", "organizationalunitcode", "periodgroupcode", "validfrom"),
	FOREIGN KEY ("version", "dataownercode", "organizationalunitcode") REFERENCES "orun" ("version", "dataownercode", "organizationalunitcode")
);
CREATE TABLE "tive" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"organizationalunitcode" VARCHAR(10)   NOT NULL,
	"timetableversioncode"   VARCHAR(10)   NOT NULL,
	"periodgroupcode"        VARCHAR(10)   NOT NULL,
	"specificdaycode"        VARCHAR(10)   NOT NULL,
	"validfrom"              DATE          NOT NULL,
	"timetableversiontype"   VARCHAR(10)   NOT NULL,
	"validthru"              DATE,
	"description"            VARCHAR(255),
	PRIMARY KEY ("version", "dataownercode", "organizationalunitcode", "timetableversioncode", "periodgroupcode", "specificdaycode"),
	FOREIGN KEY ("version", "dataownercode", "organizationalunitcode") REFERENCES "orun" ("version", "dataownercode", "organizationalunitcode"),
	FOREIGN KEY ("version", "dataownercode", "periodgroupcode") REFERENCES "pegr" ("version", "dataownercode", "periodgroupcode"),
	FOREIGN KEY ("version", "dataownercode", "specificdaycode") REFERENCES "specday" ("version", "dataownercode", "specificdaycode")
);
CREATE TABLE "timdemgrp" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"             DECIMAL(2)    NOT NULL,
	"implicit"            CHAR(1)       NOT NULL,
	"dataownercode"       VARCHAR(10)   NOT NULL,
	"lineplanningnumber"  VARCHAR(10)   NOT NULL,
	"journeypatterncode"  VARCHAR(10)   NOT NULL,
	"timedemandgroupcode" VARCHAR(10)   NOT NULL,
	PRIMARY KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode"),
	FOREIGN KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode") REFERENCES "jopa" ("version", "dataownercode", "lineplanningnumber", "journeypatterncode")
);
CREATE TABLE "timdemrnt" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"             DECIMAL(2)    NOT NULL,
	"implicit"            CHAR(1)       NOT NULL,
	"dataownercode"       VARCHAR(10)   NOT NULL,
	"lineplanningnumber"  VARCHAR(10)   NOT NULL,
	"journeypatterncode"  VARCHAR(10)   NOT NULL,
	"timedemandgroupcode" VARCHAR(10)   NOT NULL,
	"timinglinkorder"     DECIMAL(3)    NOT NULL,
	"userstopcodebegin"   VARCHAR(10)   NOT NULL,
	"userstopcodeend"     VARCHAR(10)   NOT NULL,
	"totaldrivetime"      DECIMAL(5)    NOT NULL,
	"drivetime"           DECIMAL(5)    NOT NULL,
	"expecteddelay"       DECIMAL(5),
	"layovertime"         DECIMAL(5),
	"stopwaittime"        DECIMAL(5)    NOT NULL,
	"minimumstoptime"     DECIMAL(5),
	PRIMARY KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode", "timinglinkorder"),
	FOREIGN KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode") REFERENCES "timdemgrp" ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode"),
	FOREIGN KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timinglinkorder") REFERENCES "jopatili" ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timinglinkorder")
);
CREATE TABLE "pujo" (
	"tablename"         VARCHAR(10)   NOT NULL,
	"version"                DECIMAL(2)    NOT NULL,
	"implicit"               CHAR(1)       NOT NULL,
	"dataownercode"          VARCHAR(10)   NOT NULL,
	"organizationalunitcode" VARCHAR(10)   NOT NULL,
	"timetableversioncode"   VARCHAR(10)   NOT NULL,
	"periodgroupcode"        VARCHAR(10)   NOT NULL,
	"specificdaycode"        VARCHAR(10)   NOT NULL,
	"daytype"                CHAR(7)       NOT NULL,
	"lineplanningnumber"     VARCHAR(10)   NOT NULL,
	"journeynumber"          DECIMAL(6)    NOT NULL,
	"timedemandgroupcode"    VARCHAR(10)   NOT NULL,
	"journeypatterncode"     VARCHAR(10)   NOT NULL,
	"departuretime"          CHAR(8)       NOT NULL,
	"wheelchairaccessible"   VARCHAR(13)   NOT NULL,
	"dataownerisoperator"    BOOLEAN       NOT NULL,
	 PRIMARY KEY ("version", "dataownercode", "timetableversioncode", "organizationalunitcode", "periodgroupcode", "specificdaycode", "daytype", "lineplanningnumber", "journeynumber"),
	 FOREIGN KEY ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode") REFERENCES "timdemgrp" ("version", "dataownercode", "lineplanningnumber", "journeypatterncode", "timedemandgroupcode"),
	 FOREIGN KEY ("version", "dataownercode", "organizationalunitcode", "timetableversioncode", "periodgroupcode", "specificdaycode") REFERENCES "tive" ("version", "dataownercode", "organizationalunitcode", "timetableversioncode", "periodgroupcode", "specificdaycode")
);

CREATE TABLE schedvers (
    "tablename"         VARCHAR(10)   NOT NULL,
    version numeric(2,0) NOT NULL,
    implicit CHAR(1) NOT NULL,
    dataownercode character varying(10) NOT NULL,
    organizationalunitcode character varying(10) NOT NULL,
    schedulecode character varying(10) NOT NULL,
    scheduletypecode character varying(10) NOT NULL,
    validfrom date NOT NULL,
    validthru date,
    description character varying(255),
    PRIMARY KEY (version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode),
    FOREIGN KEY (version, dataownercode, organizationalunitcode) REFERENCES orun(version, dataownercode, organizationalunitcode)
);

CREATE TABLE operday (
    "tablename"         VARCHAR(10)   NOT NULL,
    version numeric(2,0) NOT NULL,
    implicit CHAR(1) NOT NULL,
    dataownercode character varying(10) NOT NULL,
    organizationalunitcode character varying(10) NOT NULL,
    schedulecode character varying(10) NOT NULL,
    scheduletypecode character varying(10) NOT NULL,
    validdate date NOT NULL,
    description character varying(255),
    PRIMARY KEY (version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode, validdate),
    FOREIGN KEY (version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode) REFERENCES schedvers(version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode)
);

CREATE TABLE pujopass (
    "tablename"         VARCHAR(10)   NOT NULL,
    version numeric(2,0) NOT NULL,
    implicit CHAR(1) NOT NULL,
    dataownercode character varying(10) NOT NULL,
    organizationalunitcode character varying(10) NOT NULL,
    schedulecode character varying(10) NOT NULL,
    scheduletypecode character varying(10) NOT NULL,
    lineplanningnumber character varying(10) NOT NULL,
    journeynumber numeric(6,0) NOT NULL,
    stoporder numeric(4,0) NOT NULL,
    journeypatterncode character varying(10) NOT NULL,
    userstopcode character varying(10) NOT NULL,
    targetarrivaltime char(8),
    targetdeparturetime char(8),
    wheelchairaccessible VARCHAR(13),
    dataownerisoperator boolean NOT NULL,
    PRIMARY KEY (version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode, lineplanningnumber, journeynumber, stoporder),
    FOREIGN KEY (version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode) REFERENCES schedvers(version, dataownercode, organizationalunitcode, schedulecode, scheduletypecode),
    FOREIGN KEY (version, dataownercode, userstopcode) REFERENCES usrstop(version, dataownercode, userstopcode),
    FOREIGN KEY (version, dataownercode, lineplanningnumber, journeypatterncode) REFERENCES jopa(version, dataownercode, lineplanningnumber, journeypatterncode)
);

