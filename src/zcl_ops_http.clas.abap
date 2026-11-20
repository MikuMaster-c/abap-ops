CLASS zcl_ops_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ops_http.

ENDCLASS.


CLASS zcl_ops_http IMPLEMENTATION.
  METHOD zif_ops_http~post_json.
    DATA: lo_client TYPE REF TO if_http_client.

    cl_http_client=>create_by_url(
      EXPORTING url    = iv_url
      IMPORTING client = lo_client
      EXCEPTIONS OTHERS = 1 ).

    " create_by_url 失败时 lo_client 是空的。
    " 不检查就往下走，会在 lo_client->request 处抛短转储（dump），
    " 而 dump 在 ABAP 里是最难排查的一种失败——没有堆栈、没有原因。
    " 所以第一个出口就转成异常。
    IF sy-subrc <> 0 OR lo_client IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_ops_http
        EXPORTING iv_reason = `无法创建 HTTP 客户端（URL 格式或网络栈问题）`.
    ENDIF.

    lo_client->request->set_method( 'POST' ).
    lo_client->request->set_content_type( 'application/json' ).
    lo_client->request->set_cdata( iv_body ).

    lo_client->send(
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      " 失败路径必须 close：不关会泄漏连接，几次之后客户端就拿不到连接了
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_ops_http
        EXPORTING iv_reason = |发送请求失败：{ iv_url } 不可达|.
    ENDIF.

    lo_client->receive(
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_ops_http
        EXPORTING iv_reason = `接收响应失败（连接中断或超时）`.
    ENDIF.

    rv_response = lo_client->response->get_cdata( ).
    lo_client->close( ).
  ENDMETHOD.
ENDCLASS.
