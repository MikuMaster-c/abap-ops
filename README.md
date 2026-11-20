# abap-ops

用 ABAP 写的运维诊断报表套件。调用外部诊断服务的 REST 接口，把结果存进 DDIC 表，
按重启次数分级，用 ALV 展示。

写它是为了练三件事：ABAP 怎么调外部接口、怎么组织数据、怎么给过程式代码写测试。

## 状态

代码通过 [abaplint](https://abaplint.org/) 静态检查（11 个文件，0 issues），
但**没有在真实 ABAP 系统上运行过**。

原本打算用 ABAP Platform 的 Docker 镜像本地跑起来，三个都没成：SAP 官方那个已经在
2026 年 11 月下线，两个社区镜像的 HANA 试用许可证都已过期。许可证绑定硬件密钥，
过期后数据库只允许许可证相关操作，ABAP 工作进程连不上库，`disp+work` 起不来。

所以这个仓库能提供的是可导入的 abapGit 源码和静态检查结果。ALV 渲染、ABAP Unit
执行、表激活都还没验证过。

## 结构

```
src/
├── zops_diag_log.tabl.xml              DDIC 透明表：诊断记录
├── zcl_ops_status.clas.abap            阈值判定
├── zcl_ops_status.clas.testclasses.abap  ABAP Unit
├── zif_ops_status_enh.intf.abap        增强接口
├── zcl_ops_status_enh.clas.abap        增强实现
├── zcl_ops_log.clas.abap               表读写
├── zif_ops_http.intf.abap              HTTP 接口
├── zcl_ops_http.clas.abap              cl_http_client 实现
├── zcx_ops_http.clas.abap              异常类
├── z_pod_health_report.prog.abap       ALV 报表
└── z_ops_diagnose_report.prog.abap     调用诊断服务 + 落库 + ALV
```

## 检查

```bash
npm install -g @abaplint/cli
abaplint
# 0 issue(s) found, 11 file(s) analyzed
```

## 导入

1. 系统里装 [abapGit](https://abapgit.org/)
2. 用 abapGit 克隆本仓库到 `$TMP` 包
3. 激活对象

表定义在 `src/zops_diag_log.tabl.xml`，导入后需在 SE11 激活。

如果系统版本不是 7.54，改 `abaplint.json` 里的 `syntax.version`。

## 几个设计取舍

**阈值判定单独成类。** 报表的 `START-OF-SELECTION` 里写的逻辑没有供单元测试调用的
出口，抽到 `zcl_ops_status` 之后才能断言。抽出来的唯一理由就是可测性。

**判定口径做成增强点。** 阈值不是一个数字：有人按重启次数，有人按单位时间内的频率，
有人还要看副本数。配置表只能改数值，换不掉判定逻辑本身。真实系统里这个出口是
SE18 / SE19，这里用接口注入表达同一件事，顺带让测试能替换实现。

不带实现时回退默认阈值——增强是选配，不该让没配它的环境报错。

**HTTP 调用抽到接口后面。** ABAP Unit 不能依赖网络，`cl_http_client` 直接写在报表里
就没法测。

**失败也写日志。** 调用出错时同样落一行记录，状态置 CRIT。只记成功的日志表，
在出事那天恰好是空的。

## 已知限制

- 增强点用接口注入模拟，没用 SE18 / SE19 的真实定义
- 诊断报表不解析返回的 JSON，只整体展示
- `z_pod_health_report` 里是硬编码样例数据，没写 `SELECT`（方便无系统时审阅）
- 异常类用属性存原因，没用消息类（SE91），因此没有多语言
- CI 工作流配置在，但从未执行过
