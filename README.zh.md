# Agent Team Protocol

用复制即用的 Markdown 运行手册，管住 AI 编程 Agent。

Agent Team Protocol 是一套轻量流程，用于高风险 AI 编程任务。它帮助你控制任务范围、审查改动，并确认测试不是"假绿"。

**无需安装。无需框架。无需服务。就一套模板加一个检查脚本。**

> **当前版本：v0.2.8** — 完整协议规则见 [`agent-team-rules.md`](agent-team-rules.md)

---

## 快速开始

### 1. 把工具拷进你的项目

```bash
cp -r templates .agent-runs/templates
cp scripts/self-check.sh .agent-runs/self-check.sh
```

### 2. 建一个任务目录

```bash
bash scripts/new-run.sh 加限速
```

或者手动：

```bash
RUN=.agent-runs/$(date +%F)-001-加限速
mkdir -p "$RUN" && cp .agent-runs/templates/*.md "$RUN"/
```

### 3. 让 AI 按模板执行

复制下面这句话发给 AI：

```text
用 Agent Team Protocol 处理这个任务。

先填 .agent-runs/ 新目录里的：
- 00-request.md
- 01-level.md
- 02-plan.md

我确认计划后再动手改代码。

实现完后填剩余文件，关键逻辑要跑反恒真破坏实验。
```

### 4. 审查前跑自检

```bash
bash .agent-runs/self-check.sh
```

---

## 什么时候用

| 适合使用 | 可以不用 |
|-------|-------|
| 新功能、重构、多文件改动 | 改错别字、格式化 |
| 权限/支付/限速等核心逻辑 | 重命名变量 |
| 数据库迁移 | 改一行配置 |
| 改测试代码 | 只读查询 |
| 关键业务逻辑变更 | — |

---

## 模板一览

| 文件 | 用途 |
|:----|:----|
| `00-request.md` | 记录原始需求 |
| `01-level.md` | 判定风险等级 (L0-L4) |
| `02-plan.md` | Brain 写执行计划（含并发计划段） |
| `03-implementation.md` | Worker 记录实现内容、变更文件和修改原因 |
| `04-review.md` | Reviewer 检查范围、计划一致性、正确性、反恒真证据 |
| `05-sabotage.md` | 记录破坏验证测试：故意改坏实现，确认测试会失败 |
| `06-handoff.md` | 最终交付说明：变更摘要、测试结果和遗留风险 |

---

## 反恒真测试

> 测试只有在代码被故意改坏时会失败，才值得信任。

三条规则：

1. **纯函数直调规则** — 业务逻辑直接调函数测，不走 HTTP 绕路。连续调 N+1 次，断言序列结果。
2. **禁止绕路规则** — 不准注入假路由或 mock 被测模块。
3. **破坏实验** — Reviewer 故意改坏核心代码，跑测试（必须 FAIL），还原，跑回归（必须 PASS）。

---

## 并发执行（v0.2.7）

> 「并发跑」只授权 Worker 阶段并行，不豁免分级/审查/验收。

并发场景新增 **Merge Owner** 角色：收集多 Worker 输出 → 处理冲突 → 检查交叉影响 → 形成合并 diff → 交 Reviewer 审查。

**短口令**：说「ATP 并行模式」触发完整并发流程。

---

## 任务目录长什么样

```
.agent-runs/
  templates/                    # 模板
  self-check.sh                 # 自检脚本
  2026-06-19-001-加限速/
    00-request.md
    01-level.md
    02-plan.md
    03-implementation.md
    04-review.md
    05-sabotage.md
    06-handoff.md
```

每个已完成的任务目录就是一份审计线索：计划了什么、改了哪些文件、怎么验证的。

---

## 其他

- `adapters/` — 各 AI 工具的配置文件（Claude Code 看 adapters/claude/CLAUDE.md）
- `examples/` — 完整示例（等有人贡献）

---

## License

MIT
