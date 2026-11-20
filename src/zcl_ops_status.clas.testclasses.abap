* ABAP Unit 的测试代码放在独立的 test include 里（abapGit 约定：
* <类名>.clas.testclasses.abap），由类定义后面的 LOCAL FRIENDS 声明绑定。
* 这也是为什么它们不在同一个文件里——不是我把测试和生产混在一起。

CLASS ltc_classify DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS healthy           FOR TESTING.
    METHODS warn_range        FOR TESTING.
    METHODS crit_range        FOR TESTING.
    METHODS boundary_at_three FOR TESTING.
    METHODS boundary_at_ten   FOR TESTING.
    METHODS enh_overrides     FOR TESTING.
    METHODS enh_optional      FOR TESTING.
ENDCLASS.


CLASS ltc_classify IMPLEMENTATION.
  METHOD healthy.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 0 )
      exp = zcl_ops_status=>c_ok ).
  ENDMETHOD.

  METHOD warn_range.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 5 )
      exp = zcl_ops_status=>c_warn ).
  ENDMETHOD.

  METHOD crit_range.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 12 )
      exp = zcl_ops_status=>c_crit ).
  ENDMETHOD.

  " 边界：2 是 OK，3 才进 WARN。
  " 写阈值最容易错的就是这一格——把 >= 写成 >，
  " 功能上看不出来，但线上判定会整体偏移一档。
  METHOD boundary_at_three.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 2 )
      exp = zcl_ops_status=>c_ok ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 3 )
      exp = zcl_ops_status=>c_warn ).
  ENDMETHOD.

  " 同上，WARN 与 CRIT 的分界在 10。
  METHOD boundary_at_ten.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 9 )
      exp = zcl_ops_status=>c_warn ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify( 10 )
      exp = zcl_ops_status=>c_crit ).
  ENDMETHOD.

  " 增强实现接管判定：同一个重启次数（5），标准逻辑判 WARN，
  " 高敏感实现判 CRIT。这条测的是"挂上增强之后标准逻辑真的让位了"。
  METHOD enh_overrides.
    DATA(lo_enh) = NEW zcl_ops_status_enh( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify_with( io_enh = lo_enh iv_restarts = 5 )
      exp = zcl_ops_status=>c_crit ).
  ENDMETHOD.

  " 增强是选配：没挂实现时必须退回默认阈值，而不是报错或返回空。
  " 这条是上线安全性的底线——一套增强不该让没配它的客户环境挂掉。
  METHOD enh_optional.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_ops_status=>classify_with( io_enh = VALUE #( ) iv_restarts = 5 )
      exp = zcl_ops_status=>c_warn ).
  ENDMETHOD.
ENDCLASS.
