# OKAPI #

OKAPI stands for Oracle Kafka Application Programming Interface

The purpose of this project is to read kafka topic data from oracle sql queries

The application is composed of two components:

- Okapi Server 
- Oracle PLSQL package

## Okapi Server ##

The Okapi server is a very basic java microservice application based on vertx technology.
The REST API is composed of two methods:

- subscribe
- unsubscribe

It currently listens on port 9123.

### *subscribe* method ###

The subcribe method has 5 parameters:

- The kafka broker list
- The topic name
- The consumer group name
- The read policy
- Metadata flag

Example of call:

> http://localhost:9123/subscribe?topic=test&consumergroup=fpcg&readpolicy=earliest&broker=123.45.67.089:9092&metadata=true
> 

The following actions are done when subscribing to a topic:

- Check if there is already a thread running for this topic & consumer group

- If yes just exit

- If no create a new kafka client thread subscribing to this topic & consumer group

- Create a new file called *topic-name_consumer-group.topic*. This file contains the kafka record value ( one record per line )

- If the metadata flag is set to true create a new file called *topic-name_consumer-group.meta* to store kafka record metadata (timestamp,topic,partition,offset). This file contains one line per kafka record.

The subscription remains up and running until the unsubscribe method is explicitly called or the Okapi Server module is stopped. It is so not related to any sql select statement.

### *unsubscribe* method ###

The subcribe method has 2 parameters:

- The topic name
- The consumer group name

Example of call:

> http://localhost:9123/unsubscribe?topic=test&consumergroup=fpcg
> 

The following actions are done when unsubscribing from a topic:

- Check if there is already a thread running for this topic & consumer group

- If yes just stop the thread and close the open file(s) for this topic/consumer group

### Okapi server execution ###

To execute the server just run:


> java -jar OkapiSrv-1.0-SNAPSHOT-fat.jar

The server can be executed on same machine as oracle database or remotely.
If executed remotely the directory must be nfs mounted on the oracle database to allow it to read result files.

 
## Oracle PLSQL package ##

On oracle database side we have a small simple package exposing two procedures:

- subscribe
- unsubscribe

This package can be deployed on premise on a standard oracle database ( version 10 or higher ).
In order to communicate with Okapi Server you need to set oracle ACLs. (see kafka_test_create.sql)
In order to read data from kafka you need to map oracle external table(s) on top or result file(s).

### *subscribe* procedure ###

The subcribe procedure has 6 parameters:

- The Okapi server ip address
- The kafka broker list
- The topic name
- The consumer group name
- The read policy
- Metadata flag

Example of call:

    set serveroutput on
    exec kafka_test.Okapi.subscribe ('localhost:9123','123.45.67.089:9092','test','fpcg','earliest','true');

This procedure does an REST API call to the *subsribe* method of Okapi server module.

Once subscribed, you can read data from kafka topic using a classical oracle external table.
Basically you can, using oracle standard features, read data in the following format
- csv format
- fixed position format
- json format 

### *unsubscribe* procedure ###

The unsubcribe procedure has 3 parameters:

- The Okapi server ip address
- The topic name
- The consumer group name

Example of call:

    set serveroutput on
    exec kafka_test.Okapi.unsubscribe ('localhost:9123','test','fpcg');

This procedure does an REST API call to the *unsubsribe* method of Okapi server module.

## Others ##

Once subscribed to a topic/consumer group, the Okapi server thread just runs and continously dump kafka entering data into output file.
Consecutive sql select on the external table will return more and more rows as data enters kafka topic.

If you unsubscribe file is closed but data is still available from sql query.
If you "re"subscribe file is recreated, so will you receive any new received kafka data ( based on kafka read policy 'earliest' or 'latest' ) 

In case you unsubscribed and want to read all data from the beginning of the topic you need to subscribe again with a new consumer group. In this case do not forget to adapt the external table location with the new file name.

## Example of use ##

    -- create dummy test table
    create table kafka_test.ext_test (
      data   Varchar2(2000)
    )
    organization external (
      type  oracle_loader
      default directory KAFKA_LOCATION_DIR
      access parameters (
    records delimited  by newline
    fields  terminated by ','
    missing field values are null
      )
      location ('test_fpcg.topic')
    )
    reject limit unlimited; 

	set serveroutput on
    exec kafka_test.Okapi.subscribe ('localhost:9123','123.45.67.089:9092','test','fpcg','earliest','true');

    SQL> select * from kafka_test.ext_test;
    
    no rows selected
    
    SQL> 
    
    kafka-console-producer --broker-list localhost:9092 --topic test
    >this is a first test
    >this is a second test
    >
    
    SQL> select * from kafka_test.ext_test;
    
    DATA
    ------------------------------------------------------------------
    this is a first test
    this is a second test
    
    
    SQL> 

    exec kafka_test.Okapi.unsubscribe ('localhost:9123','test','fpcg');

	-- subscribe with same consumer group, get data from where we stand
    exec kafka_test.Okapi.subscribe ('localhost:9123','123.45.67.089:9092','test','fpcg','earliest','true');

    SQL> select * from kafka_test.ext_test;
    
    no rows selected
    
    SQL> 
    
    kafka-console-producer --broker-list localhost:19092 --topic test
    >this is a third test
    >
    
    SQL> select * from kafka_test.ext_test;
    
    DATA
    ------------------------------------------------------------------
    this is a third test
       
    SQL> 

    exec kafka_test.Okapi.unsubscribe ('localhost:9123','test','fpcg');

	-- subscribe with a new consumer group, get all data from beginning
    exec kafka_test.Okapi.subscribe ('localhost:9123','123.45.67.089:9092','test','fpcgNEW','earliest','true');

	SQL> ALTER TABLE kafka_test.ext_test LOCATION ('test_fpcgNEW.topic');

    SQL> select * from kafka_test.ext_test;
    
    DATA
    ------------------------------------------------------------------
    this is a first test
    this is a second test
    this is a third test

    exec kafka_test.Okapi.unsubscribe ('localhost:9123','test','fpcgNEW');

More examples with csv, json & fixed format can be found in sql\test.sql file

## To do ##

- Add kafka authentication ( any method can be used as we use standard java code )
- Improve exception handling ( both sql & java )
- update vertx version
- use java package 
- external table files cleanup ( on unsubscribe ? )
- ...
