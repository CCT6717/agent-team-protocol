#!/bin/bash
# Create a new ATP run folder with templates
# Usage: bash scripts/new-run.sh add-rate-limit

set -e

TASK_SLUG="${1:-untitled}"
DATE=$(date +%Y-%m-%d)
RUN_DIR=".agent-runs/${DATE}-001-${TASK_SLUG}"

# Count existing runs today to pick next number
EXISTING=$(ls -d .agent-runs/${DATE}-* 2>/dev/null | wc -l)
if [ "$EXISTING" -gt 0 ]; then
  LAST=$(ls -d .agent-runs/${DATE}-* 2>/dev/null | tail -1 | grep -oP '\d{3}(?=-)' || echo "001")
  NEXT=$((10#$LAST + 1))
  RUN_DIR=".agent-runs/${DATE}-$(printf '%03d' $NEXT)-${TASK_SLUG}"
fi

mkdir -p "$RUN_DIR"

# Copy templates (from repo templates/ or existing .agent-runs/templates/)
if [ -d "templates" ]; then
  cp templates/*.md "$RUN_DIR/"
elif [ -d ".agent-runs/templates" ]; then
  cp .agent-runs/templates/*.md "$RUN_DIR/"
else
  echo "Error: no templates/ directory found"
  exit 1
fi

echo "Created: $RUN_DIR"
ls "$RUN_DIR"
