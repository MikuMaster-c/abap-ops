CLASS zcl_ops_status_enh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ops_status_enh.

ENDCLASS.


CLASS zcl_ops_status_enh IMPLEMENTATION.
  METHOD zif_ops_status_enh~classify.
    " 一个具体的增强实现：按"单位时间内的重启频率"判，
    " 而不是只看绝对次数。
    "
    " 为什么这个口径值得存在：绝对次数会误报——一个跑了三个月的 Pod
    " 重启 5 次是健康的，一个刚起 10 分钟重启 5 次是灾难。
    " 但接口里只拿到重启次数，拿不到存活时长，所以这里用一个更保守的档：
    " 把这个实现当作"高敏感环境"的版本，阈值整体下移一档。
    " ——这正是 BAdI 的价值：不同环境挂不同实现，标准代码一行不改。
    IF iv_restarts >= 5.
      rv_status = 'CRIT'.
    ELSEIF iv_restarts >= 1.
      rv_status = 'WARN'.
    ELSE.
      rv_status = 'OK'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
