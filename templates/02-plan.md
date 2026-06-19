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
