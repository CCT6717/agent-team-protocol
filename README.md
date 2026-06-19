# Agent Team Protocol

Your AI agent wrote tests. They passed.
But did they actually test anything?

A lightweight workflow for AI coding agents with **sabotage-verified testing**.

> A test is not trusted until it fails when the implementation is intentionally broken.

Prevents three common failures when working with AI coding agents:

- **Scope drift** — the agent modifies files it shouldn't
- **Fake-green tests** — tests pass even when the code is broken
- **Unchecked autonomy** — the agent makes decisions without human oversight

## How It Works

### Risk Classification

Tasks are classified by risk level, which determines the workflow:

| Level | Scenario | Flow |
|-------|----------|------|
| L0 | Pure questions, no files touched | Answer directly |
| L1 | Read-only, lookups | Do it, no need to ask |
| L2 | Small changes (typo, one config line) | Do it, report what changed |
| L3 | Logic changes, multi-file, features | Plan → Confirm → Execute → Review |
| L4 | Deletions, deployments, high-risk | Full gate: Plan → Workers → Reviewer → Deliver |

L0-L2 are fast paths. L3-L4 trigger the full protocol.

### Three Roles

| Role | Job |
|------|-----|
| **Brain** | Categorizes the task, defines scope/frozen scope, creates the plan |
| **Worker(s)** | Execute within locked scope, produce evidence (diff, test output) |
| **Reviewer** | Audits scope, policy, and technical correctness; runs sabotage checks |

Workers run concurrently when possible. Reviewer isolation:
- L3: same-session perspective switch
- L4: **must** use a separate session (hard isolation)

### Task Record Structure

Each L3/L4 task creates a directory under `.agent-runs/`:

```
YYYY-MM-DD-NNN-task-slug/
├── 00-request.md              # Original request
├── 01-task-classification.md  # Risk level + scope
├── 02-plan.md                 # Execution plan (shown to human)
├── 03-evidence.md             # Evidence from execution
├── 04-worker-report.md        # Worker self-check
├── 05-review.md               # Reviewer verdict
├── 06-final.md                # Delivery summary
└── 07-brain-recheck.md        # (only when Reviewer FAILs)
```

## Sabotage-Verified Testing

The core differentiator. Three rules ensure tests are real, not tautologies:

### 1. Pure Call Rule (H4)

Call pure functions directly, N+1 times, with sequence assertions:

```python
# ✅ Direct call, sequential assertion
results = [is_rate_limited(ip) for ip in range(12)]
assert results == [False]*10 + [True, True]
# Traceback pinpoints element 10 on failure
```

### 2. No Bypass Rule

Never inject fake routes or mock the module under test.

```python
# ❌ Bypasses real routing — test can pass with broken code
flask_app.view_functions['rate_limit'] = lambda: "fake"

# ✅ No bypass — tests real code through real paths
```

### 3. Sabotage Check (Reviewer)

Reviewer intentionally breaks the implementation, then runs tests:

```
Step 1: cp app.py app.py.bak              # backup
Step 2: make is_rate_limited return False  # sabotage
Step 3: run tests → must FAIL              # if PASS, test is tautological
Step 4: cp app.py.bak app.py              # restore
Step 5: regression tests → all PASS
```

A test is real only if it fails when the code is wrong.

## Quick Start

1. **Judge the level** — L0-L2: go ahead. L3-L4: follow the protocol.
2. **Brain** — write `01-task-classification.md` + `02-plan.md`, show human
3. **Worker** — execute, write `03-evidence.md` + `04-worker-report.md`
4. **Reviewer** — run sabotage checks, write `05-review.md`
5. **Deliver** — summarize in `06-final.md`

See `templates/` for copy-paste ready templates. See `scripts/self-check.sh` for a one-shot verification script.

## License

MIT
