CLASS zcl_ops_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_ok   TYPE string VALUE 'OK'.
    CONSTANTS c_warn TYPE string VALUE 'WARN'.
    CONSTANTS c_crit TYPE string VALUE 'CRIT'.

    " 阈值判定从报表里抽出来，只为了一个目的：能测。
    " 报表程序（Z_POD_HEALTH_REPORT 那种）没有出口可以被单元测试调用，
    " 把逻辑挪进类里，ABAP Unit 才能断言它。
    CLASS-METHODS classify
      IMPORTING iv_restarts      TYPE i
      RETURNING VALUE(rv_status) TYPE string.

    " 可替换判定：传入一个增强实现，用它代替默认阈值。
    " 这条路径存在的意义是——判定口径属于"每个客户不一样"的那类逻辑，
    " 所以它不该硬编码在标准代码里，而该留一个出口。
    " 真实系统里这个出口是 SE18 的 BAdI 定义；
    " 这里用接口注入表达同一件事，好处是可以在 ABAP Unit 里替换。
    CLASS-METHODS classify_with
      IMPORTING io_enh           TYPE REF TO zif_ops_status_enh
                iv_restarts      TYPE i
      RETURNING VALUE(rv_status) TYPE string.

ENDCLASS.


CLASS zcl_ops_status IMPLEMENTATION.
  METHOD classify.
    IF iv_restarts >= 10.
      rv_status = c_crit.
    ELSEIF iv_restarts >= 3.
      rv_status = c_warn.
    ELSE.
      rv_status = c_ok.
    ENDIF.
  ENDMETHOD.

  METHOD classify_with.
    " 没给实现就退回默认阈值——增强是选配，不是必需。
    " 这一点很重要：上线一套增强不应该让没挂实现的客户环境报错。
    IF io_enh IS BOUND.
      rv_status = io_enh->classify( iv_restarts ).
    ELSE.
      rv_status = classify( iv_restarts ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
