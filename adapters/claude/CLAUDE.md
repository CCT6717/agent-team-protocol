# Agent Team Protocol v0.2.8 — Claude Code Adapter

> Full protocol rules: [`agent-team-rules.md`](../../agent-team-rules.md)

## Core Rules

1. Classify every task as L0-L4 before implementation.
2. Do not change files outside the declared task scope without asking.
3. Brain → Worker → Reviewer role separation.
4. SWMR: at most one Worker writes to any file at any time.
5. WRITE_LOCKS: all plans must declare file-level write locks per Worker.
6. Tests must verify real behavior, not mocks or bypassed routes.
7. A test is not trusted until it fails when the implementation is intentionally broken.
8. Never weaken tests just to make them pass.
9. Report all skipped checks and unverified claims.

## Required Workflow (L3-L4)

1. Fill 00-request.md, 01-level.md, 02-plan.md in the task folder.
2. 02-plan.md must include WRITE_LOCKS and FROZEN_SCOPE (glob format).
3. Wait for human approval before editing code.
4. Implement as Worker (only write locked files).
5. Review as Reviewer (read-only, independent session for L4).
6. Run sabotage verification on critical logic.
7. Write 06-handoff.md with changed files, tests run, and remaining risks.

## Test Integrity

- Prefer direct calls to core logic over HTTP wrappers.
- Do not bypass the real code path under test.
- Do not inject fake handlers or routes to make tests pass.
- If a test still passes after the implementation is broken, rewrite the test.
