# abap-ops

用 ABAP 调用 `agent-ops` 的诊断接口，把返回结果打印成报表。

写这个是为了回答一个问题：**ABAP 在真实项目里怎么和外部系统说话。**
答案是 `cl_http_client`——ABAP 侧调 REST 接口的标准做法，不是我编的接缝。

## 三个文件，各练一件事

| 文件 | 练什么 |
|---|---|
| `src/z_pod_health_report.prog.abap` | 内表定义、`VALUE #()` 构造、`LOOP AT ... INTO`、条件输出 |
| `src/zif_ops_http.intf.abap` | 接口抽象（ABAP 里也讲依赖倒置） |
| `src/zcl_ops_http.clas.abap` | `cl_http_client` 发 POST、取 response |

## 这里的边界，说清楚

**代码没有在真实 SAP 系统上跑过。** 本机没有 ABAP 运行时，起一套
ABAP Platform Developer Edition 要几十 GB 和一个 SAP 账号，不在这次的时间预算里。

那为什么还要写？因为**能被检查的部分是真的**：

- `.abapgit.xml` 是 abapGit 的标准格式，任何有 ABAP 系统的开发者可以导入
- `abaplint` 是开源的 ABAP 静态检查器，3 个文件本地跑过：`0 issues`（2.120.109，ABAP release v793）
- `cl_http_client` 的调用顺序（create → set_method → set_cdata → send → receive）是标准用法

这三点合起来，比一份"我学过 ABAP"的陈述更硬，但也不能说成"我写过生产 ABAP"。

## 面试怎么说

> 我最近自己看了 ABAP。写了个小东西练手——一个报表程序定义内表、循环输出，
> 另一个用 `cl_http_client` 调我自己那个 K8s 诊断 agent 的接口。
> **没在真实 SAP 系统上跑过**，本机起 ABAP 平台成本太高。
> 我用了 abapGit 的仓库格式和 abaplint 做静态检查，所以结构是能验证的。

最后那句"没跑过"必须留着。它让前面所有内容都可信。

## 本地检查

```bash
npm install -g @abaplint/cli
abaplint
```
