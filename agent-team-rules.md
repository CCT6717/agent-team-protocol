# Agent 协作理论 + 操作协议

> **Part I**：多智能体协作的形式化理论基础
> **Part II**：经过实战验证的操作协议与模板
> 状态：v0.1 最小闭环 PASS · 第二阶段记录层 OPERATIONAL · v0.2.8 协议定版

---

# Part I · 理论基础

---

## 1. 第一性原理

### 1.1 根本问题

多智能体协作面临三个不可约简的根本问题：

| 问题 | 表现 | 后果 |
|------|------|------|
| **写冲突** | 两个智能体同时改同一文件 | 变更覆盖、数据丢失 |
| **假共识** | 智能体各自说"做完了"，但结果对不上 | 审核流于形式，bug 漏过 |
| **范围漂移** | 智能体做了授权范围外的事 | 越权修改、配置污染 |

这三大问题无法通过"更智能的模型"解决——它们是分布式系统的固有属性，必须通过**结构约束**来解决。

### 1.2 三根支柱

```
  ┌─────────────────────────────────────┐
  │        Agent 协作理论               │
  ├───────────────────┬─────────────────┤
  │   结构层           │   验证层         │
  │ 权力分离 · 范围隔离 │ 证据真相 · 反恒真 │
  └───────────────────┴─────────────────┘
  ┌─────────────────────────────────────┐
  │           演化层                     │
  │       失败沉淀 → 规则硬化            │
  └─────────────────────────────────────┘
```

**P1 · 权力分离** — 写权限必须独占且显式授予；任何时刻最多一个 Worker 可写；审核者永远只读。

**P2 · 范围隔离** — 每个 Agent 的操作边界由显式声明定义；SCOPE ∩ FROZEN_SCOPE = ∅；越界即 FAIL。

**P3 · 证据真相** — 系统内唯一可信的事实来源是持久化介质的可观测状态；Agent 的自述不构成证据。

这三根支柱缺一不可：权力分离防止写冲突，范围隔离防止越界，证据真相防止假共识。

### 1.3 推演：从支柱到规则

从三根支柱可以形式化推导出所有操作规则：

| 支柱 | 形式化推论 | 对应操作规则 |
|------|-----------|-------------|
| P1 权力分离 | 同一文件同一时刻最多一个 Writer | SWMR、WRITE_LOCKS |
| P1 权力分离 | Reader 不能拥有写能力 | Reviewer 只读、能力自检 |
| P1 权力分离 | 写权限转移必须经过仲裁者 | Brain 持锁管理器 |
| P2 范围隔离 | 操作前必须定义边界 | FROZEN_SCOPE、SCOPE 声明 |
| P2 范围隔离 | 边界必须可机器校验 | glob 格式而非自然语言 |
| P2 范围隔离 | 触碰边界必须停止 | NEED_USER_DECISION |
| P3 证据真相 | Agent 自述不构成证据 | 证据优先原则 |
| P3 证据真相 | 证据必须可独立复现 | 磁盘/diff/测试输出 |
| P3 证据真相 | 测试可被绕过 | 反恒真定理（§5） |

---

## 2. 权力分离理论

### 2.1 写权模型（Write Authority Model）

系统包含一个文件集合 **F = {f₁, f₂, ..., fₙ}** 和一个 Agent 集合 **A = {a₁, a₂, ..., aₘ}**。

在任一时刻 **t**，写权函数 **W: A × F × T → {0, 1}** 满足：
- **单写约束**：∀f ∈ F, ∀t ∈ T: Σᵢ W(aᵢ, f, t) ≤ 1
- **读无穷约束**：∀f ∈ F, ∀t ∈ T: R(aᵢ, f, t) = 1 对任意 aᵢ 成立（读者不互斥）

### 2.2 权力谱系

每个角色拥有一个权力向量 **(read, write, verify, assign)**：

| 角色 | read | write | verify | assign |
|------|------|-------|--------|--------|
| Brain | 1 | 0 | 1 | 1 |
| Worker | 1 | 1 (锁定范围内) | 0 | 0 |
| Reviewer | 1 | 0 | 1 | 0 |
| Gate | 0 | 0 | 1 (仅规则) | 0 |
| Deliverer | 1 | 0 | 0 | 0 |

**形式约束**：write(a, f) = 1 ⇒ ∃ lock(a, f) ∈ LOCKS。没有任何 Agent 可以无锁写入。

### 2.3 SWMR 不变量

```
∀f ∈ FILES, ∀t ∈ TIME:
  │{ a ∈ AGENTS : write(a, f, t) = 1 }│ ≤ 1
```

证明草稿：WRITE_LOCKS 是 SWMR 的实现机制。Brain 在阶段 **S** 开始时确立 LOCKSₛ 分配。Worker 只能在 LOCKSₛ 中为自己分配的文件上 write=1。Worker 完成或 FAIL 后，Brain 释放 LOCKSₛ 进入下一阶段。Key 的持有者唯一性保证 SWMR。

### 2.4 Brain 中转定理

**定理**：两个 Worker 之间不存在直接通信信道。所有信息交换必须经过 Brain。

**推论**：如果 Worker A 的输出是 Worker B 的输入，则 Worker A 的证据包必须经 Brain 验证后转发给 Worker B。这保证了 Brain 作为唯一仲裁者的角色，防止 Worker 之间形成未授权的共识。

---

## 3. 状态机理论

### 3.1 状态定义

任务状态集合 **S = {DRAFT, PLANNED, APPROVED, DRY_RUN_ONLY, IN_PROGRESS, WORKER_DONE, REVIEWING, NEEDS_DECISION, PASSED, FAILED, FINALIZED, ABORTED, READY_FOR_FINAL_CONFIRM}**

### 3.2 状态转移图

```
                ┌──────────────────────────────────┐
                │                                  │
                ↓                                  │
DRAFT → PLANNED → APPROVED → IN_PROGRESS → WORKER_DONE → REVIEWING
                │              │                            │
                │              ↓                            ↓
                │        DRY_RUN_ONLY             ┌─── PASSED ───→ FINALIZED
                │              │                  │
                │              ↓                  ├─── FAILED ──→ PLANNED (重试)
                │          WORKER_DONE            │
                │                                ├─── NEEDS_DECISION → APPROVED
                │                                │
                │                                └─── NEEDS_DECISION → ABORTED
                │
                └───────────────── 任何状态 ───→ ABORTED
```

### 3.3 转移守卫（Transition Guards）

每条转移必须满足守卫条件：

| 转移 | 守卫条件 |
|------|---------|
| DRAFT → PLANNED | Brain 已理解需求，完成等级评估 |
| PLANNED → APPROVED | 用户已确认计划（L1 可跳过） |
| APPROVED → IN_PROGRESS | WRITE_LOCKS 已分配，Worker Task Card 已下发 |
| APPROVED → DRY_RUN_ONLY | L4 任务且用户指定仅观察 |
| IN_PROGRESS → WORKER_DONE | Worker 完成所有 AC，证据包已输出 |
| WORKER_DONE → REVIEWING | Reviewer 已启动独立会话 |
| REVIEWING → PASSED | 审核结论 PASS |
| REVIEWING → FAILED | 审核结论 FAIL |
| REVIEWING → NEEDS_DECISION | 审核发现需用户选择的决策点 |
| REVIEWING → READY_FOR_FINAL_CONFIRM | 审核结论 PASS + 等待用户最后确认按钮 |
| PASSED → FINALIZED | 交付者已输出最终报告 |
| FAILED → PLANNED | Worker 按 Required Fixes 修改后重新计划 |
| NEEDS_DECISION → APPROVED | 用户做出方向选择 |
| * → ABORTED | 用户终止 |

### 3.4 状态不变量

在每个状态下，以下条件恒成立：

- **IN_PROGRESS**：Worker.write_count > 0 ∧ ∀ 其他 Worker'.write_count = 0
- **REVIEWING**：∀ Agent, Agent.write = 0（审核期间全部只读）
- **FINALIZED**：06-final.md 存在且 TASK_RESULT ≠ 空
- **ABORTED**：无需进一步动作，系统已释放所有锁

---

## 4. 角色演算

### 4.1 角色签名

每个角色由其 **(能力集, 约束集)** 唯一标识：

```
Role = (Capabilities, Constraints)
Capabilities ⊆ {READ, WRITE, VERIFY, ASSIGN, DELIVER}
Constraints = { 范围子句, 通信约束, 生命周期 }
```

### 4.2 角色形式定义

```
Brain:
  Capabilities = {READ, VERIFY, ASSIGN}
  Constraints  = {不可直接写文件, 不可执行Worker任务}
  Lifecycle    = 任务全程存活

Worker:
  Capabilities = {READ, WRITE(锁定范围内)}
  Constraints  = {只写LOCKS内的文件, 不与其他Worker通信}
  Lifecycle    = PLAN → WORKER_DONE

Reviewer:
  Capabilities = {READ, VERIFY}
  Constraints  = {不可写任何文件, 必须在独立会话运行}
  Lifecycle    = WORKER_DONE → REVIEW_DONE

Gate:
  Capabilities = {VERIFY(仅规则匹配)}
  Constraints  = {不可读取任务内容, 不参与结果判断}
  Lifecycle    = 触发式

Deliverer:
  Capabilities = {READ}
  Constraints  = {不可修改, 不可验证}
  Lifecycle    = REVIEW_PASS → FINALIZED
```

