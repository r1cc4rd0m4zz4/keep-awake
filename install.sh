#!/usr/bin/env bash
# ==============================================================================
# Installer for keep-awake
# Supports:
#   1. Remote one-liner: curl -fsSL <URL>/install.sh | bash
#   2. Local execution: ./install.sh (from any working directory)
#   3. Uninstallation: ./install.sh --uninstall or curl ... | bash -s -- --uninstall
# ==============================================================================
set -euo pipefail

REPO_OWNER="r1cc4rd0m4zz4"
REPO_NAME="keep-awake"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/keep-awake"

DEFAULT_BIN_DIR="${HOME}/.local/bin"
BIN_DIR="${BIN_DIR:-$DEFAULT_BIN_DIR}"
DO_UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall)
            DO_UNINSTALL=true
            shift
            ;;
        --dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: --dir requires a directory path." >&2
                exit 1
            fi
            BIN_DIR="$2"
            shift 2
            ;;
        -h|--help)
            cat <<EOF
keep-awake installer

Usage:
  ./install.sh [OPTIONS]
  curl -fsSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/install.sh | bash [OPTIONS]

Options:
  --dir <path>     Install to a custom directory (default: ~/.local/bin).
  --uninstall      Remove keep-awake and awake symlink.
  -h, --help       Show this help message.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

TARGET_BIN="${BIN_DIR}/keep-awake"
ALIAS_BIN="${BIN_DIR}/awake"

if [[ "$DO_UNINSTALL" == true ]]; then
    echo "🗑️  Uninstalling keep-awake..."
    rm -f "$TARGET_BIN" "$ALIAS_BIN"
    echo "✅ Successfully removed keep-awake and awake from ${BIN_DIR}."
    exit 0
fi

mkdir -p "$BIN_DIR"

# Dual-Mode Portability: Zero assumptions about repository visibility.
# Install directly from local clone if present; fallback to remote only if piped.
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
LOCAL_FILE=""
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/keep-awake" ]]; then
        LOCAL_FILE="${SCRIPT_DIR}/keep-awake"
    fi
fi

if [[ -n "$LOCAL_FILE" ]]; then
    echo "📦 Installing from local repository: ${LOCAL_FILE}"
    cp -f "$LOCAL_FILE" "$TARGET_BIN"
else
    echo "🌐 Downloading keep-awake from GitHub (${RAW_URL})..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$RAW_URL" -o "$TARGET_BIN"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TARGET_BIN" "$RAW_URL"
    else
        echo "❌ Error: Neither curl nor wget was found on your system." >&2
        exit 1
    fi
fi

chmod +x "$TARGET_BIN"

# Create shorthand symlink 'awake'
ln -sf "$TARGET_BIN" "$ALIAS_BIN"

echo "✅ Installed successfully:"
echo "   - Main binary: ${TARGET_BIN}"
echo "   - Shorthand:   ${ALIAS_BIN}"

# Verify PATH
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo ""
    echo "ℹ️  Notice: ${BIN_DIR} is not in your current PATH."
    echo "   Add it to your shell configuration (e.g. ~/.zshrc or ~/.bashrc):"
    echo "     export PATH=\"${BIN_DIR}:\$PATH\""
fi
