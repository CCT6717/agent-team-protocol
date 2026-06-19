#!/bin/bash
# Agent Team Protocol — self-check script
# Run before every Review phase. All checks must pass.
P="[PASS]"; F="[FAIL]"; t=0; p=0
check() { t=$((t+1)); if "$@" >/dev/null 2>&1; then echo -e "\033[32m$P\033[0m $1"; p=$((p+1)); else echo -e "\033[31m$F\033[0m $1"; fi; }

echo "=== Capabilities ==="
check "Dir readable"         ls .agent-runs/ 2>/dev/null
check "Request file exists"  test -f .agent-runs/00-request.md
check "Git repo"             git rev-parse --git-dir
check "Python"               python3 --version

echo "=== Git Status ==="
check "Working tree clean"   git diff --quiet
check "Staging area clean"   git diff --cached --quiet

echo "=== Tests ==="
if ls test_*.py 2>/dev/null | head -1 >/dev/null 2>&1; then check "Tests pass" python -m pytest -x -q
elif ls *_test.go 2>/dev/null | head -1 >/dev/null 2>&1; then check "Go tests" go test ./... -count=1
else echo "  Skip (no test files)"; fi

echo "=== Sabotage-Verified ==="
check "No view_functions injection"  grep -nE "view_functions" test_*.py 2>/dev/null
check "No route bypass"             grep -nE "_patch_view|_rate_limited_view" test_*.py 2>/dev/null

echo "" && echo "  $p / $t passed"
