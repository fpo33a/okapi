
-- create user kafka_test;
drop user kafka_test cascade;
create user kafka_test identified by kafka_test;

-- grant some permissions;
grant create session, alter session, unlimited tablespace, create table, create procedure, create type, create view, create sequence, create materialized view to kafka_test;
grant execute on sys.utl_file to kafka_test;

-- create ext table directory
create or replace directory KAFKA_LOCATION_DIR as '/home/oracle';
grant read, write on directory KAFKA_LOCATION_DIR to kafka_test;

-- add permission for utl_http
grant execute on utl_http to kafka_test;
grant execute on dbms_lock to kafka_test;
 
-- add acl to connect to Okapi server
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'local_kafka_acl_file.xml',
    description  => 'A kafka test of the ACL functionality',
    principal    => 'KAFKA_TEST',
    is_grant     => TRUE, 
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);
end;
/

begin
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => 'local_kafka_acl_file.xml',
    host        => 'localhost', 
    lower_port  => 9123,
    upper_port  => NULL);    
end; 
/
commit;

-- create dummy test table
create table kafka_test.ext_test (
  data   Varchar2(2000)
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
    records delimited  by newline
    fields  terminated by ','
    missing field values are null
  )
  location ('test_fp100.topic')
)
reject limit unlimited;