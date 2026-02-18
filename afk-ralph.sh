#!/bin/bash
# afk-ralph.sh — Run Ralph in autonomous loop (AFK mode)
#
# Generic template script. For MindSage, use ../ralph.sh instead.
#
# Usage: ./afk-ralph.sh <iterations> <project-dir>
#
# Example:
#   ./afk-ralph.sh 10 /path/to/my-project

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <iterations> <project-dir>"
    echo "  Example: $0 10 /path/to/my-project"
    exit 1
fi

MAX_ITER="$1"
WORK_DIR="$(cd "$2" && pwd)"
LOG_FILE="$WORK_DIR/ralph-log-$(date +%Y%m%d-%H%M%S).txt"

cd "$WORK_DIR"

for f in prd.md prompt.md northstar.md features.json; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: $f not found in $WORK_DIR"
        exit 1
    fi
done

touch claude-progress.txt

echo "=== AFK Ralph: $MAX_ITER iterations in $WORK_DIR ===" | tee "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

for ((i=1; i<=MAX_ITER; i++)); do
    echo "--- Iteration $i/$MAX_ITER ($(date)) ---" | tee -a "$LOG_FILE"

    result=$(CLAUDECODE="" claude \
        --permission-mode acceptEdits \
        -p \
        "@northstar.md @prd.md @features.json @claude-progress.txt $(cat prompt.md)" \
        2>&1) || true

    echo "$result" >> "$LOG_FILE"

    if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== ALL FEATURES COMPLETE after $i iterations ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"
        exit 0
    fi

    echo "Iteration $i done." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
done

echo "=== Reached max iterations ($MAX_ITER) ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
