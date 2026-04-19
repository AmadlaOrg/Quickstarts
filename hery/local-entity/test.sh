#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== local-entity ==="

# Test: hery resolves a directory of .hery files with _requires into one local entity (one layer)
actual=$(hery compose --dir "$SCRIPT_DIR/input")
expected=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: local entity with _requires resolved (5 files, 1 layer)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: local entity with _requires resolved"
    echo "    Expected:"
    echo "$expected" | head -10 | sed 's/^/      /'
    echo "    Got:"
    echo "$actual" | head -10 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