### 4.3 能力偏序

能力之间的包含关系构成偏序格：

```
ASSIGN
  ↑
WRITE(锁定) ─→ VERIFY
  ↑              ↑
  └── READ ──────┘
```

**推论**：拥有 WRITE 能力的角色必然拥有 READ。ASSIGN 能力是最高级权限，仅 Brain 持有。Reader 能力是最低级权限，所有角色都至少有 READ。

### 4.4 Reviewer 硬隔离定理

**定理**：Reviewer 与 Worker 共享同一会话上下文时，Reviewer 的结论不可信。

**证明**：如果 Reviewer 和 Worker 在同一上下文，Reviewer 会继承 Worker 的中间状态（读取过的文件、执行过的命令、形成的偏见），无法独立评估。只有在新会话（新的 context window、干净的推理链路）中，Reviewer 的审查才具有独立性。

**推论**：任何声称在同一上下文中完成 Reviewer 工作的输出必须标记为 `NEEDS_INDEPENDENT_REVIEW`，不可直接按 PASS/FAIL 处理。

---

## 5. 范围代数

### 5.1 基础定义

文件宇宙 **U** 是所有可访问文件的集合。对于任务 **T**：

```
SCOPE(T) ∪ FROZEN_SCOPE(T) = U(T)
SCOPE(T) ∩ FROZEN_SCOPE(T) = ∅
WRITE_LOCKS(T) ⊆ SCOPE(T)
```

其中 **U(T)** 是任务 T 涉及的候选文件集。

### 5.2 FROZEN_SCOPE 代数

冻结范围具有传递性：

```
FROZEN_SCOPE(T) = FROZEN_SCOPE_user ⊕ FROZEN_SCOPE_history

其中 ⊕ 为范围并集（union），冻结范围只增不减。
```

