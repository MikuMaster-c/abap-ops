CLASS zcx_ops_http DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " 为什么不用 if_t100_message + SE91 消息类：
    " 那需要维护一套消息文本，而这些文本不在源码里，abaplint 校验不到，
    " abapGit 提交时还要单独处理 TEXT 元素。
    " 这里把原因装进 attribute，代价是丢掉多语言，换来的是
    " 这份代码在没有 SAP 系统时也是完整的。这是一个明确的取舍。
    DATA mv_reason TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING iv_reason TYPE string.

ENDCLASS.


CLASS zcx_ops_http IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_reason = iv_reason.
  ENDMETHOD.
ENDCLASS.
