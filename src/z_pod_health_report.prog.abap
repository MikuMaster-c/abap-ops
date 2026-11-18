REPORT z_pod_health_report.
* 目的：练内表 + 结构 + LOOP + 条件输出。
* 数据是硬编码的，因为本机没有 ABAP 运行时；这个程序只用于说明
* "我知道 ABAP 的报表长什么样"，不代表它跑过。

TYPES: BEGIN OF ty_pod,
         pod_name  TYPE string,
         namespace TYPE string,
         restarts  TYPE i,
       END OF ty_pod.

DATA: gt_pods TYPE STANDARD TABLE OF ty_pod WITH EMPTY KEY,
      gs_pod  TYPE ty_pod.

START-OF-SELECTION.

  gt_pods = VALUE #(
    ( pod_name = 'agent-ops-7d9' namespace = 'default'  restarts = 5 )
    ( pod_name = 'web-2b1'       namespace = 'default'  restarts = 0 )
    ( pod_name = 'job-4c8'       namespace = 'batch'    restarts = 2 )
    ).

  LOOP AT gt_pods INTO gs_pod.
    IF gs_pod-restarts >= 3.
      WRITE: / 'WARN', 8 gs_pod-namespace, 28 gs_pod-pod_name,
               60 gs_pod-restarts.
    ELSE.
      WRITE: / 'OK  ', 8 gs_pod-namespace, 28 gs_pod-pod_name,
               60 gs_pod-restarts.
    ENDIF.
  ENDLOOP.