**冻结闭包**：如果路径 **p** 被冻结，则 p 的所有子路径 **p/*** 也被冻结。

```
p ∈ FROZEN_SCOPE ⇒ p/** ∈ FROZEN_SCOPE
```

### 5.3 WRITE_LOCKS 代数

```
WRITE_LOCKS(T) = {(p₁ → a₁), (p₂ → a₂), ..., (pₙ → aₙ)}

约束：
① ∀i: pᵢ ∈ SCOPE(T)
② ∀i ≠ j: pᵢ ∩ pⱼ = ∅（无重叠锁）
③ ∪ pᵢ = SCOPE(T) \ FROZEN_SCOPE(T)（锁定范围覆盖全部可写范围）
```

**锁粒度定理**：锁粒度越细，并行度越高，但 Brain 调度开销越大。最小合理粒度为文件级（glob 格式）。比文件更细（字段级）可由 Worker 自行管理。

### 5.4 范围变化规则

```
| 事件 | 对 SCOPE 的影响 | 对 FROZEN_SCOPE 的影响 |
|------|----------------|----------------------|
| 用户新声明冻结 | 不变 | FROZEN_SCOPE ∪ {新范围} |
| Reviewer 发现越界 | 无影响 | 审计标记，不自动冻结 |
| Worker 请求扩大范围 | 需用户确认后更新 | 不变 |
| 任务完成 | 释放全部 | 重置为初始冻结范围 |
```

---

## 6. 验证与证据理论

### 6.1 证据链

**定义**：证据链是一个不可逆序列 **E = (e₁, e₂, ..., eₙ)**，其中每个 **eᵢ** 满足：

1. **可观测性**：eᵢ 可从持久化介质读取
2. **可复现性**：给定相同输入，eᵢ 可被独立第三方复现
3. **不可抵赖性**：eᵢ 的源（文件路径、命令、时间戳）可追溯

### 6.2 证据等级

```
等级3: 破坏实验（验证边界失效）       ← Reviewer 级证据
等级2: 运行验证（测试 PASS / FAIL）    ← Worker 级证据
等级1: 静态验证（diff / 文件内容核对）  ← Worker 级证据
等级0: Agent 自述（"我做完了"）        ← 不可作为证据
```

**断言**：等级 0 在任何审查中不构成有效证据。L2+ 任务的 PASS 至少需要等级 1 证据。L3+ 任务至少需要等级 2。L4 任务至少需要等级 3（破坏实验）。

### 6.3 验证类型

```
静态验证: 读文件、grep、diff、目录列举、配置核对
  → 验证"是否修改了不该改的"

测试验证: 单元测试、集成测试、编译检查
  → 验证"逻辑是否正确"

运行验证: 启动服务、健康检查、接口调用
  → 验证"能否跑起来"

破坏实验: 改坏实现 → 测试应FAIL → 还原 → 回归PASS
  → 验证"测试是真的"
```

### 6.4 分类验证定理

**定理**：任意验证 **V** 可以唯一分类为静态、测试、运行或破坏之一，且同一验证不能同时属于多个类别。

**推论**：一个 PASS 结论必须说明达到了哪个验证等级。如果只做了静态验证就声称 PASS，审核者必须降级为 NEED_USER_DECISION。

---

## 7. 反恒真定理

### 7.1 定义

> **恒真测试**：一个测试套件 T 对实现 I 恒真，当且仅当 T 在不依赖 I 的内部行为时仍然全部 PASS。

### 7.2 定理

> 如果测试套件 T 的构造方式允许绕过被测实现 I（如注入假视图、mock 掉核心函数、修改路由表），则 T 的 PASS 结果**不蕴含** I 的正确性。

**证明**（构造性）：假设测试 T 对 I 恒真。构造 I' ≠ I，使得 I' 包含与 I 不同接口的假实现。将 T 的路由指向 I'。由于 T 不依赖 I 的内部行为，T 在 I' 上同样 PASS。但 I' 不等于 I，所以 T 的 PASS 不证明 I 正确。

### 7.3 实战中的恒真模式

| 模式 | 检测方法 |
|------|---------|
| `view_functions` 注入 | grep "view_functions" |
| 注册同名路由覆盖 | grep "@app.route" + 检查重复 |
| Mock 掉整个模块 | 检查测试 import 路径 |
| 用 wrapper 替换核心函数 | grep "_patch_\|_wrapped_\|_decorated_" |

### 7.4 对抗手段

反恒真的**唯一可靠手段**是 H4 纯函数级断言 + 破坏实验（Part II §7.6 §③）：

- H4 断言暴露精确到元素位置的 traceback（`First differing element 10`）
- 破坏实验修改核心函数后，H4 断言必定 FAIL，且 FAIL 位置可溯源

---

## 8. 协议演化模型

### 8.1 规则硬化路径

每一条操作规则都遵循相同的生命周期：

```
现实失败                         # 某个 Agent 犯错了
  → 案例沉淀                     # 记录到案例库，标注"这个错了"
  → 短规则                       # 提取为一条可执行的禁止/必须规则
  → 模板嵌入                     # 写入 Worker Task Card / Reviewer 检查表
  → 全局硬化                     # 写入 AGENTS.md / CLAUDE.md
  → 自动化（可选）                # 做成 grep 检查 / CI 门禁
```

### 8.2 规则层级

```
| 层级 | 存储位置 | 更新频率 | 示例 |
|------|---------|---------|------|
| 原理级 | 本文 Part I | 极少修改 | 权力分离、SWMR |
| 协议级 | 本文 Part II | 阶段迭代 | WRITE_LOCKS 模板 |
| 策略级 | AGENTS.md | 按需更新 | "不改 FROZEN_SCOPE" |
| 案例级 | 案例库 | 每次任务 | CASE-003 工具链验证 |
| 自动化 | grep/CI 脚本 | 随规则更新 | 反注入 grep |
```

### 8.3 演化不变量

协议演化过程中以下性质必须保持不变：

1. **SWMR 不变量**：任何新规则不得引入多 Writer 并发
2. **证据不变量**：任何新规则不得降低证据等级要求
3. **审核独立不变量**：任何新规则不得允许审核者修改文件

---

# Part II · 操作协议

---

## 1. 核心原则

### 1.1 修改权隔离

> 多智能体**不能同时拥有修改权**；同一阶段只能一个执行者可以写，审核者永远只读。

### 1.2 范围冻结

用户明确说"不要动某块""只改某部分"时，该范围冻结到**字段级**。执行者不得修改范围内任何子字段、配置项、文件内容或行为逻辑。如需触碰必须停止并单独确认。

### 1.3 证据优先

PASS 的唯一依据：**磁盘文件内容、Git Diff、测试输出**。不接受"执行者说已做完"作为验收标准。

### 1.4 能力自检

承担 L3+ 任务的会话，必须先通过一次只读能力自检（读目录、读文件、git status、git diff、运行测试）。无法通过则卸任。

---

## 2. 角色分工

### 2.1 v0.1 角色（中文）

```
用户
│
协调者
├── 执行者：按授权范围完成任务
├── 审核者：只读复核结果和证据
├── 规则门禁：判断是否需要用户确认
└── 交付者：输出最终交付说明
```

扩展角色：
- **规划者**：拆解需求、制定执行计划
- **验证者**：运行或核查测试、命令和证据链
- **安全/正确性/风格审核者**：按维度拆分审查

### 2.2 v0.2 角色升级（Brain/Worker/Reviewer）

| v0.1 | v0.2 | 职责 | 权限 |
|------|------|------|------|
| 协调者 | **Brain** | 理解需求、判断等级、拆解原子任务、分发 Worker Task Card、协调 Reviewer | 控权，不直接执行 |
| 执行者 | **Worker** | 收到独立 Task Card，持 WRITE_LOCKS 租约，只做卡片描述的事，输出证据包 | 可写，受 WRITE_LOCKS 约束 |
| 审核者 | **Reviewer** | 必须在新会话/新 context window 启动，否则输出 `NEEDS_INDEPENDENT_REVIEW` | **只读**，硬隔离 |
| 规则门禁 | 保留 | 判断是否触发用户确认条件 | 决策是否继续 |
| 交付者 | 保留 | 汇总最终结果 | 汇总，不扩大范围 |

核心约束：
- **SWMR（Single Writer, Multiple Readers）**：同一文件系统上一次只能一个 Worker 有写权限
- **Brain 中转**：Worker 之间如需共享信息，通过 Brain 中转，不直接通信

---

## 3. 任务风险等级

| 等级 | 类型 | 需用户确认 | 需审核者 | Superpowers |
|------|------|-----------|---------|-------------|
| L1 | 纯聊天、解释、总结、只读查询、review、代码库解释 | 不需要 | 不需要 | 不触发 |
| L2 | 小改动、单文件修改、补测试 | 需要 | 建议 | 不触发 |
| L3 | 多文件修改、配置变更、跨模块 | 必须 | 必须 | **强制触发** |
| L4 | 删除、迁移、部署、数据库、系统配置、破坏现存配置/数据兼容性 | 必须 + 单独确认风险 | 必须 | **强制触发** |

---

## 4. 标准流程

### 4.1 修改类任务

**L1-L2（简化流程）**：
```
用户请求
→ Brain 判断等级 (L1-L2)
→ Worker 给出计划 → 用户确认
→ Worker 执行 → 输出证据包
→ Reviewer 只读复核（L2 建议）→ PASS / FAIL / NEED_USER_DECISION
→ 若 FAIL：Worker 只修 Required Fixes（不扩大范围）
→ 若 NEED_USER_DECISION：停下来问用户
→ 若 PASS：交付者交付
```

**L3-L4（Superpowers 完整流程）**：
```
用户请求
→ Brain 判断等级 (L3-L4)
→ 触发 /brainstorming：
   → 探索上下文 → 逐个问清需求 → 提出 2-3 方案
   → 出设计文档 → cct 审核设计
→ 触发 /writing-plans：
   → 基于设计文档出实施计划
→ 计划写入 02-plan → cct 确认
→ Worker 执行 → 输出证据包
→ Reviewer 只读复核（L3 同会话 / L4 必须新会话）
→ 若 FAIL：Worker 只修 Required Fixes
→ 若 PASS：交付者交付
```

### 4.2 查询类任务

```
用户提问 → Brain 判 READ_ONLY → 只读查询 → 必要时审核 → 直接回答
```

### 4.3 方案设计类任务

```
用户提想法 → Brain 澄清约束 → 多角度分析 → 汇总 2-3 方案 → 用户选方向 → 进入实现
```

### 4.4 高风险任务（L4）

```
用户提高风险操作 → Brain 标记 L4 → /brainstorming 完整流
→ /writing-plans 出实施计划 → 规则门禁列风险 → 用户确认
→ 分阶段执行 → 逐阶段审核 → 交付
```

---

## 5. 审查结论标准

### PASS

- 已完成用户要求的核心目标
- 无违规、无未授权操作
- 验证结果明确
- 未完成项和风险已说明

### FAIL

- 未经确认就修改了不该修改的内容
- 安装/下载/删除/改配置未授权
- 结果明显不符合要求
- 存在明显技术错误
- 验证证据不真实
- 做了大量无关改动
- 触碰冻结范围且未经确认

### NEED_USER_DECISION

- 需用户在多个方案中选择
- 需扩大任务范围或执行高风险操作
- 发现状态与用户描述不一致
- 完成任务可能触碰冻结范围

---

## 6. 默认任务路由

| 用户意图 | 默认流程 |
|----------|---------|
| "看看/查一下/有没有/在哪" | 只读查询 |
| "review/检查/评估" | 审核者只读审查 |
| "帮我改/实现/加功能/修bug" | 先计划 → 用户确认 → 执行 |
| "设计一下/怎么做/架构方案" | 多智能体讨论或方案设计 |
| "安装/下载/删除/改配置/改环境" | 必须用户确认 |
| "大重构/迁移/改架构" | 方案设计 + 确认 + 分阶段 |

---

## 7. v0.2 协议升级

### 7.1 WRITE_LOCKS 规则

02-plan 和 Worker Task Card 必须包含 WRITE_LOCKS 段。Worker A 锁定的文件，Worker B 不能写。粒度最小为文件级（glob 格式）。Brain 持有锁管理器角色。

```
WRITE_LOCKS:
- src/module_a/* → Worker A
- src/module_b/* → Worker B
```

### 7.2 Worker Task Card 模板

每个 Worker 拿独立任务卡，代替自然语言分配：

```
TASK_ID: v0.2-{YMD}-{NNN}-W{序号}
ASSIGNED_BY: Brain
MODE: DRY_RUN | EXECUTE
SCOPE:
  - 允许读取/修改的路径
WRITE_LOCKS:
  - path/glob → Worker {name}
FROZEN_SCOPE:
  - path/glob（用 glob，不用自然语言）
ACCEPTANCE_CRITERIA:
  - 什么算完成 / 什么算 PASS
VERIFICATION_PLAN:
  - 准备执行的测试/检查
EXPECTED_OUTPUT:
  - 代码/diff/截图/日志
```

### 7.3 状态机扩展

v0.1 状态：`DRAFT → PLANNED → APPROVED → IN_PROGRESS → WORKER_DONE → REVIEWING → PASSED → FINALIZED`

v0.2 新增：

| 状态 | 含义 | 上一状态 | 下一状态 |
|------|------|----------|----------|
| `DRY_RUN_ONLY` | 只观察模式，不点最终发布 | `APPROVED` | `WORKER_DONE` |
| `READY_FOR_FINAL_CONFIRM` | 所有前置条件就绪，等用户最后确认 | `REVIEWING` | `FINALIZED` |
| `NEEDS_DECISION` | 多个分支方向，需用户选择 | `REVIEWING` | `APPROVED` / `ABORTED` |
| `ABORTED` | 任务终止归档 | 任何状态 | 终态 |

审核状态新增 `NEEDS_INDEPENDENT_REVIEW`：审核者未在独立会话运行，不得代审。

### 7.4 v0.2 里程碑

| 里程碑 | 状态 | 日期 |
|--------|------|------|
| M1 — 协议升级定版 | DONE | 2026-06-12 |
| M2 — 小型并发演练 | PASS / FINALIZED | 2026-06-12 |
| L3-CODE-DEMO — 代码并发演练（反恒真三条） | PASS / FINALIZED | 2026-06-13 |
| M3 — 头条 L4 实战 | 进行中 | 自 2026-06-13 起持续推进，当前仍处于 PATCH 系列补丁阶段 |

### 7.5 v0.2 验证能力清单

- ✅ Brain Plan：TASK_SUMMARY / WORKER_ASSIGNMENT / WRITE_LOCKS / VERIFICATION_PLAN 结构
- ✅ Worker Task Card：TASK_ID / SCOPE / WRITE_LOCKS / FROZEN_SCOPE / ACCEPTANCE_CRITERIA
- ✅ WRITE_LOCKS / SWMR：10 文件锁定，3 角色无重叠
- ✅ 双 Worker 并发：A/B 报告时间戳差 20s，零文件冲突
- ✅ Reviewer 硬切换：独立会话审核，5 维度 PASS
- ✅ 证据闭环：00-request → 07-final 全链路 7 文件，三方独立产出
- ✅ 反恒真三条铁规
- ✅ L4 头条实战硬规则三条

### 7.6 反恒真硬规则（2026-06-13 沉淀）

**背景**：L3 演练中 Worker v1 通过 `view_functions` 注入假视图绕过真实实现，6/6 unittest 仍 PASS。Reviewer 硬切换逮住。

**三条铁规（L2+ 任务的 Worker 测试交付 AC 中必须包含，Reviewer 检查表必须包含）**：

**① H4 纯函数级断言作为契约对象铁证**
- 至少连续 N+1 次调用（N = 被测边界值）
- 断言 `assertEqual(pure_results, [expected_pass] × N + [expected_block, expected_block])`
- traceback 必须精确到元素位置（如 `First differing element 10`）

**② 禁止任何 view_functions 注入**
- ❌ `flask_app.view_functions[...] = ...`
- ❌ `@app.route` 重新注册同名路由
- ❌ `_patch_view` / `_rate_limited_view` 等 wrapper
- ❌ `app.before_request` / `after_request` 钩子注入
- 唯一允许入口：`app.test_client()`
- Reviewer 必跑反注入 grep：`grep -nE "view_functions|_patch_view|_rate_limited_view|wrapped_view" test_*.py`，期望 GREP_EXIT=1

**③ Reviewer 必须做破坏实验（改坏实现 → 测试须 FAIL → 还原）**
1. `python -m py_compile {app.py, test_app.py}` → EXIT=0
2. 反注入 grep 三模式 → GREP_EXIT=1
3. `python -m unittest test_app.py -v` → 全部 PASS
4. Reviewer 独立复算脚本（直调纯函数 + 真路由 + /health + JSON 字段 + 清理恢复）→ 全部 PASS
5. **破坏实验**：备份 app.py → 改核心函数为恒定错误返回值 → 复跑测试至少 1 个 FAIL → 还原 → 回归 100% PASS
6. 删除破坏临时文件，FROZEN_SCOPE 无污染

### 7.7 L4 头条实战硬规则（2026-06-13 沉淀）

**① dry_run `[FAIL]` 字样是脚本设计行为**
- 头条发布脚本 `--diagnose` 必然以 `[FAIL]` 结尾（源码 L1168 `return False`）
- 判断 PASS/FAIL 必须溯源 L1xxx 源码确认设计意图

**② 草稿箱核对禁用 playwright MCP**
- playwright MCP 浏览器跟脚本 profile 不共享 cookie/localStorage
- 改为：cct 手动浏览器核对 / 脚本 profile 启动 / API 核对 / 跳过

**③ Worker Task Card 路径必须用绝对路径**
- ❌ `.agent-runs/...`（被解析到 cwd 下，可能触发 FROZEN_SCOPE 违规）
- ✅ `<project-root>/.agent-runs/...`

---

## 8. Prompt 模板

### 8.1 执行者报告

```
TASK_SUMMARY: 本次任务目标
PLAN: 准备怎么做
CHANGES_MADE: 实际做了什么
VERIFICATION: 执行了哪些验证，结果是什么
  STATIC_VERIFICATION: 静态检查
  TEST_VERIFICATION: 测试验证
  RUNTIME_VERIFICATION: 运行验证
RISKS_OR_UNDONE: 剩余风险和未完成事项
```

### 8.2 审核者复核

```
REVIEW_STATUS: PASS | FAIL | NEED_USER_DECISION | NEEDS_INDEPENDENT_REVIEW

Scope Check: 是否在授权范围内操作，是否触碰冻结范围
Policy Check: 是否遵守先问再干，有无未授权操作
Technical Check: 是否解决原始问题，有无 bug/行为漂移
Verification Check: 验证是否真实、必要、充分，是否区分验证类型
Required Fixes: 必须修复的问题
Notes: 其他建议
```

### 8.3 交付者交付

```
TASK_RESULT: PASS | FAIL | NEED_USER_DECISION | CANCELLED
WHAT_WAS_DONE: 实际完成了什么
FILES_CHANGED: 修改了哪些文件
FILES_NOT_TOUCHED: 明确未触碰的冻结范围
VERIFICATION_SUMMARY: 验证了什么、未验证什么及原因
REVIEW_RESULT: 审核者结论
USER_DECISIONS: 用户做过的确认或选择
RISKS_OR_UNDONE: 剩余风险和未完成事项
```

### 8.4 代码库解释

```
TASK_SUMMARY: 解释目标项目结构、运行方式和核心流程
READ_ONLY_SCOPE: 允许读取的范围
FACTS_VERIFIED: 从文件/配置/命令输出确认的事实（可追溯）
ASSUMPTIONS_OR_INFERENCES: 推断内容（说明依据，不写成事实）
CODEBASE_OVERVIEW: 项目是什么、主要用途
TECH_STACK: 语言、框架、数据库、部署
MAIN_DIRECTORIES: 主要目录职责
RUNBOOK: 启动方式、端口、环境变量
KEY_FLOWS: 请求入口、核心链路、错误处理
CURRENT_RISKS_OR_DIRTY_STATE: 现状风险（仅提示，不处理）
```

---

## 8a. 核心流程（总纲）

> **本流程仅用于 L3/L4 任务。L1-L2 直接做，不需要走这套。**

### 8a.1 七步流程（含 Superpowers）

```
用户请求
  ↓
Brain 分类定级（L1-L4）
  ↓
[仅 L3/L4] 触发 Superpowers：
  → /brainstorming：探索上下文 → 逐问需求 → 2-3 方案 → 设计文档
  → cct 审核设计文档
  → /writing-plans：设计文档 → 实施计划
  ↓
Brain 写 01-task-classification + 02-plan（L3/L4 以 Superpowers 输出为输入）
  ↓
cct 确认计划
  ↓
Worker 执行（能并发就并发）
  ↓
Reviewer 审核（L3 同会话 · L4 必须新会话）
  ↓
交付
```

### 8a.2 Reviewer 隔离规则

| 等级 | 审核方式 | 操作 |
|:----|:--------|:----|
| L3 | 同会话切换 | 我声明「切换为 Reviewer 视角」，重新读证据文件后独立复核 |
| L4 | **必须新会话** | 你手动开一个新对话，我进去只读审核，不碰代码 |

> L3 同会话审核时，我会先重置角色状态、忽略之前的执行记忆，只靠证据文件做判定。
> L4 新会话审核是硬隔离——前后两个会话互相看不到对方的内容，确保零偏见。

### 8a.3 Superpowers 触发规则

**触发条件**：Brain 分类为 L3 或 L4 时，**固定触发** Superpowers 完整流程，不可跳过。

**流程**：

| 步骤 | 调用 | 产出 | 说明 |
|:-----|:-----|:-----|:-----|
| 1 | `/brainstorming` | 设计文档 `docs/superpowers/specs/` | 探索上下文 → 逐个问清 → 提 2-3 方案 → 设计 → cct 审核 |
| 2 | `/writing-plans` | 实施计划 | 基于设计文档拆实施步骤 |
| 3 | Brain 写 02-plan | Worker Task Card | 以 Superpowers 产出为输入，写入标准模板 |

**L3/L4 完整链路**：
```
/brainstorming → cct 审核设计 → /writing-plans → 02-plan → cct 确认 → Worker → Reviewer → 交付
```

**不触发场景**：
- L1（纯查询/聊天）：直接回答
- L2（小改动）：走简化流程，不出设计文档

**与现有流程的关系**：
- Superpowers 是 L3/L4 的**前置阶段**，在 Worker 执行之前
- 设计文档是 02-plan 的输入来源，不是替代品
- cct 审核设计文档 = 用户确认计划的一部分

---

## 9. .agent-runs 任务记录规范

### 9.1 目录结构

```
.agent-runs/
  YYYY-MM-DD-NNN-task-slug/
    00-request.md              # 原始需求
    01-task-classification.md  # 任务分类(L1-L4)
    02-plan.md                 # 执行计划（含 WRITE_LOCKS）
    03-evidence.md             # 证据记录
    04-worker-report.md        # 执行者报告
    05-review.md               # 审核者复核
    06-final.md                # 最终交付
```

### 9.2 命名规则

`YYYY-MM-DD-NNN-task-slug`，如 `2026-06-10-001-explain-codebase`

### 9.3 归档规则

- PASS 归档：`05-review.md` 写 `PASS`，`06-final.md` 写 `PASS`，状态 `FINALIZED`
- FAIL 归档：保留失败原因 + Required Fixes，Worker 只修 Required Fixes 后重入 REVIEWING
- NEED_USER_DECISION：记录待决策问题、可选方案，等用户选择后继续
- 中断任务：写 `CANCELLED` 或 `NEED_USER_DECISION`，说明停止点和恢复条件

---

## 10. 完整任务模板（00-06 可复制版）

> **命名规则**：以下使用角色中立命名（`01-task-classification.md`）作为标准。实际使用时两种命名都有效：
>
> | 标准名 | 等价角色名 | 适用场景 |
> |:-------|:----------|:--------|
> | `01-task-classification.md` | `01-brain-plan.md` | 单 Worker 场景 |
> | `02-plan.md` | `02-plan.md` | 无歧义，两种命名一致 |
> | `04-worker-report.md` | `04-worker-a-report.md` | **多 Worker 时按角色编号** |
>
> **原则**：多 Worker 场景下，`04-worker-{name}-report.md`  按字母序顺延编号，每多一个 Worker 多一个文件。
> 不改协议字段，只改文件名后缀区分 Worker。单 Worker 保留原 `04-worker-report.md`。

### 10.1 00-request.md

```markdown
TASK_ID: {task-id}
TASK_TITLE: {简明的任务标题}
TASK_STATUS: DRAFT
RISK_LEVEL: L1 | L2 | L3 | L4
CREATED_AT: {YYYY-MM-DD HH:MM}

ORIGINAL_REQUEST:
- 用户原始请求（逐条记录，不做概括）

NORMALIZED_REQUEST:
- Brain 归一化后的任务目标（拆掉模糊表述）

CONSTRAINTS:
- 用户明确约束
- 技术上不允许做的事
- 时间/环境/工具限制

DO_NOT_TOUCH:
- 禁止触碰的文件/目录/配置
- 用户明确说"不管"的部分

EXPECTED_OUTPUT:
- 期望交付物类型（代码/diff/方案/报告）
```

### 10.2 01-task-classification.md

```markdown
TASK_TYPE: L1 | L2 | L3 | L4
TASK_MODE: READ_ONLY | MODIFICATION | DESIGN | HIGH_RISK
RISK_LEVEL: {理由}

SCOPE:
- 允许读取或修改的范围（glob 格式）

FROZEN_SCOPE:
- 禁止触碰的范围（glob 格式，不要自然语言）

REQUIRES_USER_APPROVAL: YES | NO
REQUIRES_REVIEWER: YES | NO

WHY_THIS_CLASSIFICATION:
- 为什么是这个等级
- 主要风险点
- 如果跟预期不同，说明原因
```

### 10.3 02-plan.md

```markdown
TASK_SUMMARY:
- 本次任务目标

FILES_TO_READ:
- 需要先读取的文件或目录

FILES_TO_CHANGE:
- 计划修改的文件
- 每项修改的原因

NON_GOALS:
- 明确不做的事（防止范围扩大）

WRITE_LOCKS:
- path/glob → Worker {name}

VERIFICATION_PLAN:
- 用什么方法验证每项修改
- ① 静态检查：diff/grep/文件核对
- ② 测试验证：具体测试命令
- ③ 运行验证：启动检查（如有）

ACCEPTANCE_CRITERIA:
- {条件1} → PASS
- {条件2} → FAIL
- {条件3} → NEED_USER_DECISION
```

### 10.4 03-evidence.md

```markdown
FACTS_VERIFIED:
- 从文件、命令输出、测试结果确认的事实
- 每条可追溯到具体命令或文件

ASSUMPTIONS_OR_INFERENCES:
- 基于证据推断但未完全验证的内容
- 每条注明依据

COMMANDS_RUN:
- 执行过的命令及其输出（缩短到关键行）
- 失败的命令也记录

FILES_READ:
- 读取过的文件列表

BASELINE_BEHAVIOR:
- 修改前的基线（git status / config dump）
```

### 10.5 04-worker-report.md（单 Worker）/ 04-worker-{name}-report.md（多 Worker）

```markdown
TASK_SUMMARY:
- 实际完成了什么

CHANGES_MADE:
- 逐条列出变更内容
- 每项对应 02-plan 的哪条计划

FILES_CHANGED:
- 新增：{file1, file2}
- 修改：{file3, file4}
- 删除：{file5}

VERIFICATION:
- STATIC:   grep/diff 结果
- TEST:     测试命令 + 结果摘要
- RUNTIME:  启动检查结果（如有）

RISKS_OR_UNDONE:
- 未完成事项及原因
- 已知风险

WORKER_STATUS: DONE | BLOCKED | NEED_USER_DECISION
```

**多 Worker 编号规则**：

| Worker 数量 | 文件命名 | Brain 分配 WRITE_LOCKS |
|:-----------|:--------|:---------------------|
| 1 | `04-worker-report.md` | 一个 Worker → 这一个文件 |
| 2 | `04-worker-a-report.md` + `05-worker-b-report.md` | Worker A 只写 `04*`，Worker B 只写 `05*`，互相 FROZEN |
| 3 | `04-worker-a.md` + `05-worker-b.md` + `06-worker-c.md` | 依此类推，Review/final 文件号顺延 |

**文件号顺延规则**：每多一个 Worker，后续文件号 +N-1。例：
- 双 Worker：04(A) → 05(B) → 06(review) → 07(final)
- 三 Worker：04(A) → 05(B) → 06(C) → 07(review) → 08(final)

Reviewer 和最终交付的编号总在 Worker 报告之后。

### 10.6 05-review.md

```markdown
REVIEW_INPUTS:
- request, plan, evidence, worker_report, git_status, git_diff, test_output

REVIEW_STATUS: PASS | FAIL | NEED_USER_DECISION | NEEDS_INDEPENDENT_REVIEW

Scope Check:
- 是否只在授权范围内操作：{YES/NO + 证据}
- 是否触碰冻结范围：{YES/NO + 证据}

Policy Check:
- 是否遵守先问再干：{YES/NO}
- 是否存在未授权操作：{YES/NO + 证据}

Technical Check:
- 是否解决原始问题：{YES/NO + 理由}
- 是否存在明显 bug/风险：{YES/NO + 文件:行号}

Verification Check:
- 静态验证是否充分：{YES/NO}
- 测试验证是否真实（反恒真检查）：{YES/NO + grep 结果}
- 破坏实验是否执行：{YES/NO + 结果}
- 未验证项是否说明原因：{YES/NO}

Required Fixes:
1. {文件:行号} — {问题描述}

Notes:
- 其他建议
```

### 10.7 06-final.md

```markdown
TASK_RESULT: PASS | FAIL | NEED_USER_DECISION | CANCELLED

WHAT_WAS_DONE:
- 实际完成了什么

FILES_CHANGED:
- 修改了哪些文件

FILES_NOT_TOUCHED:
- 明确未触碰的冻结范围（逐项确认）

VERIFICATION_SUMMARY:
- 执行了哪些验证
- 未执行哪些验证及原因
- 最高证据等级：{1/2/3}

REVIEW_RESULT:
- 审核结论：{PASS/FAIL}
- Required Fixes 处理情况

USER_DECISIONS:
- 用户做过的确认或选择（逐条记录）

RISKS_OR_UNDONE:
- 剩余风险
- 未完成事项

---

### 10.8 07-brain-recheck.md（Brain 复算 · 仅 Reviewer FAIL 时触发）

> 当 Reviewer 判定 FAIL 后，任务不直接回到 Worker，而是先由 Brain 做独立复算。
> Brain 以 Reviewer 的 Required Fixes 为输入，判定（a）Fix 方向是否正确、（b）是否需重写计划、（c）是否升级风险等级。

```markdown
TRIGGER:
- Reviewer 判定 FAIL
- Required Fixes 列表

BRAIN_RECHECK:

1. REQUIRED_FIXES_REVIEW:
   - Fix 1: {问题描述} → {Brain 评估：同意 / 修正 / 否决 + 理由}
   - Fix 2: {同上}

2. PLAN_UPDATE:
   - 计划是否需要重写：{YES/NO + 理由}
   - 是否需要调整 SCOPE/FROZEN_SCOPE：{YES/NO}
   - 是否需要升级 RISK_LEVEL：{YES/NO}

3. WORKER_REASSIGNMENT:
   - 原 Worker 继续修复：{YES/NO + 理由}
   - 新 Worker 接手：{Worker name + 理由}
   - WRITE_LOCKS 是否有变化：{YES/NO}

4. RE_REVIEW_REQUIREMENT:
   - 修复后是否需要原 Reviewer 复审：{YES/NO}
   - 是否需要新 Reviewer 独立复审：{YES/NO}

BRAIN_VERDICT: PROCEED | REJECT | NEED_USER_DECISION

PROCEED 路径 → Worker 按 Required Fixes + Brain 修正修复 → 重入 REVIEWING
REJECT 路径 → 任务终止，归档为 CANCELLED
NEED_USER_DECISION → 提请用户裁定
```
- 后续建议
```

---

## 11. 角色操作指南

### 11.1 Brain 操作流程

拿到用户请求后，按顺序执行：

**第一步：分类**
1. 是查询/解释 → L1，只读模式，走简化流程
2. 是方案/设计 → 先讨论，不落地
3. 是修改/实现/修 bug → 判断影响范围
4. 是删除/部署/改配置 → 标 L4，强制逐项确认

**第二步：拆解**
1. 把需求拆成可独立执行的原子任务
2. 判断是否需要多个 Worker（并发＞1）
3. 需要并发 → 分配 WRITE_LOCKS，保证锁无重叠
4. 不需要并发 → 一个 Worker 搞定

**第三步：写 02-plan**
1. 写 TASK_SUMMARY、SCOPE、FROZEN_SCOPE
2. 写 WRITE_LOCKS、ACCEPTANCE_CRITERIA
3. 用户确认后再派工

**第四步：派工 & 中转**
1. 下发 Worker Task Card（每个 Worker 独立卡片）
2. Worker 执行期间不切入
3. Worker 完成后读证据包，转发给 Reviewer
4. Worker A 输出须给 Worker B 的 → Brain 中转

**第五步：收尾**
1. 收到 Reviewer 结论后执行对应动作
2. PASS → 交给 Deliverer
3. FAIL → 告诉 Worker 只修 Required Fixes
4. NEED_USER_DECISION → 停下来问用户

### 11.2 Worker 操作流程

收到 Task Card 后：

**执行前**
1. 重读 SCOPE 和 FROZEN_SCOPE — 记牢边界
2. 重读 WRITE_LOCKS — 只改分配给自己的文件
3. 能力自检（L3+）：读文件、git status、跑测试 → 任一失败则报告 BLOCKED
4. 执行任务

**执行中**
1. 不改 FROZEN_SCOPE 里的任何东西
2. 不改 WRITE_LOCKS 里没分配给自己的文件
3. 不确定的事先问 Brain，不替用户拍板
4. 每完成一步，确认没有越界

**执行后**
1. 写 04-worker-report.md（按 §10.5 模板）
2. 写 03-evidence.md（证据链，可追溯）
3. 验证自检：
   - [ ] 每个修改都有对应的 AC？
   - [ ] 静态验证做过？
   - [ ] 测试跑过？
   - [ ] FROZEN_SCOPE 无触碰？
   - [ ] 自述改的内容磁盘上真的改了？
4. 设置 `WORKER_STATUS: DONE`，通知 Brain

### 11.3 Reviewer 检查表

收到 Worker 证据包后，在新会话中执行：

**前置条件**
- [ ] 是否在新会话/新 context window 启动？
  - 否 → 停止，输出 `NEEDS_INDEPENDENT_REVIEW`
- [ ] 工具链可用？(读目录、读文件、git diff、跑测试)
  - 否 → 停止，报告 BLOCKED，无法审

**审核步骤**

```
□ 范围检查（Scope）
  □ 读取 FROZEN_SCOPE（来自 01-task-classification）
  □ grep -nE "{FROZEN_SCOPE_glob}" 修改过的文件
    → 期望无匹配
  □ git diff --name-only → 只有 SCOPE 内的文件

□ 政策检查（Policy）
  □ 确认未安装/下载/删除/改配置（除非授权）
  □ 确认未触碰用户声明"不管"的内容

□ 技术检查（Technical）
  □ 修改是否解决了原始问题
  □ 有无明显 bug（边界、异常、NPE、SQL 注入等）
  □ 有无行为漂移（改了不该改的行为逻辑）

□ 验证检查（Verification）
  □ 静态验证：grep / diff / 文件核对
  □ 测试验证：跑测试命令
  □ 反恒真 grep（L2+ 必须）：
    - grep "view_functions" test_*.py → 期望空
    - grep "@app.route" 改过文件 → 检查重复
  □ 破坏实验（L3+ 必须）：
    - 备份核心函数 → 改为固定返回值 → 复跑测试
    - 期望：至少 1 个 FAIL，traceback 精确到元素位置
    - 还原 → 回归全部 PASS

□ 输出
  REVIEW_STATUS: PASS / FAIL / NEED_USER_DECISION
  Required Fixes（若 FAIL）：逐条文件:行号
```

---

## 12. 常见违规与标准处置

### 12.1 违规类型速查

| 违规 | 检测者 | 标准处置 |
|------|--------|---------|
| 没有计划就开干 | Brain / Gate | 立即停止，补计划，等确认 |
| 改了冻结范围外文件 | Reviewer | FAIL，还原修改，记 Required Fix |
| 改了 WRITE_LOCKS 外的文件 | Brain / Reviewer | FAIL，还原修改，记违规 |
| Worker 自述完成但磁盘没变 | Reviewer | FAIL，证据不够，补证据 |
| 测试恒真（view_functions 注入） | Reviewer | FAIL，重写测试，加反恒真断言 |
| 用户说"查一下"但执行者改了 | Gate / Reviewer | FAIL，还原，问用户是否授权 |
| 安装/下载/删除未授权 | Gate | 阻止，问用户 |
| Reviewer 和 Worker 同会话 | Reviewer 自查 | 输出 NEEDS_INDEPENDENT_REVIEW，拒绝代审 |
| Worker 能力自检失败 | Worker 自查 | 报告 BLOCKED，卸任交还 Brain |
| 多个合理方向需选择 | Brain | 输出 NEEDS_DECISION，等用户选 |

### 12.2 标准处置模板

**审核发现越界：**
```
VIOLATION: 修改了 FROZEN_SCOPE 内的 {文件}
ACTION: FAIL
REQUIRED_FIX: 还原 {文件} 到修改前版本
EVIDENCE: git diff 显示 {内容}
```

**审核发现测试恒真：**
```
VIOLATION: 测试套件通过 view_functions 注入绕过真实实现
ACTION: FAIL
REQUIRED_FIX: ① 删除所有 view_functions 赋值 ② 加纯函数断言
EVIDENCE: grep 结果 {内容}
```

**工具不可用：**
```
VIOLATION: Reviewer 无法读取 {文件/目录/命令}
ACTION: NEEDS_INDEPENDENT_REVIEW
REASON: 当前会话不具备必要工具能力
NEXT: 在新会话中重新审核，或由用户粘贴必要输出
```

### 12.3 用户不在线时的处理

| 情况 | 操作 |
|------|------|
| 需要确认计划 | 等，不可自行执行 |
| 需要确认高风险 | 等，不可默认继续 |
| 发现多个方向 | 选出最安全的方向暂存，不执行，等用户回复 |
| 审核 FAIL | 记下 Required Fixes，等用户确认后重试 |
| 非常明确的 bug（如数据丢失风险） | 停下，等用户 |

---

## 13. 案例库

### CASE-001：字段修复复审（L2）

**问题**：首个 `.agent-runs` 试跑记录使用了旧字段名 `SCOPE`/`FREEZE`，不符合标准字段 `AUTHORIZED_SCOPE`/`FROZEN_SCOPE`。
**修复**：只改字段名不改内容，提供修改后片段和精确计数。
**沉淀**：执行者声明已修复 ≠ 磁盘已修复；审核者以磁盘实际内容为准；字段级修复必须提供片段 + 计数。

### CASE-002：L2 文档修改记录复用

**问题**：已有记录目录满足本次任务要求，是否可复用。
**结果**：复用 PASS。说明未重复创建原因，审核者独立确认文件完整性。
**沉淀**：复用记录目录 ≠ 跳过审核；仍必须输出证据和审核结论。

### CASE-003：L3 审核因工具能力失效受阻

**问题**：L3 代码修改任务已完成，但审核者因工具不可用无法读取目录、git status、git diff、测试输出。
**结果**：`BLOCKED_BY_TOOLING`，`NEED_USER_DECISION`。
**沉淀**：新增"能力自检规则"——接 L3+ 任务前必须先通过只读命令自证工具可用。

### L3 清理：工作区垃圾文件清理

**类型**：高风险删除任务，需逐项确认 + 用户决策保留。
**目录**：`.agent-runs/2026-06-11-001-l3-workspace-cleanup/`

### L4 演练：自定义错误拦截 + fallback + 测试

**类型**：跨文件逻辑耦合任务全流程 PASS。
**目录**：`.agent-runs/2026-06-12-001-l4-error-interception/`

---

## 14. 项目状态

### 14.1 整体进度

| 阶段 | 状态 | 日期/说明 |
|------|------|------|
| 第一阶段（最小闭环） | **PASS** | 5 个案例验证 |
| 第二阶段（记录层） | **OPERATIONAL** | 已验证字段修复/文档复用/L3 清理/L4 演练 |
| v0.2-M1 协议升级 | **DONE** | 2026-06-12 |
| v0.2-M2 小型并发演练 | **PASS / FINALIZED** | 2026-06-12 |
| v0.2-L3 代码并发演练 | **PASS / FINALIZED** | 2026-06-13 |
| v0.2-M3 / 头条 L4 实战 | **进行中** | 自 2026-06-13 起持续推进，当前仍处于 PATCH 系列补丁阶段 |

### 14.2 已验证能力

- ✅ 最小闭环（协调者 → 执行者 → 审核者 → 交付）
- ✅ `.agent-runs` 记录层（00-request → 06-final 完整模板）
- ✅ 独立审核者只读复核闭环
- ✅ 跨文件修改任务的证据链追踪
- ✅ 能力自检工具链验证
- ✅ 字段级修复验收规则
- ✅ 配置驱动 + 代码逻辑的跨文件关联
- ✅ NOT_WIRED 交付口径（能力与生产接线分离）
- ✅ Brain Plan / Worker Task Card / WRITE_LOCKS / SWMR
- ✅ 双 Worker 并发零冲突
- ✅ 反恒真三条硬规则
- ✅ L4 头条实战硬规则三条

### 14.3 待办

1. Reviewer 外部化，形成独立可调用检查器
2. CLI 编排器落地，形成多模型/多进程/多 workspace 的正式调度层
3. 继续推进 v0.2-M3 / 头条 L4 实战补丁链，包括 PATCH6 / PATCH-BODY 相关问题收口
4. 如需在生产中启用 ClassifyRelayErrorWithConfig，接线到 relay 层

---

## 15. 后续演进方向

### 15.1 外部化路线

1. **审核者外部化**：独立可调用的检查器
2. **CLI 编排器**：多智能体调度 + 多模型调用 + git worktree 隔离 + 状态管理 + 审计日志 + 失败重试
3. **专业审核者**：正确性 / 安全 / 性能 / 风格 / 规则 拆分

### 15.2 全局规则沉淀原则

- CLAUDE.md / AGENTS.md 只记录稳定项目事实和长期规则
- 每次真实任务结束后，发现可复现的错误先总结成一条短规则
- 短规则需要用户确认后，再写入全局或项目级规则文件
- 完整复盘、背景和讨论过程保留在协议或任务记录中

---

## 附录：文件索引

| 内容 | 路径 |
|------|------|
| **本文件（主文档）** | `agent-team-rules.md`（仓库根目录） |
| Claude Code 适配器 | `adapters/claude/CLAUDE.md` |
| 任务模板 | `templates/00-request.md` ~ `06-handoff.md` |
| 自检脚本 | `scripts/self-check.sh` |
| 任务记录目录 | `<project-root>/.agent-runs/` |

---

## 16. 工具与自动化

### 16.1 反恒真 grep 命令集

Reviewer 执行反恒真检查时，直接复制粘贴以下命令：

```bash
# [Basic] 检查 test_*.py 中是否通过 view_functions 绕过（预期：exit 1 = 无匹配）
grep -nE "view_functions" test_*.py

# [Extended] 检查是否绕过了 view 装饰器（预期：exit 1）
grep -nE "_patch_view|_rate_limited_view|wrapped_view" test_*.py

# [Route duplication] 检查是否存在重复路由（预期：exit 1）
grep -nE "@app\.route" modified_app.py | awk -F"'" '{print $2}' | sort | uniq -d

# [Full sweep] 单条合并所有检查
echo "=== 1/3: 真实函数引用 ===" && grep -nE "view_functions" test_*.py && echo "FAIL" || echo "PASS" && echo "=== 2/3: 装饰器绕过 ===" && grep -nE "_patch_view|_rate_limited_view|wrapped_view" test_*.py && echo "FAIL" || echo "PASS" && echo "=== 3/3: 重复路由 ===" && (grep -nE "@app\.route" modified_app.py 2>/dev/null | awk -F"'" '{print $2}' | sort | uniq -d) && echo "FAIL" || echo "PASS"
```

### 16.2 破坏实验模板脚本

```bash
# ===== 破坏实验：改坏实现 → 测试须 FAIL → 还原 =====
FILE="[要修改的文件路径]"          # 例：app.py
FUNC="[要破坏的函数名]"            # 例：is_rate_limited
RETURN="[固定返回值]"              # 例：True
TEST_CMD="python -m unittest [模块] -v"

# Step 1: 备份
cp "$FILE" "$FILE.bak"

# Step 2: 手动修改 ${FILE} 中 ${FUNC} 的 return 值为 "${RETURN}"

# Step 3: 运行测试（预期：至少 1 个 FAIL）
echo "=== [Step 3] 破坏后测试 ===" && $TEST_CMD 2>&1 | tail -20

# Step 4: 恢复
cp "$FILE.bak" "$FILE"

# Step 5: 回归测试（预期：全部 PASS）
echo "=== [Step 5] 恢复后回归 ===" && $TEST_CMD 2>&1 | tail -10

# Step 6: 清理
rm "$FILE.bak"
echo "=== [Step 6] 清理完成 ==="
```

### 16.3 能力自检命令

```bash
# 单行自检：目录/文件/git/测试
echo "=== Dir ===" && ls .agent-runs/ && echo "=== File ===" && head -3 00-request.md && echo "=== Git ===" && git status --short && echo "=== Diff ===" && git diff --name-only && echo "=== Test ===" && python -m pytest -x -q 2>/dev/null || go test ./... 2>/dev/null || echo "No test"
```

| 段 | 成功标志 | 失败含义 |
|:--|:--|:--|
| Dir | 列出 `.agent-runs/` | 目录未初始化 |
| File | 显示文件前 3 行 | 请求文件缺失 |
| Git | 显示变更（或空） | 不在 git repo |
| Diff | 显示修改文件名 | 无未暂存变更 |
| Test | 测试通过 / "No test" | 测试失败 |

### 16.4 .agent-runs 目录初始化

```bash
# 创建标准目录结构 + 空白模板
mkdir -p .agent-runs/00-request ..trash

cat > .agent-runs/00-request.md << 'EOF'
TASK_ID:
TASK_TITLE:
RISK_LEVEL:
ORIGINAL_REQUEST:
EOF

cat > .agent-runs/01-task-classification.md << 'EOF'
TASK_TYPE:
SCOPE:
FROZEN_SCOPE:
EOF

echo "=== 已初始化 ===" && ls -R .agent-runs/
```

### 16.5 完整一键自检脚本

```bash
#!/bin/bash
# Agent 完整自检 — 磁盘/文件/Git/测试/反恒真
P="[PASS]"; F="[FAIL]"; t=0; p=0
check() { t=$((t+1)); if "$@" >/dev/null 2>&1; then echo -e "\033[32m$P\033[0m $1"; p=$((p+1)); else echo -e "\033[31m$F\033[0m $1"; fi; }

echo "=== 基础能力 ==="
check "目录可读"     ls .agent-runs/
check "请求文件存在" test -f .agent-runs/00-request.md
check "Git repo"     git rev-parse --git-dir
check "Python"       python3 --version

echo "=== Git 状态 ==="
check "工作树干净"   git diff --quiet
check "暂存区干净"   git diff --cached --quiet

echo "=== 测试 ==="
if ls test_*.py 2>/dev/null | head -1 >/dev/null 2>&1; then check "测试通过" python -m pytest -x -q
elif ls *_test.go 2>/dev/null | head -1 >/dev/null 2>&1; then check "Go测试" go test ./... -count=1
else echo "  跳过（无测试文件）"; fi

echo "=== 反恒真 ==="
check "无 view_functions 注入" grep -nE "view_functions" test_*.py
check "未绕过装饰器"          grep -nE "_patch_view|_rate_limited_view" test_*.py

echo "" && echo "  $p / $t 通过"
```

保存为 `.agent-runs/self-check.sh`，每次 Review 前执行：`bash .agent-runs/self-check.sh`

---

## 17. 快速上手

### 17.1 给 Brain：10 秒判断任务等级

```
用户说"看看/查一下/聊聊" → L1 只读 → 直接查，不用问
用户说"改个小东西" → L2 → 先计划，等确认，做，审
用户说"实现/重构/加功能" → L3 → Superpowers 完整流 → 必须 Reviewer
用户说"删除/部署/迁移/改系统" → L4 → Superpowers 完整流 → 逐项确认风险
```

**L3/L4 Superpowers 固定触发**：Brain 分类为 L3/L4 后，强制调 `/brainstorming` → `/writing-plans`，走完设计文档 + 实施计划再进 Worker 执行。L1/L2 不触发。

### 17.2 最简模板（三字段就够了）

```
## SCOPE
要做什么，一句话。

## FROZEN_SCOPE
绝对不能碰的文件/模块列表。没有就写"无"。

## ACCEPTANCE_CRITERIA
- [ ] 做完的标准 1
- [ ] 做完的标准 2
```

其他字段对小型任务可全部省略。Brain 写完这三个字段直接进入下一步，不要过度规划。

### 17.3 Worker 速查：执行前/中/后三道门

**执行前（30 秒自检）：**
1. 读 FROZEN_SCOPE — 标记为冻结的文件一律不改
2. 读 SCOPE — 确认"做什么"和"不做什么"
3. 能力自检 — 需要的工具/权限都有吗？没有就喊 Brain

**执行中：**
1. 只改自己 Lock 范围内的文件
2. 不改冻结区任何内容
3. 不做 SCOPE 之外的事

**执行后：**
1. 证据链 — 留下可复现的产出：diff / 测试输出 / 截图 / 日志
2. 自检清单 — 逐条过 ACCEPTANCE_CRITERIA，每条对应一条证据
3. 标注风险 — 有 TODO、已知缺陷、不确定的地方必须写明

### 17.4 Reviewer 速查：三步过审

1. **Scope 审查**：grep 冻结范围文件，确认 Worker 没动过 → 期望输出为空
2. **Policy 审查**：确认 Worker 没越权（没删文件、没改配置、没碰冻结范围）
3. **Verification 审查**：跑测试 → 反恒真 grep → 破坏实验（L3+）

---

## 18. 真实对话示例

> 本章展示 Brain/Worker/Reviewer 三角色协作在完整 L2 任务中的实际操作流程。
> 任务：把 README.md 里的端口号从 3000 改成 8080。

### 18.1 用户请求

```
cct: 帮我把 README.md 里的端口号从 3000 改成 8080
```

### 18.2 Brain 处理

**第一步：任务分类**

```markdown
TASK_TYPE: L2
TASK_MODE: FILE_MODIFY
RISK_LEVEL: L2

WHY_THIS_CLASSIFICATION:
- 单文件修改，无架构变更
- 改动量小（一行字符串替换）
- 不涉及数据库、部署、删除

SCOPE:
- 允许读取：README.md
- 允许修改：README.md

FROZEN_SCOPE:
- 其他所有文件一概不动

REQUIRES_USER_APPROVAL: YES
REQUIRES_REVIEWER: YES (建议)
```

**第二步：写 02-plan**

```markdown
TASK_SUMMARY:
- 把 README.md 中的端口号从 3000 改为 8080

SCOPE:
- README.md（单文件）

FROZEN_SCOPE:
- **/*（README.md 之外的一切文件）

