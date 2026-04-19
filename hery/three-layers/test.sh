#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== three-layers ==="

# Test 1: layer 1 — the top-level includer (input/)
actual_l1=$(hery compose --dir "$SCRIPT_DIR/input" --layer 1)
expected_l1=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual_l1" == "$expected_l1" ]]; then
    echo "  PASS: layer 1 (top-level includer)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 1"
    diff <(echo "$expected_l1") <(echo "$actual_l1") | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 2: layer 2 — middle (layer-b/)
actual_l2=$(hery compose --dir "$SCRIPT_DIR/input" --layer 2)
expected_l2=$(cat "$SCRIPT_DIR/expected/layer-2.yaml")

if [[ "$actual_l2" == "$expected_l2" ]]; then
    echo "  PASS: layer 2 (middle — nginx app + service)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 2"
    diff <(echo "$expected_l2") <(echo "$actual_l2") | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 3: layer 3 — deepest (layer-a/)
actual_l3=$(hery compose --dir "$SCRIPT_DIR/input" --layer 3)
expected_l3=$(cat "$SCRIPT_DIR/expected/layer-3.yaml")

if [[ "$actual_l3" == "$expected_l3" ]]; then
    echo "  PASS: layer 3 (deepest — openssl package)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 3"
    diff <(echo "$expected_l3") <(echo "$actual_l3") | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 4: default returns final merged with all 3 layers
actual_final=$(hery compose --dir "$SCRIPT_DIR/input")
if echo "$actual_final" | grep -q "provider: libvirt" \
    && echo "$actual_final" | grep -q "name: nginx" \
    && echo "$actual_final" | grep -q "name: openssl"; then
    echo "  PASS: final merged result contains all 3 layers"
    PASS=$((PASS + 1))
else
    echo "  FAIL: final merged result"
    echo "    Got:"
    echo "$actual_final" | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
