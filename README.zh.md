# Agent Team Protocol

你的 AI 助手写了测试，通过了。
但它们真的在测东西吗？

一套面向 AI 编程 Agent 的轻量协作流程，核心武器是**反恒真测试（Sabotage-Verified Testing）**。

> 测试只有在代码被故意改坏时会失败，才值得信任。

解决三个常见问题：

- **范围漂移** — Agent 改了不该碰的文件
- **假绿测试** — 测试全绿，代码是坏的
- **无人把关** — Agent 自己写代码、自己测、自己验收

---

## 分级协作

任务按风险分五档，L0-L2 快速走，L3-L4 走全套协议：

| 等级 | 场景 | 流程 |
|:----|:----|:----|
| L0 | 纯问问题 | 直接回答 |
| L1 | 看看/查查 | 直接做，不用问 |
| L2 | 小改（错别字、一行配置） | 直接做，改完说一声 |
| L3 | 逻辑改动、多文件、加功能 | 出计划 → 确认 → 执行 → 审查 |
| L4 | 删文件、部署、高风险 | 全链路：Brain → Worker(s) → Reviewer → 交付 |

---

## 三个角色

| 角色 | 职责 |
|:----|:----|
| **Brain** | 定任务等级、画边界（SCOPE/FROZEN_SCOPE）、出计划 |
| **Worker(s)** | 在锁定范围内执行，留证据（diff、测试输出） |
| **Reviewer** | 审范围、审策略、审技术，跑反恒真破坏实验 |

多 Worker 可并发执行。审查隔离规则：
- L3：同会话切换视角声明即可
- L4：**必须开新会话**（硬隔离，零偏见）

---

## 反恒真测试（Sabotage-Verified Testing）

这是本协议的核心差异点。三条规则确保测试是真的，不是糊弄人的：

### 1. 纯函数直调规则（H4）

直接调纯函数 N+1 次，做序列断言，不绕 HTTP：

```python
# ✅ 正确做法
results = [is_rate_limited(ip) for ip in range(12)]
assert results == [False]*10 + [True, True]
# Traceback 精确指出第 10 个元素不一样
```

### 2. 禁止绕路规则

不准绕过真实路由去测：

```python
# ❌ 绕路——测的是假路由，不是真代码
flask_app.view_functions['rate_limit'] = lambda: "fake"

# ✅ 不绕路——测真实代码
```

### 3. 破坏实验（Reviewer 必跑）

Reviewer 故意把代码改坏，验证测试能发现：

```
Step 1: cp app.py app.py.bak               # 备份
Step 2: 把 is_rate_limited 改成 return True  # 故意改坏
Step 3: 跑测试 → 必须 FAIL                  # 如果 PASS = 假绿
Step 4: cp app.py.bak app.py               # 还原
Step 5: 回归测试 → 全部 PASS
```

---

## 任务记录结构

每个 L3/L4 任务在 `.agent-runs/` 下建一个目录：

```
YYYY-MM-DD-NNN-任务名/
├── 00-request.md              # 原始需求
├── 01-task-classification.md  # 风险等级 + 范围
├── 02-plan.md                 # 执行计划（给人看的）
├── 03-evidence.md             # 执行证据
├── 04-worker-report.md        # Worker 自检报告
├── 05-review.md               # Reviewer 审核结论
├── 06-final.md                # 交付总结
└── 07-brain-recheck.md        # （仅 Reviewer FAIL 时）
```

多 Worker 场景下，`04-worker-report.md` 变为 `04-worker-a-report.md` + `05-worker-b-report.md`，后续文件编号顺延。

---

## 快速开始

1. **判定等级** — L0-L2 直接干，L3-L4 走协议
2. **Brain 出计划** — 写 `01-task-classification.md` + `02-plan.md`，给人看
3. **Worker 执行** — 写 `03-evidence.md` + `04-worker-report.md`
4. **Reviewer 审查** — 跑反恒真检查，写 `05-review.md`
5. **交付** — 汇总到 `06-final.md`

模板见 `templates/`，自检脚本见 `scripts/self-check.sh`。

## License

MIT