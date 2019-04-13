-- create package to talk to OkapiSrv
CREATE OR REPLACE PACKAGE KAFKA_TEST.OKAPI
as
   procedure subscribe
            ( piv_okapi_server in varchar2,
              piv_broker in varchar2,
              piv_topic in varchar2,
              piv_consumer_group in varchar2,
              piv_readpolicy in varchar2,
              piv_metadata in varchar2);
   
   procedure unsubscribe
            ( piv_okapi_server in varchar2,
              piv_topic in varchar2,
              piv_consumer_group in varchar2);
end;
/
show errors;

set define off;

CREATE OR REPLACE PACKAGE BODY KAFKA_TEST.OKAPI
as
  procedure send_http_request ( piv_url in varchar2 )
  is
    req utl_http.req;
    res utl_http.resp;
    buffer varchar2(4000);

  begin
    req := utl_http.begin_request(piv_url, 'GET',' HTTP/1.1');
    utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(req, 'content-type', 'application/html');

    res := utl_http.get_response(req);
    -- process the response from the HTTP call
    begin
      loop
        utl_http.read_line(res, buffer);
        dbms_output.put_line(buffer);
      end loop;
      utl_http.end_response(res);
    exception
      when utl_http.end_of_body 
      then
        utl_http.end_response(res);
    end;
  end send_http_request;

  procedure subscribe
            ( piv_okapi_server in varchar2,
              piv_broker in varchar2,
              piv_topic in varchar2,
              piv_consumer_group in varchar2,
              piv_readpolicy in varchar2,
              piv_metadata in varchar2)
  is
  begin
     send_http_request( 'http://'||piv_okapi_server||'/subscribe?topic='||piv_topic||'&consumergroup='||piv_consumer_group||'&readpolicy='||piv_readpolicy||'&broker='||piv_broker||'&metadata='||piv_metadata );
  end subscribe;
  
  procedure unsubscribe
            ( piv_okapi_server in varchar2,
              piv_topic in varchar2,
              piv_consumer_group in varchar2)
  is
  begin
     send_http_request( 'http://'||piv_okapi_server||'/unsubscribe?topic='||piv_topic||'&consumergroup='||piv_consumer_group);
  end unsubscribe;

end;
/
show errors;

