#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== single-entity ==="

# Test: hery resolves a single .hery file with no _requires or _extends
actual=$(hery compose --dir "$SCRIPT_DIR/input")
expected=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: single entity resolved"
    PASS=$((PASS + 1))
else
    echo "  FAIL: single entity resolved"
    echo "    Expected:"
    echo "$expected" | head -10 | sed 's/^/      /'
    echo "    Got:"
    echo "$actual" | head -10 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
