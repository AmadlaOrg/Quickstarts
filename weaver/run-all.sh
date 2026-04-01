#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

for plugin_dir in "$SCRIPT_DIR"/weaver-*/; do
    plugin=$(basename "$plugin_dir")
    if [[ -x "$plugin_dir/test.sh" ]]; then
        echo ""
        if "$plugin_dir/test.sh"; then
            TOTAL_PASS=$((TOTAL_PASS + 1))
        else
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
    fi
done

echo ""
echo "=============================="
echo "All plugins: $TOTAL_PASS passed, $TOTAL_FAIL failed"
[[ $TOTAL_FAIL -eq 0 ]]
