#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="weaver-freemarker"
PASS=0
FAIL=0

# Resolve plugin binary
if command -v "$PLUGIN" &>/dev/null; then
    BIN="$PLUGIN"
else
    # Fallback to native binary in plugin source directory
    PLUGIN_DIR="$(dirname "$SCRIPT_DIR")/../../weaver-freemarker"
    BIN="$PLUGIN_DIR/target/weaver-freemarker"
    if [[ ! -x "$BIN" ]]; then
        echo "Building $PLUGIN native binary from source..."
        export JAVA_HOME="${GRAALVM_HOME:-${JAVA_HOME:-/home/jn/.local/graalvm}}"
        export GRAALVM_HOME="$JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
        (cd "$PLUGIN_DIR" && mvn -Pnative native:compile -DskipTests -q) || { echo "ERROR: failed to build $PLUGIN"; exit 2; }
    fi
fi

run_test() {
    local name="$1"
    local template="$2"
    local data="$3"
    local expected="$4"

    local actual
    actual=$("$BIN" render -t "$SCRIPT_DIR/$template" -f "$SCRIPT_DIR/$data")

    local expected_content
    expected_content=$(cat "$SCRIPT_DIR/$expected")

    if [[ "$actual" == "$expected_content" ]]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"
        echo "    Expected:"
        echo "$expected_content" | head -5 | sed 's/^/      /'
        echo "    Got:"
        echo "$actual" | head -5 | sed 's/^/      /'
        FAIL=$((FAIL + 1))
    fi
}

echo "=== $PLUGIN E2E Tests ==="

# Test 1: info command
info_output=$("$BIN" info)
if echo "$info_output" | grep -q '"engine" : "freemarker"'; then
    echo "  PASS: info command"
    PASS=$((PASS + 1))
else
    echo "  FAIL: info command"
    FAIL=$((FAIL + 1))
fi

# Test 2: nginx.conf from JSON
run_test "nginx.conf (JSON input)" \
    "templates/nginx.conf.ftl" "data/nginx.json" "expected/nginx.conf"

# Test 3: upstream.conf from YAML
run_test "upstream.conf (YAML input)" \
    "templates/upstream.conf.ftl" "data/upstreams.yaml" "expected/upstream.conf"

# Test 4: systemd.service from YAML
run_test "systemd.service (YAML input)" \
    "templates/systemd.service.ftl" "data/systemd.yaml" "expected/systemd.service"

# Test 5: stdin pipe
stdin_output=$(echo '{"server_name": "test.local", "listen_port": 443, "root_path": "/var/www/test", "proxy_port": 8080}' \
    | "$BIN" render -t "$SCRIPT_DIR/templates/nginx.conf.ftl" -f -)
if echo "$stdin_output" | grep -q "test.local"; then
    echo "  PASS: stdin pipe"
    PASS=$((PASS + 1))
else
    echo "  FAIL: stdin pipe"
    FAIL=$((FAIL + 1))
fi

# Test 6: output to file
tmpfile=$(mktemp)
"$BIN" render -t "$SCRIPT_DIR/templates/nginx.conf.ftl" -f "$SCRIPT_DIR/data/nginx.json" -o "$tmpfile"
if diff -q "$tmpfile" "$SCRIPT_DIR/expected/nginx.conf" &>/dev/null; then
    echo "  PASS: output to file"
    PASS=$((PASS + 1))
else
    echo "  FAIL: output to file"
    FAIL=$((FAIL + 1))
fi
rm -f "$tmpfile"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
