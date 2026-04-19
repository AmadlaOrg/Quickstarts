#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== extends-local ==="

# Test: _extends within same directory deep-merges parent _body into child
actual=$(hery compose --dir "$SCRIPT_DIR/input")
expected=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: _extends local merge (child inherits parent _body)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: _extends local merge"
    echo "    Expected:"
    echo "$expected" | head -15 | sed 's/^/      /'
    echo "    Got:"
    echo "$actual" | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
