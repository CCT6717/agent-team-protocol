# Claude Code 适配器 — Agent Team Protocol

> 将以下内容追加到你的 CLAUDE.md 即可激活协议。

## Agent Team 协作（v0.2.8）

### 阈值规则

| 等级 | 场景 | 操作 | Superpowers |
|:----|:----|:----|:----:|
| L1 | 纯问问题、只读查询、代码库解释 | 直接回答/查 | ❌ |
| L2 | 小改：改一行配置、修错别字、简单改动 | 直接做，说一声 | ❌ |
| L3 | 改代码逻辑、加功能、重构、涉及多个文件 | `/brainstorming` → `/writing-plans` → Worker→Reviewer | ✅ |
| L4 | 删东西、改系统、发请求、部署、配置结构/格式变更、破坏现存数据/配置兼容性 | `/brainstorming` → `/writing-plans` → 逐项确认风险 → 全链路 Brain→Worker(s)→Reviewer→交付 | ✅ |

### L3/L4 完整链路

```
/brainstorming → 用户审核设计 → /writing-plans → 02-plan → 用户确认 → Worker → Reviewer → 交付
```

### 角色

- **Brain** → **Worker(s)** → **Merge Owner** → **Reviewer** → 交付
- **并发**：「并发跑」只授权 Worker 并行，不豁免分级/审查/验收
- **Reviewer**：L3 同会话切换视角；L4 必须手动开新会话

### 操作红线

- 未授权不得修改 AGENTS.md、删除文件、运行 Docker
- 范围冻结到字段级

详细规则见 `agent-team-rules.md`