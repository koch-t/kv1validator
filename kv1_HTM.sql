alter table pool drop constraint pool_dataownercode_fkey;
alter table link drop constraint link_pkey;
alter table link add constraint link_pkey PRIMARY KEY ("dataownercode", "userstopcodebegin", "userstopcodeend", "validfrom");
alter table pool add constraint pool_dataownercode_fkey FOREIGN KEY (DataOwnerCode, UserStopCodeBegin, UserStopCodeEnd, LinkValidFrom) REFERENCES 
link (DataOwnerCode, UserStopCodeBegin, UserStopCodeEnd, ValidFrom);
alter table pool drop constraint pool_dataownercode_fkey;

alter table pool drop constraint pool_pkey;
alter table pool add constraint pool_pkey PRIMARY KEY (DataOwnerCode, UserStopCodeBegin, UserStopCodeEnd, LinkValidFrom, PointDataOwnerCode, 
PointCode);

alter table usrstar alter town drop not null;
alter table usrstop alter town drop not null;

alter table usrstar alter name drop not null;
alter table usrstop alter name drop not null;

alter table dest alter destnamemain type VARCHAR(38);
