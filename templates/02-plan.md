TASK_SUMMARY:
- Task objective

FILES_TO_READ:
- Files/dirs to read first

FILES_TO_CHANGE:
- Files to modify, with rationale per change

NON_GOALS:
- Explicitly excluded work (prevents scope drift)

WRITE_LOCKS:
- path/glob → Worker {name}

VERIFICATION_PLAN:
- Static: grep/diff/file checks
- Test: specific test commands
- Runtime: launch checks (if applicable)

ACCEPTANCE_CRITERIA:
- {condition} → PASS
- {condition} → FAIL
- {condition} → NEED_USER_DECISION

---

## Parallel Execution Plan (if applicable)

是否请求并发：是 / 否

| 子 Agent | 角色 | 范围 | 允许修改路径 | 禁止修改路径 | 预期产出 |
|----------|------|------|-------------|-------------|---------|
| Worker A | | | | | |
| Worker B | | | | | |
| Worker C | | | | | |

**Merge Owner**: [Brain / Worker name]

并发规则：
- 每个 Worker 只能处理自己声明范围内的文件
- 每个 Worker 必须报告改了什么文件 + 跑了哪些测试 + 测试结果
- Worker 不得自审自己的产出
- Merge Owner 汇总后交 Reviewer 审查合并结果，不只看单 Worker 交付
