#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== two-layers ==="

# Test 1: layer 1 (the includer directory) is cached correctly
actual_l1=$(hery compose --dir "$SCRIPT_DIR/input" --layer 1)
expected_l1=$(cat "$SCRIPT_DIR/expected/layer-1.yaml")

if [[ "$actual_l1" == "$expected_l1" ]]; then
    echo "  PASS: layer 1 (includer)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 1 (includer)"
    echo "    Expected:"
    echo "$expected_l1" | head -10 | sed 's/^/      /'
    echo "    Got:"
    echo "$actual_l1" | head -10 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 2: layer 2 (the included external directory) is cached correctly
actual_l2=$(hery compose --dir "$SCRIPT_DIR/input" --layer 2)
expected_l2=$(cat "$SCRIPT_DIR/expected/layer-2.yaml")

if [[ "$actual_l2" == "$expected_l2" ]]; then
    echo "  PASS: layer 2 (included external)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: layer 2 (included external)"
    echo "    Expected:"
    echo "$expected_l2" | head -10 | sed 's/^/      /'
    echo "    Got:"
    echo "$actual_l2" | head -10 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 3: default (no --layer) returns final merged result
actual_final=$(hery compose --dir "$SCRIPT_DIR/input")
# Final should contain both layers merged
if echo "$actual_final" | grep -q "provider: libvirt" && echo "$actual_final" | grep -q "distro: debian"; then
    echo "  PASS: final merged result contains both layers"
    PASS=$((PASS + 1))
else
    echo "  FAIL: final merged result"
    echo "    Got:"
    echo "$actual_final" | head -10 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
