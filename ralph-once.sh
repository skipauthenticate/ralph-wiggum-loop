#!/bin/bash
# ralph-once.sh — Run one Ralph iteration (Human-in-the-Loop)
# Usage: ./ralph-once.sh [project-dir]
#   project-dir: optional subdirectory (e.g. "mindsage")

set -euo pipefail

PROJECT_DIR="${1:-.}"
WORK_DIR="/home/mindsage/workspace/mindsage-workspace/$PROJECT_DIR"
cd "$WORK_DIR"

# Validate required files
for f in prd.md prompt.md northstar.md; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f not found in $(pwd)"
    echo "Create it first (see ralph-guide.md)"
    exit 1
  fi
done

# Create progress file if missing
touch claude-progress.txt

echo "=== Ralph HITL: $(pwd) ==="
echo "Started: $(date)"

CLAUDECODE="" claude \
  --permission-mode acceptEdits \
  -p \
  "@northstar.md @prd.md @claude-progress.txt $(cat prompt.md)"

echo ""
echo "=== Ralph iteration complete ($(date)) ==="
