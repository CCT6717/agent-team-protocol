REVIEW_INPUTS:
- request, level, plan, implementation, git diff, test output

REVIEW_STATUS: PASS | FAIL | NEED_USER_DECISION | NEEDS_INDEPENDENT_REVIEW

## Scope Check
- Only authorized files changed: {YES/NO + evidence}
- Frozen scope untouched: {YES/NO + grep evidence}

## Policy Check
- Plan approved before execution: {YES/NO}
- No unauthorized operations: {YES/NO + evidence}
- Review gate respected: Reviewer is a mandatory stage, not optional: {YES/NO}
- L4: classified correctly (config structure/format changes → L4): {YES/NO}

## Technical Check
- Problem solved: {YES/NO + rationale}
- No obvious bugs: {YES/NO + file:line}

## Verification Check
- Static check sufficient: {YES/NO}
- Tests real (anti-tautology):
  - H4 pure-function assertion chain: {YES/NO + file:line}
  - No view_functions/router injection: {YES/NO + grep result}
  - Sabotage experiment executed: {YES/NO + result}
- Evidence priority: PASS requires disk files / git diff / test output as proof: {YES/NO}

## Parallel Execution Check (if concurrent)
- Each Worker stayed within its declared scope: {YES/NO}
- Cross-dependency conflicts resolved: {YES/NO}
- Reviewer reviewed the merged result, not only individual outputs: {YES/NO}

## Required Fixes
1. {file:line} — {description}
