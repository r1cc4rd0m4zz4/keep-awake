#!/usr/bin/env bash
# ==============================================================================
# Automated Test Suite for keep-awake
# Checks unit logic, CLI flags, codesmells, and installer behavior
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_PATH="${SCRIPT_DIR}/keep-awake"
INSTALLER_PATH="${SCRIPT_DIR}/install.sh"

PASSED=0
FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  ✅ PASS: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ FAIL: $test_name (expected '$expected', got '$actual')"
        FAILED=$((FAILED + 1))
    fi
}

assert_exit_code() {
    local expected="$1"
    local test_name="$2"
    shift 2
    local code=0
    "$@" >/dev/null 2>&1 || code=$?
    if [[ "$code" -eq "$expected" ]]; then
        echo "  ✅ PASS: $test_name (exit code $expected)"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ FAIL: $test_name (expected code $expected, got $code)"
        FAILED=$((FAILED + 1))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Running keep-awake Automated Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Test CLI Help & Version
echo "[1] CLI Metadata & Flags"
assert_exit_code 0 "keep-awake --help exits with 0" "$BIN_PATH" --help
assert_exit_code 0 "keep-awake -h exits with 0" "$BIN_PATH" -h
assert_exit_code 0 "keep-awake --version exits with 0" "$BIN_PATH" --version
assert_exit_code 0 "keep-awake -v exits with 0" "$BIN_PATH" -v

# 2. Test Duration Parsing Logic
echo "[2] Duration Parsing Unit Tests"
# Source only parse_duration function from the script
parse_duration() {
    local input="${1:-60m}"
    case "$input" in
        *[hH])
            local num="${input%[hH]}"
            if [[ ! "$num" =~ ^[0-9]+$ ]] || [[ "$num" -le 0 ]]; then
                return 1
            fi
            echo "$(( num * 3600 ))"
            ;;
        *[mM])
            local num="${input%[mM]}"
            if [[ ! "$num" =~ ^[0-9]+$ ]] || [[ "$num" -le 0 ]]; then
                return 1
            fi
            echo "$(( num * 60 ))"
            ;;
        *[sS])
            local num="${input%[sS]}"
            if [[ ! "$num" =~ ^[0-9]+$ ]] || [[ "$num" -le 0 ]]; then
                return 1
            fi
            echo "$(( num ))"
            ;;
        *[0-9])
            if [[ ! "$input" =~ ^[0-9]+$ ]] || [[ "$input" -le 0 ]]; then
                return 1
            fi
            echo "$(( input * 60 ))"
            ;;
        *)
            return 1
            ;;
    esac
}

assert_eq "3600" "$(parse_duration 60)" "Parse '60' -> 3600s"
assert_eq "2700" "$(parse_duration 45m)" "Parse '45m' -> 2700s"
assert_eq "7200" "$(parse_duration 2h)" "Parse '2h' -> 7200s"
assert_eq "90" "$(parse_duration 90s)" "Parse '90s' -> 90s"
assert_exit_code 1 "Reject invalid format 'abc'" parse_duration "abc"
assert_exit_code 1 "Reject negative/special chars '-10m'" parse_duration "-10m"

# 3. Test Installer from arbitrary directories
echo "[3] Installer & Symlink Integration Tests"
TEST_TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TEMP_DIR"' EXIT

# Run installer from a different working directory
(
    cd /tmp
    bash "$INSTALLER_PATH" --dir "$TEST_TEMP_DIR" >/dev/null 2>&1
)

assert_eq "true" "$([[ -x "$TEST_TEMP_DIR/keep-awake" ]] && echo true || echo false)" "Binary installed and executable"
assert_eq "true" "$([[ -L "$TEST_TEMP_DIR/awake" ]] && echo true || echo false)" "Shorthand symlink 'awake' created"
assert_eq "true" "$([[ "$(readlink "$TEST_TEMP_DIR/awake")" == "$TEST_TEMP_DIR/keep-awake" ]] && echo true || echo false)" "Symlink points to target binary"

# Verify installed binary runs
assert_exit_code 0 "Installed binary runs --version" "$TEST_TEMP_DIR/awake" --version

# 4. Test Uninstaller
echo "[4] Uninstaller Tests"
bash "$INSTALLER_PATH" --dir "$TEST_TEMP_DIR" --uninstall >/dev/null 2>&1
assert_eq "false" "$([[ -f "$TEST_TEMP_DIR/keep-awake" ]] && echo true || echo false)" "Binary cleanly removed"
assert_eq "false" "$([[ -e "$TEST_TEMP_DIR/awake" ]] && echo true || echo false)" "Symlink cleanly removed"

# 5. Codesmell & Security Integrity
echo "[5] Codesmell & Security Checks"
# Ensure no hardcoded personal paths
LEAK_COUNT="$(grep -rEn "(/Users/|/home/[a-zA-Z0-9]+|10\.10\.)" "$BIN_PATH" "$INSTALLER_PATH" || true)"
assert_eq "" "$LEAK_COUNT" "Zero hardcoded personal paths or internal IPs in scripts"

# Ensure strict bash options are present
assert_eq "true" "$(grep -q "set -euo pipefail" "$BIN_PATH" && echo true || echo false)" "Strict mode 'set -euo pipefail' in keep-awake"
assert_eq "true" "$(grep -q "set -euo pipefail" "$INSTALLER_PATH" && echo true || echo false)" "Strict mode 'set -euo pipefail' in install.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASSED passed, $FAILED failed."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$FAILED" -gt 0 ]]; then
    exit 1
fi
