alter table link drop column transporttype;
alter table pool drop column transporttype;
alter table line drop column transporttype;
alter table dest drop column relevantdestnamedetail;
alter table usrstop drop column userstoptype;
alter table jopatili drop column productformulatype;
alter table pujopass drop column dataownerisoperator;
alter table line alter linevetagnumber type VARCHAR(3);
alter table jopatili drop constraint jopatili_dataownercode_fkey;

-- Some Veolia KV1 do have this column
alter table pujopass drop column wheelchairaccessible;