WRITE_LOCKS:
- README.md → Worker

PLAN:
1. Worker：读取 README.md，确认上下文
2. Worker：把 "3000"（端口语境下）替换为 "8080"
3. Worker：grep 确认旧端口消失、新端口存在
4. Worker：输出证据包
5. Reviewer：只读审核
6. 交付者：汇总

NON_GOALS:
- 不修改其他任何文件
- 不启动服务、不安装依赖

ACCEPTANCE_CRITERIA:
- README.md 不再出现端口 3000
- README.md 出现端口 8080
- 其他文件零修改

VERIFICATION_PLAN:
- grep "3000" README.md → 0 匹配
- grep "8080" README.md → 至少 1 匹配
- git diff --name-only → 只有 README.md
```

**第三步：向用户确认**

```
Brain > cct：计划如下——
  修改文件：README.md（仅此一个）
  改动内容："3000" → "8080"（端口相关上下文）
  冻结范围：其他所有文件概不动
  审核方式：独立 Reviewer 审核后交付

 是否确认执行？
```

### 18.3 Worker 执行

**Worker Task Card**

```markdown
TASK_ID: v0.2-2026-0618-L2-port-change-W1
ASSIGNED_BY: Brain
MODE: EXECUTE
SCOPE:
- 允许读取：README.md
- 允许修改：README.md
WRITE_LOCKS:
- README.md → Worker W1
FROZEN_SCOPE:
- **/* (README.md 以外的文件)
ACCEPTANCE_CRITERIA:
- README.md 中端口 3000 → 8080
- 其他文件零修改
VERIFICATION_PLAN:
1. grep "3000" README.md → 确认旧值存在
2. sed 替换或手动编辑
3. grep "8080" README.md → 确认新值存在
4. git diff --name-only → 只有 README.md
```

**Worker 实际执行**

```
Worker > 读取 README.md...
# My Project
## Getting Started
1. Start the server: `node server.js --port 3000`
2. Open http://localhost:3000
The default port is 3000.
| port | 3000 | HTTP server port |

Worker > 确认上下文：3000 出现 3 次，均为端口号相关。
Worker > 执行替换：3000 → 8080
```

**Worker 写出 03-evidence.md**

```markdown
FACTS_VERIFIED:
- README.md 中 "3000" 出现 3 次，均在端口号上下文中
- 无其他文件需要修改

COMMANDS_RUN:
- grep -n "3000" README.md
- sed -i 's/3000/8080/g' README.md
- grep -n "8080" README.md
- git diff --name-only
```

**Worker 写出 04-worker-report.md**

```markdown
TASK_SUMMARY:
- 把 README.md 中的端口号从 3000 改为 8080

CHANGES_MADE:
- README.md：3 处 "3000" → "8080"

FILES_CHANGED:
- README.md（仅此一个）

VERIFICATION:
- 静态验证 ✅：grep "3000" README.md → 0 匹配
- 静态验证 ✅：grep "8080" README.md → 3 匹配
- 范围检查 ✅：git diff --name-only → 只输出 README.md

WORKER_STATUS: DONE
```

### 18.4 Reviewer 审核

Reviewer 在新会话（独立 context window）中开始只读审核：

```
Reviewer > 读取 00-request.md ✓
Reviewer > 读取 01-task-classification.md ✓
Reviewer > 读取 02-plan.md ✓
Reviewer > 读取 03-evidence.md ✓
Reviewer > 读取 04-worker-report.md ✓

Reviewer > git diff --name-only → README.md ✅
Reviewer > grep -n "3000" README.md → exit 1 ✅
Reviewer > grep -n "8080" README.md → 第 7/8/10/18 行 ✅
Reviewer > git status --short → M README.md ✅
```

**Reviewer 写出 05-review.md**

```markdown
REVIEW_STATUS: PASS

Scope Check ✅:
- git diff --name-only → 只有 README.md (计划内文件)

Policy Check ✅:
- Brain 出计划 → 用户确认后才执行
- Worker 严格按 Task Card 执行，未扩大范围

Technical Check ✅:
- 修改正确：3000 → 8080，共 4 处
- 全部是端口号上下文，无误替换

Verification Check ✅:
- grep "3000" README.md → exit 1（0 匹配）
- grep "8080" README.md → 4 匹配
- 验证数据可复现，非"执行者说"

Required Fixes: 无
```

### 18.5 交付

**交付者写出 06-final.md**

```markdown
TASK_RESULT: PASS

WHAT_WAS_DONE:
- README.md 中端口号从 3000 改为 8080（共 4 处）

FILES_CHANGED:
- README.md

FILES_NOT_TOUCHED:
- 冻结范围内的所有其他文件未被触碰

REVIEW_RESULT:
- REVIEW_STATUS: PASS

RISKS_OR_UNDONE: 无
```

```
Brain > cct：任务完成。
  - README.md 中所有 3000 → 8080（4 处）
  - 冻结范围零污染
  - Reviewer 独立审核 PASS
  - 可直接使用新端口启动服务。
```

### 18.6 关键路径总结

| 阶段 | 检查点 | 通过标志 |
|------|--------|---------|
| Brain 分类 | 等级判断正确 | L2（单文件小改） |
| Brain 计划 | 用户确认 | cct: "确认" |
| Worker 执行 | 只改计划内文件 | git diff --name-only = README.md |
| Worker 验证 | 旧值消失 + 新值出现 | grep 3000=0, grep 8080=4 |
| Reviewer 审核 | 独立会话 + 全 PASS | REVIEW_STATUS: PASS |
| 交付汇总 | 无遗漏、无风险 | 正常结束 |

---

## 19. 最新进度同步（2026-06-19 ~ 2026-06-20）

### 19.1 协议版本状态

- `agent-team-protocol/agent-team-rules.md` 当前定版为 **v0.2.8**
- 截止 **2026-06-24**，最近版本演进如下：
  - `v0.2.5`：加入反恒真硬规则 + L4 头条实战规则
  - `v0.2.6`：加入 L4 检核条件扩展、Reviewer 硬门槛、能力自检加塞、ponytail 冲突处理
  - `v0.2.7`：加入并发执行规则，包括 `Merge Owner`、`ATP 并发模式`、`02-plan` 并发计划段
  - `v0.2.8`：清理本地路径、更新至公开仓库版本

### 19.2 项目阶段状态

根据本文件前文记录，当前阶段状态应更新为：

| 阶段 | 状态 | 说明 |
|------|------|------|
| 第一阶段（最小闭环） | PASS | 已完成并验证 |
| 第二阶段（记录层） | OPERATIONAL | `.agent-runs` 与任务记录已形成稳定形态 |
| v0.2-M1 协议升级 | DONE | 已完成 |
| v0.2-M2 小型并发演练 | PASS / FINALIZED | 已闭环 |
| v0.2-L3 代码并发演练 | PASS / FINALIZED | 已闭环 |
| v0.2-M3 / 头条 L4 实战 | 进行中 | 仍处于 PATCH 系列补丁推进阶段 |

### 19.3 当前未完成项

截至 **2026-06-20**，协议体系本身不是“未设计完”，而是“已设计并部分实战，尚未完全平台化”。当前主要未完成项：

1. Reviewer 外部化仍未完成，尚未形成独立可调用检查器
2. CLI 编排器仍未落地，尚未形成多模型/多进程/多 workspace 的正式调度层
3. 头条 L4 实战链路仍有补丁任务在推进，协议仍在借真实任务继续沉淀规则

### 19.4 头条 L4 实战的最新真实状态

头条 L4 实战补丁链为协议规则的主要实战验证来源。当前状态：
- `toutiao_article_publish.py` 当前为 **已解冻**（允许继续处理封面上传及正文改进）
- 以下文件仍属于冻结范围：`toutiao_article_publish_utils.py`、`app.py`、`toutiao_publish.py`、`test_*.py`、`diagnose_publish.py`、`~/.toutiao_profile/**`、`.agent-runs/{历史任务}/**`

**当前真实活跃主线仍然是头条 L4 实战补丁链，而不是新的协议主线开发。**

### 19.5 本轮新增经验

2026-06-20 补充一条实践规则：

- 遇到中文文件读取乱码时，不能直接把当前输出当成真实内容
- 必须至少切换一种读取方式复核后再判断
- 推荐顺序：
  1. `chcp 65001` 后用 `Get-Content -Encoding utf8`
  2. `python -X utf8 -c "open(..., encoding='utf-8').read()"`
  3. 仍异常时再判断是否为 `GBK`、`UTF-8 with BOM` 或文件损坏

---

## 20. 与全局 AGENTS.md 的区别

### 20.1 全局 AGENTS.md

这是 **全局运行规则文件**，作用范围是整个工作空间。它的职责是：

- 约束 Agent 的通用行为
- 定义审批、只读模式、Scope Freeze、风险等级等全局规则
- 补充在当前机器和当前工作区下长期有效的执行习惯

它偏向”**操作系统级 / 工作区级 / Agent 行为级规则**”。

### 20.2 agent-team-rules.md（本文件）

这是 **协议主文档**，作用范围是 Agent Team 协议项目本身。它的职责是：

- 记录 Agent Team 的理论基础
- 沉淀协议设计、案例、状态演进和任务方法
- 作为该项目自己的”设计文档 + 演进日志 + 案例库主文档”

它偏向”**项目协议本体**”，不是全局执行入口。

### 20.3 关系

可以把两者理解成：

- `AGENTS.md`：外层宪法，管”这个 Agent 在整个工作区怎么做事”
- `agent-team-rules.md`：内层项目主文档，管”Agent Team 这个项目本身发展到了哪一步、怎么定义自己”

前者更偏执行约束，后者更偏项目知识与协议沉淀。两者有关联，但不等价，也不应相互替代。
