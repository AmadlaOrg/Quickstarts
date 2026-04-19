#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== extends-external ==="

# Test 1: layer 1 — child with _extends merged from external parent
actual_l1=$(hery compose --dir "$SCRIPT_DIR/input" --layer 1)
expected_l1=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual_l1" == "$expected_l1" ]]; then
    echo "  PASS: layer 1 (child inherits external parent, overrides logging.path)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 1"
    diff <(echo "$expected_l1") <(echo "$actual_l1") | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 2: layer 2 — the external parent entity is cached
actual_l2=$(hery compose --dir "$SCRIPT_DIR/input" --layer 2)
expected_l2=$(cat "$SCRIPT_DIR/expected/layer-2.yaml")

if [[ "$actual_l2" == "$expected_l2" ]]; then
    echo "  PASS: layer 2 (external parent cached)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 2"
    diff <(echo "$expected_l2") <(echo "$actual_l2") | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 3: deep merge — child overrides logging.path but keeps logging.enabled from parent
actual_final=$(hery compose --dir "$SCRIPT_DIR/input")
if echo "$actual_final" | grep -q "path: /var/log/nginx" \
    && echo "$actual_final" | grep -q "enabled: true" \
    && echo "$actual_final" | grep -q "user: www-data"; then
    echo "  PASS: deep merge correct (child overrides path, inherits enabled + runtime)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: deep merge"
    echo "    Got:"
    echo "$actual_final" | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
