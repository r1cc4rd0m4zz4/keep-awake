#!/usr/bin/env bash
# ==============================================================================
# Packaging script for keep-awake release tarballs & checksums
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
VERSION="${1:-0.1.0}"
ARCHIVE_NAME="keep-awake-v${VERSION}.tar.gz"

echo "📦 Packaging keep-awake v${VERSION}..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

TMP_STAGE="$(mktemp -d)"
STAGE_DIR="${TMP_STAGE}/keep-awake-v${VERSION}"
mkdir -p "$STAGE_DIR"

cleanup() {
    rm -rf "$TMP_STAGE"
}
trap cleanup EXIT

cp "${ROOT_DIR}/keep-awake" "$STAGE_DIR/"
cp "${ROOT_DIR}/install.sh" "$STAGE_DIR/"
cp "${ROOT_DIR}/README.md" "$STAGE_DIR/"
cp "${ROOT_DIR}/LICENSE" "$STAGE_DIR/"
cp "${ROOT_DIR}/CONTRIBUTORS.md" "$STAGE_DIR/"

chmod +x "$STAGE_DIR/keep-awake" "$STAGE_DIR/install.sh"

tar -czf "${DIST_DIR}/${ARCHIVE_NAME}" -C "$TMP_STAGE" "keep-awake-v${VERSION}"

cd "$DIST_DIR"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ARCHIVE_NAME" > SHA256SUMS.txt
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$ARCHIVE_NAME" > SHA256SUMS.txt
fi

echo "✅ Release package built successfully in dist/:"
ls -lh "${DIST_DIR}"
cat "${DIST_DIR}/SHA256SUMS.txt"
