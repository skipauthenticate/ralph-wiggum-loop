#!/bin/bash
# ralph-once.sh — Run one Ralph iteration (Human-in-the-Loop)
#
# Generic template script. For MindSage, use ../ralph.sh instead.
#
# Usage: ./ralph-once.sh <project-dir>
#   project-dir: path to directory containing prd.md, features.json, etc.
#
# Example:
#   ./ralph-once.sh /path/to/my-project

set -euo pipefail

if [[ -z "${1:-}" ]]; then
    echo "Usage: $0 <project-dir>"
    echo "  project-dir: path containing prd.md, features.json, northstar.md, prompt.md"
    exit 1
fi

WORK_DIR="$(cd "$1" && pwd)"
cd "$WORK_DIR"

# Validate required files
for f in prd.md prompt.md northstar.md features.json; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: $f not found in $WORK_DIR"
        echo "Create it first (see ralph-guide.md)"
        exit 1
    fi
done

# Create progress file if missing
touch claude-progress.txt

echo "=== Ralph HITL: $WORK_DIR ==="
echo "Started: $(date)"

CLAUDECODE="" claude \
    --permission-mode acceptEdits \
    -p \
    "@northstar.md @prd.md @features.json @claude-progress.txt $(cat prompt.md)"

echo ""
echo "=== Ralph iteration complete ($(date)) ==="
