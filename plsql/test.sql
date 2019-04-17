---------------------------------------------------------------------------------
-- basic tests
---------------------------------------------------------------------------------

-- subscribe
set serveroutput on
exec kafka_test.Okapi.subscribe ('localhost:9123','123.456.089:9092','test','fp100','earliest','true');

select * from kafka_test.ext_test;

-- unsubscribe
set serveroutput on
exec kafka_test.Okapi.unsubscribe ('localhost:9123','123.456.089:9092','test','fp100','earliest','true');

-- query
SQL> select * from kafka_test.ext_test;

no rows selected

SQL> 

-- add data in kafka
 kafka-console-producer --broker-list localhost:19092 --topic test
>this is a first test
>this is a second test
>

-- query
SQL> select * from kafka_test.ext_test;

DATA
------------------------------------------------------------------
this is a first test
this is a second test


SQL>

---------------------------------------------------------------------------------
-- csv test
---------------------------------------------------------------------------------

-- on oracle DB
---------------

SQL> -- create dummy test table
create table kafka_test.ext_test_csv (
  firstname   Varchar2(20),
  lastname    Varchar2(20),
  country     Varchar2(20)
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
    records delimited  by newline
    fields  terminated by ','
    missing field values are null
  )
  location ('testcsv_fpcsv.topic')
)
reject limit unlimited;
SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
Table created.

SQL> select * from  kafka_test.ext_test_csv;
select * from  kafka_test.ext_test_csv
*
ERROR at line 1:
ORA-29913: error in executing ODCIEXTTABLEOPEN callout
ORA-29400: data cartridge error
KUP-04040: file testcsv_fpcsv.topic in KAFKA_LOCATION_DIR not found


SQL> set serveroutput on
exec kafka_test.Okapi.subscribe ('localhost:9123','123.456.089:9092','testcsv','fpcsv','earliest','true');
<html><body>Subscribing for testcsv, fpcsv, earliest created</body></html>

PL/SQL procedure successfully completed.

-- On Kafka box
---------------
root@kafka-vm1:/# kafka-topics --zookeeper localhost:32181 --create --replication-factor 1 --partitions 3 --topic testcsv
Error while executing topic command : Topic 'testcsv' already exists.
[2019-04-14 16:00:36,425] ERROR org.apache.kafka.common.errors.TopicExistsException: Topic 'testcsv' already exists.
 (kafka.admin.TopicCommand$)
root@kafka-vm1:/# kafka-console-producer --broker-list localhost:9092 --topic testcsv
>john,doe,usa
>emmanuel,macron,france
>root@kafka-vm1:/# kafka-topics --zookeeper localhost:32181 --create --replication-factor 1 --partitions 3 --topic testcsv
Error while executing topic command : Topic 'testcsv' already exists.
[2019-04-14 16:00:36,425] ERROR org.apache.kafka.common.errors.TopicExistsException: Topic 'testcsv' already exists.
 (kafka.admin.TopicCommand$)
root@kafka-vm1:/# kafka-console-producer --broker-list localhost:9092 --topic testcsv
>john,doe,usa
>emmanuel,macron,france
>

-- on oracle DB
---------------

SQL> select * from  kafka_test.ext_test_csv;

FIRSTNAME	     LASTNAME		  COUNTRY
-------------------- -------------------- --------------------
john		     doe		  usa
emmanuel	     macron		  france

SQL> exec kafka_test.Okapi.unsubscribe ('localhost:9123','testcsv','fpcsv');
<html><body><h1>Ending subscribing for testcsv, fpcsv</body></html>

PL/SQL procedure successfully completed.


---------------------------------------------------------------------------------
-- json test
---------------------------------------------------------------------------------

-- on oracle DB
---------------

SQL> -- create dummy test table
drop table kafka_test.ext_test_json;
create table kafka_test.ext_test_json (
  data   Varchar2(2000)
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
    records delimited  by newline
    missing field values are null
  )
  location ('testjson_fpjson.topic')
)
reject limit unlimited;
SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14
Table created.

SQL> 

SQL> create or replace view kafka_test.vw_test_json
as
  select json_value(data, '$.firstname') as firstname,
         json_value(data, '$.lastname') as lastname,
         json_value(data, '$.country') as country
  from kafka_test.ext_test_json;  2    3    4    5    6  

View created.

SQL> set serveroutput on
exec kafka_test.Okapi.subscribe ('localhost:9123','123.456.089:9092','testjson','fpjson','earliest','true');

-- on kafka server
------------------
root@kafka-vm1:/# kafka-topics --zookeeper localhost:32181 --create --replication-factor 1 --partitions 3 --topic testjson
Created topic testjson.
root@kafka-vm1:/# kafka-console-producer --broker-list localhost:9092 --topic testjson
>{"firstname":"john","lastname":"doe","country":"usa"}
>{"firstname":"emmanuel","lastname":"macron","country":"france"}
>

-- on oracle DB
---------------
SQL> select data from kafka_test.ext_test_json;

