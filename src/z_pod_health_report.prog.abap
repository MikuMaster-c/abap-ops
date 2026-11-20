REPORT z_pod_health_report.
* 目的：从诊断日志表读记录，按重启次数分级，用 ALV 输出。
*
* 为什么用 ALV 而不是 WRITE：
* 真实 SAP 报表都是 ALV——可排序、可筛选、可导出 Excel、可存布局。
* WRITE 只适合演示，上线系统里几乎见不到。
* 报表 + ALV 还带来一个区别：选择屏幕参数可以存成变式（variant），
* 然后由 SM36 后台作业循环调度。这是 ABAP 区别于普通脚本的地方。

TYPES: BEGIN OF ty_row,
         pod_name  TYPE string,
         namespace TYPE string,
         restarts  TYPE i,
         status    TYPE string,
       END OF ty_row.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_ns   TYPE string DEFAULT 'default',
              p_min  TYPE i      DEFAULT 0.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA: gt_rows TYPE STANDARD TABLE OF ty_row,
        gs_row  TYPE ty_row,
        lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lx_err  TYPE REF TO cx_salv_msg.

  " 生产环境这里会是 SELECT ... INTO TABLE FROM zops_diag_log。
  " 用固定数据是因为：没有 SAP 系统时这段程序也要能被静态检查和审阅，
  " 而 DDIC 表在源码仓库里不存在。
  gt_rows = VALUE #(
    ( pod_name = 'agent-ops-7d9' namespace = 'default' restarts = 12 )
    ( pod_name = 'web-2b1'       namespace = 'default' restarts = 4 )
    ( pod_name = 'job-4c8'       namespace = 'batch'   restarts = 1 )
    ( pod_name = 'cache-5f2'     namespace = 'default' restarts = 0 ) ).

  " 按选择屏幕过滤——这是 PARAMETERS 存在的意义，不写就是死代码
  DELETE gt_rows WHERE namespace <> p_ns OR restarts < p_min.

  LOOP AT gt_rows INTO gs_row.
    gs_row-status = zcl_ops_status=>classify( gs_row-restarts ).
    MODIFY gt_rows FROM gs_row.
  ENDLOOP.

  IF gt_rows IS INITIAL.
    MESSAGE '没有符合条件的记录' TYPE 'S' DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  " ALV 输出：字段目录不手写，让 cl_salv 从内表结构自动推导。
  " 手写 field catalog 只在需要改列标题、隐藏字段、加图标时才必要。
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = gt_rows ).

      " 列宽自适应：ALV 的内存表列宽来自字段定义，
      " 中文列标题常常比内容宽，不调整会出现标题被截断。
      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->display( ).

    CATCH cx_salv_msg INTO lx_err.
      " 这里不包装成 ZCX_OPS_HTTP：ALV 渲染失败不是业务错误，
      " 拿到 HTTP 异常类里会让调用方误以为网络出了问题。
      MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.
