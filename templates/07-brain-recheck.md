TRIGGER:
- Reviewer verdict: FAIL
- Required Fixes list

BRAIN_RECHECK:

1. REQUIRED_FIXES_REVIEW:
   - Fix 1: {description} → {agree / revise / reject + rationale}
   - Fix 2: {same}

2. PLAN_UPDATE:
   - Plan needs rewrite: {YES/NO + rationale}
   - SCOPE/FROZEN_SCOPE adjustment needed: {YES/NO}
   - RISK_LEVEL upgrade needed: {YES/NO}

3. WORKER_REASSIGNMENT:
   - Same Worker continues: {YES/NO + rationale}
   - New Worker assigned: {name + rationale}
   - WRITE_LOCKS changed: {YES/NO}

4. RE_REVIEW_REQUIREMENT:
   - Needs original Reviewer: {YES/NO}
   - Needs new Reviewer: {YES/NO}

BRAIN_VERDICT: PROCEED | REJECT | NEED_USER_DECISION

PROCEED → Worker fixes → re-enter REVIEWING
REJECT → cancel task, archive as CANCELLED
NEED_USER_DECISION → escalate to human
