REVIEW_INPUTS:
- request, level, plan, implementation, git diff, test output

REVIEW_STATUS: PASS | FAIL | NEED_USER_DECISION

Scope Check:
- Only authorized files changed: {YES/NO + evidence}
- Frozen scope untouched: {YES/NO + evidence}

Policy Check:
- Plan approved before execution: {YES/NO}
- No unauthorized operations: {YES/NO + evidence}

Technical Check:
- Problem solved: {YES/NO + rationale}
- No obvious bugs: {YES/NO + file:line}

Verification Check:
- Static check sufficient: {YES/NO}
- Tests real (anti-tautology grep): {YES/NO + grep result}
- Sabotage experiment executed: {YES/NO + result}

Required Fixes:
1. {file:line} — {description}
