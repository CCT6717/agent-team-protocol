# Agent Team Protocol v0.2.7 — Claude Code Adapter

## CORE RULES

1. Classify every task L0-L4 before implementation.
2. Do not change files outside scope without asking.
3. **Brain → Worker → Reviewer** role separation. L4 Reviewer must be a new session.
4. Tests must verify real behavior, not mocks or bypassed routes.
5. A test is not trusted until it fails when the implementation is intentionally broken.
6. Never weaken tests just to make them pass.
7. Report all skipped checks and unverified claims.

## REQUIRED WORKFLOW (L3-L4)

```
Brain → Worker(s) → [Merge Owner if concurrent] → Reviewer → Sabotage → Handoff
```

1. Fill 00-request.md, 01-level.md, 02-plan.md in task folder.
2. Wait for human approval before editing code.
3. Implement as Worker (may split into parallel sub-agents).
4. Review as Reviewer — **test green ≠ review pass, Reviewer is mandatory**.
5. Run sabotage verification on critical logic.
6. Write 06-handoff.md with changed files, tests run, remaining risks.

## CONCURRENT EXECUTION

When the user says "parallel mode" or "并发跑":

- ✅ Workers may run concurrently with bounded scopes.
- ✅ Merge Owner consolidates results before handing off to Reviewer.
- ❌ Never waives classification, planning, review, or sabotage.
- ❌ Never use concurrency as an excuse to skip gates.

Merge Owner is a temporary role that collects sub-agent outputs, resolves conflicts, checks cross-dependencies, and produces a merged diff for Reviewer.

## REVIEW GATE (hard rule)

- **Reviewer is a mandatory stage**, not an option.
- Worker-done → Reviewer-review (L3 same session, L4 new session).
- L4: config structure changes, breaking backward compatibility — must be classified as L4.
- Self-check between plan approval and coding: git status → git diff → go build → confirm toolchain.

## TEST INTEGRITY

- Prefer direct calls to core logic over HTTP wrappers.
- Do not bypass the real code path under test.
- Do not inject fake handlers or routes to make tests pass.
- If a test still passes after the implementation is broken, rewrite the test.
- H4 pure-function assertion chain (N+1 calls, sequence assert with element-level traceback).
- Reviewer must run sabotage experiment: break implementation → test FAILs → restore → regression PASS.
