# Agent Team Protocol — Claude Code Adapter

## Core Rules

1. Classify every task as L0-L4 before implementation.
2. Do not change files outside the declared task scope without asking.
3. Brain → Worker → Reviewer role separation.
4. Tests must verify real behavior, not mocks or bypassed routes.
5. A test is not trusted until it fails when the implementation is intentionally broken.
6. Never weaken tests just to make them pass.
7. Report all skipped checks and unverified claims.

## Required Workflow (L3-L4)

1. Fill 00-request.md, 01-level.md, 02-plan.md in the task folder.
2. Wait for human approval before editing code.
3. Implement as Worker.
4. Review as Reviewer.
5. Run sabotage verification on critical logic.
6. Write 06-handoff.md with changed files, tests run, and remaining risks.

## Test Integrity

- Prefer direct calls to core logic over HTTP wrappers.
- Do not bypass the real code path under test.
- Do not inject fake handlers or routes to make tests pass.
- If a test still passes after the implementation is broken, rewrite the test.
