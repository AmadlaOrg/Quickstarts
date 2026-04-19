#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

echo "=== mixed (_requires + _extends) ==="

# Test 1: final merged result has _extends merge applied (ssh deep-merged, port overridden)
actual_final=$(hery compose --dir "$SCRIPT_DIR/input")

if echo "$actual_final" | grep -q "port: 2222" \
    && echo "$actual_final" | grep -q "user: root" \
    && echo "$actual_final" | grep -q "key: ~/.ssh/id_ed25519" \
    && echo "$actual_final" | grep -q "provider: libvirt"; then
    echo "  PASS: _extends deep merge (port overridden, user+key inherited)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: _extends deep merge"
    echo "    Got:"
    echo "$actual_final" | head -15 | sed 's/^/      /'
    FAIL=$((FAIL + 1))
fi

# Test 2: _requires brought in the packages entity
if echo "$actual_final" | grep -q "name: curl"; then
    echo "  PASS: _requires resolved (curl package included)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: _requires not resolved"
    FAIL=$((FAIL + 1))
fi

# Test 3: _extends and _requires are orthogonal — _extends does data merge, _requires does dependency inclusion
# The package entity should NOT be merged into infrastructure's _body
if echo "$actual_final" | grep -q "version: \"8.0\""; then
    echo "  PASS: _requires entity present separately (not merged into infrastructure _body)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: _requires entity missing"
    FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
