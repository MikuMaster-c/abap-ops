CLASS zcl_ops_http DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_ops_http.
ENDCLASS.

CLASS zcl_ops_http IMPLEMENTATION.
  METHOD zif_ops_http~post_json.
    DATA: lo_client TYPE REF TO if_http_client.

    cl_http_client=>create_by_url(
      EXPORTING url    = iv_url
      IMPORTING client = lo_client ).

    lo_client->request->set_method( 'POST' ).
    lo_client->request->set_content_type( 'application/json' ).
    lo_client->request->set_cdata( iv_body ).
    lo_client->send( ).
    lo_client->receive( ).

    rv_response = lo_client->response->get_cdata( ).
    lo_client->close( ).
  ENDMETHOD.
ENDCLASS.
