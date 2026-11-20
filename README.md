# abap-ops

一个 ABAP 侧的运维诊断报表套件：从外部的 K8s 诊断服务取结果，落进 DDIC 表，
按阈值分级，用 ALV 展示，判定逻辑有 ABAP Unit 覆盖，判定口径做成可替换的增强点。

写它为了回答三个问题：**ABAP 怎么和外部系统说话、怎么组织数据、怎么被测。**

> **状态：代码通过 abaplint 静态检查，但尚未在真实 ABAP 系统上激活运行。**
> 原因见 [边界](#边界)。

## 文件

| 文件 | 内容 |
|---|---|
| `src/zops_diag_log.tabl.xml` | DDIC 透明表：诊断记录 |
| `src/zcl_ops_status.clas.abap` | 阈值判定（默认口径） |
| `src/zcl_ops_status.clas.testclasses.abap` | ABAP Unit：7 个测试 |
| `src/zif_ops_status_enh.intf.abap` | 增强接口（BAdI 形式） |
| `src/zcl_ops_status_enh.clas.abap` | 增强实现：高敏感环境 |
| `src/zcl_ops_log.clas.abap` | 表读写 |
| `src/zif_ops_http.intf.abap` | HTTP 接口 |
| `src/zcl_ops_http.clas.abap` | `cl_http_client` 实现 |
| `src/zcx_ops_http.clas.abap` | 自定义异常类 |
| `src/z_pod_health_report.prog.abap` | ALV 报表：读表 + 分级展示 |
| `src/z_ops_diagnose_report.prog.abap` | 调用诊断服务 + 落库 + ALV |

## 三个设计决定

### 1. 阈值判定不在报表里，在类里

报表程序没有供单元测试调用的出口，逻辑写在 `START-OF-SELECTION` 里就永远测不到。
所以 `zcl_ops_status=>classify( )` 被单独拎出来，报表只是它的调用方。
这个拆分的唯一理由就是可测性，不是为了分层好看。

### 2. 判定口径做成可替换的增强

阈值不是一个数字，是一套判断逻辑：有人按重启次数，有人按单位时间内频率，
有人要结合副本数。做成配置表只能覆盖"换个数字"，做成增强才能替换整个判定。

真实系统里这个出口是 SE18 建 BAdI 定义、SE19 挂实现。这里用接口注入表达同一件事，
额外的好处是 ABAP Unit 能直接替换实现来断言"增强真的接管了"。

`zcl_ops_status=>classify_with( )` 不传实现时退回默认阈值——**增强必须是选配**，
上线一套增强不该让没配它的客户环境报错。这一条有测试覆盖（`enh_optional`）。

### 3. HTTP 调用抽成接口，是为了注入假实现

ABAP Unit 不能依赖网络。如果 `cl_http_client` 直接写在报表里，测试要么跑真的
外部服务，要么不测。抽成 `zif_ops_http` 之后，测试类可以实现一个返回固定
JSON 的假类。

## 数据流

```
z_ops_diagnose_report
    │  PARAMETERS: 输入 Pod 名与服务地址
    ▼
zcl_ops_http ──POST──► 外部诊断服务 /diagnose
    │                    返回 JSON
    ▼
zcl_ops_log ──INSERT──► ZOPS_DIAG_LOG
    │
    ▼
cl_salv_table（ALV 展示）

z_pod_health_report
    │  选择屏幕筛选命名空间与最小重启次数
    ▼
zcl_ops_status=>classify  ──可选──► zif_ops_status_enh（增强接管）
    │
    ▼
cl_salv_table（ALV 展示）
```

## 边界

**代码没有在真实 ABAP 系统上运行过。**

原计划用 ABAP Platform 的 Docker 镜像本地启动，但没有成功：

| 镜像 | 结果 |
|---|---|
| `sapse/abap-platform-trial:1909` | 404 —— SAP 于 2026-11 下线该产品线 |
| 社区镜像（1909 / 2022 各一个） | HANA 试用许可证已过期 |

许可证绑定硬件密钥，过期后 HANA 进入只允许许可证相关操作的受限模式，
ABAP 工作进程在 `ThInit: db_connect` 阶段被拒绝，`disp+work` 无法启动。

**能验证的部分**：

- `abaplint` 静态检查：**11 个文件，0 issues**（语法版本 v754）
- 依赖 `open-abap/open-abap-core` 标准库，标准类（`cx_static_check`、`cl_salv_table`）能被解析
- `.abapgit.xml` 是 abapGit 标准格式，有 ABAP 系统的开发者可以直接导入
- `cl_http_client` 的调用顺序（create → set_method → set_cdata → send → receive → close）是标准用法

**不能验证的**：ALV 是否真能渲染、ABAP Unit 是否真能通过、表的激活与写入。
这三件必须有运行中的系统。

## 使用

### 静态检查

```bash
npm install -g @abaplint/cli
abaplint          # 期望输出：0 issue(s) found, 11 file(s) analyzed
```

### 导入到 ABAP 系统

1. 在系统中安装 [abapGit](https://abapgit.org/)
2. 用 abapGit 克隆本仓库到 `$TMP` 包
3. 激活对象

需要按实际系统调整 `abaplint.json` 里的 `syntax.version`（1909 对应 `v754`）。

### 建表

`src/zops_diag_log.tabl.xml` 是 abapGit 格式的表定义，导入后需在 SE11 激活。
若手工建表，字段参照该 XML：`MANDT`、`ID`、`RAN_AT`、`POD_NAME`、`NAMESPACE`、
`RESTARTS`、`STATUS`、`CONFIDENCE`。

## 已知限制

- BAdI 用接口注入模拟，未使用 SE18/SE19 的真实增强定义
- `z_ops_diagnose_report` 不解析返回的 JSON，只做整体展示
- `z_pod_health_report` 使用硬编码样例数据，未写入 `SELECT`（便于无系统时审阅）
- 异常类用 attribute 存原因，未使用消息类（SE91），因此没有多语言支持
- CI 工作流配置存在，但从未在远端执行

## 许可

未声明。如需复用请先确认。
