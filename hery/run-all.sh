#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

for test_dir in \
    "$SCRIPT_DIR/single-entity" \
    "$SCRIPT_DIR/local-entity" \
    "$SCRIPT_DIR/extends-local" \
    "$SCRIPT_DIR/two-layers" \
    "$SCRIPT_DIR/three-layers" \
    "$SCRIPT_DIR/extends-external" \
    "$SCRIPT_DIR/mixed"; do

    name=$(basename "$test_dir")
    if [[ -x "$test_dir/test.sh" ]]; then
        echo ""
        if "$test_dir/test.sh"; then
            echo "  >> $name: PASS"
            TOTAL_PASS=$((TOTAL_PASS + 1))
        else
            echo "  >> $name: FAIL"
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
    else
        echo "  >> $name: SKIP (no test.sh)"
    fi
done

echo ""
echo "=============================="
echo "HERY E2E: $TOTAL_PASS passed, $TOTAL_FAIL failed"
[[ $TOTAL_FAIL -eq 0 ]]
