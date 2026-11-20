INTERFACE zif_ops_status_enh PUBLIC.
* BAdI 接口：把"多少次重启算严重"的判定交给增强实现。
*
* 为什么这里该是 BAdI 而不是配置表：
* 阈值不是一个数，是一套判断逻辑——有人按重启次数，有人按时间窗口内的频率，
* 有人要结合副本数；做成配置表只能覆盖"换个数字"这一种情况。
* 而 BAdI 允许客户在不动标准代码的前提下替换整个判定逻辑，
* 这是 SAP 增强模型存在的理由：标准交付给一千个客户，判定口径必然不一致。
*
* 注意：这里用接口 + 实现类的写法模拟 BAdI，
* 真实系统的挂载点是 SE18 建 BAdI 定义、SE19 建实现，
* 或者走 enhancement framework 的显式增强点（ENHANCEMENT-POINT）。
* 语义一样：标准代码在固定位置留一个出口，客户代码在出口处接管。

  METHODS classify
    IMPORTING iv_restarts       TYPE i
    RETURNING VALUE(rv_status)  TYPE string.

ENDINTERFACE.