DATA
---------------------------------------------------------------------------
{"firstname":"john","lastname":"doe","country":"usa"}
{"firstname":"emmanuel","lastname":"macron","country":"france"}

SQL> 

SQL> select firstname,lastname,country from kafka_test.vw_test_json;

FIRSTNAME            LASTNAME           COUNTRY
--------------------------------------------------------------------
john                 doe                usa
emmanuel             macron             france

exec kafka_test.Okapi.unsubscribe ('localhost:9123','testjson','fpjson');
<html><body><h1>Ending subscribing for testjson, fpjson2</body></html>

PL/SQL procedure successfully completed.

---------------------------------------------------------------------------------
-- fixed position test
---------------------------------------------------------------------------------

-- on oracle DB
---------------

SQL> -- create dummy test table
SQL> create table kafka_test.ext_test_fixed (
  firstname   varchar2(20),
  lastname    varchar2(20),
  country     varchar2(20)
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
     records delimited by newline
     fields (
       firstname position(1: 10) char(10),
       lastname  position(11:30)  char(20),
       country   position(31:50) char(20)
       )
  )
  location ('testfixed_fpfixed.topic')
)
reject limit unlimited;  2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19  

Table created.

SQL> 

SQL> set serveroutput on
exec kafka_test.Okapi.subscribe ('localhost:9123','123.456.089:9092','testfixed','fpfixed','earliest','true');
SQL> <html><body>Subscribing for testfixed, fpfixed, earliest created</body></html>


-- on kafka server
-------------------
root@kafka-vm1:/# kafka-topics --zookeeper localhost:32181 --create --replication-factor 1 --partitions 3 --topic testfixed
Created topic testfixed.
root@kafka-vm1:/# kafka-console-producer --broker-list localhost:19092 --topic testfixed
>john      doe                 usa
>emmanuel  macron              france
>

-- on oracle DB
---------------

SQL> select * from   kafka_test.ext_test_fixed;

FIRSTNAME	     LASTNAME		  COUNTRY
-------------------- -------------------- --------------------
emmanuel	     macron		  france
john		     doe		  usa

SQL> 

---------------------------------------------------------------------------------
-- Getting data AND kafka metadata - this works with any format
-- In the below example i use rownum to join data. This is normally something to NOT do.
-- In this case it works because external tables based on file are always sorted
---------------------------------------------------------------------------------

-- on oracle DB
---------------

 drop table kafka_test.ext_test_fixed_metadata ;
 create table kafka_test.ext_test_fixed_metadata (
  epoch        number,
  topicname   varchar2(50),
  partition   number,
  offset      number
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
    records delimited  by newline
    fields  terminated by ','
    missing field values are null
  )
  location ('testfixed_fpfixed.meta')
)
reject limit unlimited;


create table kafka_test.ext_test_fixed_metadata (
  epoch       number,
  topicname   varchar2(50),
  partition   number,
  offset      number
)
organization external (
  type              oracle_loader
  default directory KAFKA_LOCATION_DIR
  access parameters (
    records delimited  by newline
    fields  terminated by ','
    missing field values are null
  )
  location ('testfixed_fpfixed.meta')
)
reject limit unlimited;
  2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17  
Table created.

select * from kafka_test.ext_test_fixed_metadata;

     EPOCH TOPICNAME					       PARTITION     OFFSET
---------- -------------------------------------------------- ---------- ----------
1.5553E+12 testfixed						       1	  0
1.5553E+12 testfixed						       2	  0

SQL> create or replace view kafka_test.vw_test_fixed_metadata as
  select m.EPOCH,
         m.TOPICNAME,
         m.PARTITION,
         m.OFFSET,
         ROWNUM as RN
  from kafka_test.ext_test_fixed_metadata m;  2    3    4    5    6    7  

View created.

SQL> create or replace view kafka_test.vw_test_fixed as
  select f.FIRSTNAME,
         f.LASTNAME,
         f.COUNTRY,
         ROWNUM as RN
  from kafka_test.ext_test_fixed f;SQL> SQL>   2    3    4    5    6  

View created.

SQL> create or replace view kafka_test.vw_test_fixed_with_metadata as
  select m.EPOCH,
         m.TOPICNAME,
         m.PARTITION,
         m.OFFSET,
         f.FIRSTNAME,
         f.LASTNAME,
         f.COUNTRY
  from kafka_test.vw_test_fixed f inner join kafka_test.vw_test_fixed_metadata m on f.rn = m.rn;
  2    3    4    5    6    7    8    9
View created.

SQL>select * from kafka_test.vw_test_fixed_with_metadata;

SQL> select * from kafka_test.vw_test_fixed_with_metadata;

     EPOCH TOPICNAME					       PARTITION     OFFSET FIRSTNAME		 LASTNAME	      COUNTRY
---------- -------------------------------------------------- ---------- ---------- -------------------- -------------------- --------------------
1.5553E+12 testfixed						       1	  0 emmanuel		 macron 	      france
1.5553E+12 testfixed						       2	  0 john		 doe		      usa

SQL> 




