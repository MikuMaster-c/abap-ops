CLASS zcl_ops_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_entry,
             ran_at     TYPE d,
             pod_name   TYPE string,
             namespace  TYPE string,
             restarts   TYPE i,
             status     TYPE string,
             confidence TYPE p LENGTH 3 DECIMALS 2,
           END OF ty_entry.

    " 写一行诊断记录。
    " 用 INSERT 而不是 MODIFY：日志表只追加不改写，
    " 这样每一条历史都能回溯，代价是表会长大，靠归档解决。
    CLASS-METHODS write
      IMPORTING is_entry TYPE ty_entry.

    " 读最近 N 条，供报表使用。DESC 是因为人看日志总是想先看最新的。
    CLASS-METHODS recent
      IMPORTING iv_limit         TYPE i DEFAULT 50
      RETURNING VALUE(rt_entry)  TYPE STANDARD TABLE OF ty_entry.

ENDCLASS.


CLASS zcl_ops_log IMPLEMENTATION.
  METHOD write.
    INSERT zops_diag_log FROM @is_entry.
  ENDMETHOD.

  METHOD recent.
    SELECT FROM zops_diag_log
      FIELDS ran_at, pod_name, namespace, restarts, status, confidence
      ORDER BY ran_at DESCENDING
      INTO TABLE @rt_entry
      UP TO @iv_limit ROWS.
  ENDMETHOD.
ENDCLASS.
