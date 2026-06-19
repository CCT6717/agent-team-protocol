REVIEW_INPUTS:
- request, plan, evidence, worker_report, git_status, git_diff, test_output

REVIEW_STATUS: PASS | FAIL | NEED_USER_DECISION

Scope Check:
- Only authorized files modified: {YES/NO + evidence}
- Frozen scope untouched: {YES/NO + evidence}

Policy Check:
- Plan approved before execution: {YES/NO}
- No unauthorized operations: {YES/NO + evidence}

Technical Check:
- Original problem solved: {YES/NO + rationale}
- No obvious bugs/risks: {YES/NO + file:line}

Verification Check (Sabotage-Verified):
- Static verification sufficient: {YES/NO}
- Tests are real (anti-tautology grep): {YES/NO + grep result}
- Sabotage experiment executed: {YES/NO + result}
- Unexecuted checks explained: {YES/NO}

Required Fixes:
1. {file:line} — {description}

Notes:
- Additional observations
