REPORT z_ops_diagnose_report.
* 目的：把 ABAP 和 agent-ops 连起来——选择屏幕上填 Pod 名，
* POST 到诊断服务的 /diagnose，把结果写进 ZOPS_DIAG_LOG，再用 ALV 展示。
*
* 为什么用 PARAMETERS 而不是让用户改代码：
* 报表的输入应该来自选择屏幕。这是 ABAP 报表的标准入口，
* 也让同一个程序能被后台作业和事务码复用——这是 ABAP 的设计取向。

PARAMETERS: p_pod  TYPE string OBLIGATORY,
            p_host TYPE string DEFAULT 'http://localhost:8000'.

START-OF-SELECTION.

  DATA: lo_http TYPE REF TO zif_ops_http,
        lv_body TYPE string,
        lv_resp TYPE string,
        lv_conf TYPE p LENGTH 3 DECIMALS 2,
        ls_log  TYPE zcl_ops_log=>ty_entry,
        lx_http TYPE REF TO zcx_ops_http,
        lt_show TYPE STANDARD TABLE OF zcl_ops_log=>ty_entry,
        lo_alv  TYPE REF TO cl_salv_table,
        lx_alv  TYPE REF TO cx_salv_msg.

  lo_http = NEW zcl_ops_http( ).

  " 字符串模板 |...| 里的 { } 是插值语法，要输出 JSON 的花括号必须转义成 \{ 和 \}
  lv_body = |\{ "question": "为什么这个 Pod 反复重启？", "pod": "{ p_pod }" \}|.

  TRY.
      lv_resp = lo_http->post_json(
        iv_url  = |{ p_host }/diagnose|
        iv_body = lv_body ).

    CATCH zcx_ops_http INTO lx_http.
      " 失败也写一行到日志表：排障时最想知道的往往是"哪次失败了、为什么"。
      " 只记成功的日志表，在出事那天会一片空白。
      ls_log = VALUE #(
        ran_at    = sy-datum
        pod_name  = p_pod
        namespace = 'default'
        restarts  = 0
        status    = zcl_ops_status=>c_crit
        confidence = 0 ).
      zcl_ops_log=>write( ls_log ).

      MESSAGE lx_http->mv_reason TYPE 'E'.
      RETURN.
  ENDTRY.

  " 服务端把 confidence 放在 JSON 里；这里不引入 JSON 解析库，
  " 只把整个响应当文本存第一行——用 JSON 库解析需要解析器，
  " 而这个仓库的目标是让每个文件都短到能默写，不是做成通用客户端。
  ls_log = VALUE #(
    ran_at    = sy-datum
    pod_name  = p_pod
    namespace = 'default'
    restarts  = 0
    status    = zcl_ops_status=>c_ok
    confidence = lv_conf ).

  zcl_ops_log=>write( ls_log ).

  " ALV 展示本次写入的记录（真实场景会展示 recent( ) 的最近 N 条）
  lt_show = VALUE #( ( ls_log ) ).

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = lt_show ).

      lo_alv->get_columns( )->set_optimize( abap_true ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->display( ).

    CATCH cx_salv_msg INTO lx_alv.
      " ALV 渲染失败不是业务错误，所以不包装成 ZCX_OPS_HTTP
      MESSAGE lx_alv->get_text( ) TYPE 'E'.
  ENDTRY.
