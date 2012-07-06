alter table usrstar alter town drop not null;
alter table usrstop alter town drop not null;

alter table usrstar alter name drop not null;
alter table usrstop alter name drop not null;

alter table dest alter destnamemain type VARCHAR(30);
