# Agent Team Protocol

Keep AI coding agents honest with copy-paste runbooks.

Use it when an AI agent is about to make a risky change: new feature, refactor, auth, payments, data migration, or production logic.

**No install. No framework. No service. Just Markdown templates and a verification script.**

---

## Quick Start

### 1. Copy the tools into your project

```bash
cp -r templates .agent-runs/templates
cp scripts/self-check.sh .agent-runs/self-check.sh
```

### 2. Create a run folder for your task

```bash
bash scripts/new-run.sh add-rate-limit
```

Or manually:

```bash
RUN=.agent-runs/$(date +%F)-001-add-rate-limit
mkdir -p "$RUN" && cp .agent-runs/templates/*.md "$RUN"/
```

### 3. Ask your AI agent

Copy this prompt:

```text
Use Agent Team Protocol for this task.

Create a new run folder under .agent-runs/ with the templates.

First fill:
- 00-request.md
- 01-level.md
- 02-plan.md

Do not edit source code until I approve the plan.

After implementation, fill the remaining files and run sabotage verification on critical logic.
```

### 4. Review

Before final sign-off:

```bash
bash .agent-runs/self-check.sh
```

---

## When to Use

| When | Probably Not Needed |
|------|-------------------|
| New feature, refactor, multi-file change | Typos, comments, formatting |
| Auth, payments, permissions, rate limits | Renaming a variable |
| Database migration | One-line config change |
| Logic where correctness matters | Read-only lookup |
| Writing or modifying tests | — |

---

## Templates

| File | Purpose |
|------|---------|
| `00-request.md` | Capture the original request and constraints |
| `01-level.md` | Classify risk level (L0-L4) |
| `02-plan.md` | Brain writes the execution plan |
| `03-implementation.md` | Worker records what changed and why |
| `04-review.md` | Reviewer checks scope, policy, and correctness |
| `05-sabotage.md` | Sabotage-verified testing log |
| `06-handoff.md` | Final delivery with tests run and risks noted |

---

## Sabotage-Verified Testing

> A test is not trusted until it fails when the implementation is intentionally broken.

Three rules:

1. **Pure Call Rule** — test business logic by calling it directly (not through HTTP wrappers). Call N+1 times and assert the sequence.
2. **No Bypass Rule** — never inject fake routes or mock the module under test.
3. **Sabotage Check** — Reviewer intentionally breaks the implementation, runs tests (must FAIL), restores, runs tests again (must PASS).

---

## How the run folder grows

```
.agent-runs/
  templates/                  # Your copy of the templates
  self-check.sh               # Reviewer pre-check script
  2026-06-19-001-add-rate-limit/
    00-request.md
    01-level.md
    02-plan.md
    03-implementation.md
    04-review.md
    05-sabotage.md
    06-handoff.md
  2026-06-18-002-fix-auth/
    ...
```

Each completed folder is an audit trail: what was planned, what was changed, how it was verified.

---

## Options

- `adapters/` — Tool-specific configs (see adapters/claude/CLAUDE.md for Claude Code)
- `examples/` — Filled examples coming when someone contributes one

---

## License

MIT
