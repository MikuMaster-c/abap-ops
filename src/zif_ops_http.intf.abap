INTERFACE zif_ops_http PUBLIC.
* 把 HTTP 调用抽成接口，是为了让"诊断"和"取数"分开：
* 报表只关心拿到 JSON，不关心用的是 cl_http_client 还是 mock。
  METHODS post_json
    IMPORTING iv_url  TYPE string
              iv_body TYPE string
    RETURNING VALUE(rv_response) TYPE string.
ENDINTERFACE.
