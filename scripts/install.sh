#!/bin/bash
# install.sh — download and install the LogSage binary for the current GitHub Actions runner.
# Reads: LOGSAGE_VERSION, RUNNER_OS, RUNNER_ARCH, RUNNER_TEMP, GITHUB_PATH
set -euo pipefail

REPO="UreaLaden/log-sage"
INSTALL_DIR="${RUNNER_TEMP}/logsage-bin"

# ── 1. Resolve version ────────────────────────────────────────────────────────

if [ -z "${LOGSAGE_VERSION:-}" ] || [ "${LOGSAGE_VERSION}" = "latest" ]; then
  echo "Resolving latest LogSage version..."
  LOGSAGE_VERSION=$(
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep '"tag_name"' \
      | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/'
  )
  [ -n "${LOGSAGE_VERSION}" ] || { echo "::error::Failed to resolve latest LogSage version" >&2; exit 1; }
fi

echo "LogSage version: ${LOGSAGE_VERSION}"

# ── 2. Map runner OS/arch to GoReleaser artifact naming ──────────────────────

case "${RUNNER_OS}" in
  Linux)   os="linux"   ;;
  macOS)   os="darwin"  ;;
  Windows) os="windows" ;;
  *) echo "::error::Unsupported runner OS: ${RUNNER_OS}" >&2; exit 1 ;;
esac

case "${RUNNER_ARCH}" in
  X64)   arch="amd64" ;;
  ARM64) arch="arm64" ;;
  *) echo "::error::Unsupported runner architecture: ${RUNNER_ARCH}" >&2; exit 1 ;;
esac

if [ "${os}" = "windows" ] && [ "${arch}" = "arm64" ]; then
  echo "::error::LogSage does not publish a Windows ARM64 binary" >&2
  exit 1
fi

# ── 3. Build artifact name ────────────────────────────────────────────────────

if [ "${os}" = "windows" ]; then
  ext="zip"
  binary="logsage.exe"
else
  ext="tar.gz"
  binary="logsage"
fi

artifact="logsage_${LOGSAGE_VERSION}_${os}_${arch}.${ext}"
base_url="https://github.com/${REPO}/releases/download/v${LOGSAGE_VERSION}"

echo "Artifact: ${artifact}"

# ── 4. Download ───────────────────────────────────────────────────────────────

tmp_dir="${RUNNER_TEMP}/logsage-download-$$"
mkdir -p "${tmp_dir}"

artifact_path="${tmp_dir}/${artifact}"
checksums_path="${tmp_dir}/checksums.txt"

echo "Downloading ${artifact}..."
curl -fsSL -o "${artifact_path}" "${base_url}/${artifact}"

echo "Downloading checksums.txt..."
curl -fsSL -o "${checksums_path}" "${base_url}/checksums.txt"

# ── 5. Verify SHA256 checksum ─────────────────────────────────────────────────

echo "Verifying checksum..."
grep "  ${artifact}$" "${checksums_path}" > "${tmp_dir}/check.txt" \
  || { echo "::error::Artifact ${artifact} not found in checksums.txt" >&2; exit 1; }

if command -v sha256sum >/dev/null 2>&1; then
  (cd "${tmp_dir}" && sha256sum -c "check.txt")
elif command -v shasum >/dev/null 2>&1; then
  (cd "${tmp_dir}" && shasum -a 256 -c "check.txt")
else
  echo "::error::No SHA256 verifier found (sha256sum or shasum required)" >&2
  exit 1
fi

# ── 6. Extract and install ────────────────────────────────────────────────────

mkdir -p "${INSTALL_DIR}"

echo "Extracting ${artifact}..."
if [ "${ext}" = "zip" ]; then
  unzip -q -o "${artifact_path}" -d "${INSTALL_DIR}"
else
  tar -xzf "${artifact_path}" -C "${INSTALL_DIR}"
fi

chmod +x "${INSTALL_DIR}/${binary}" 2>/dev/null || true

# Add install dir to PATH for subsequent steps
echo "${INSTALL_DIR}" >> "${GITHUB_PATH}"

echo "LogSage installed: ${INSTALL_DIR}/${binary}"

# Cleanup download temp
rm -rf "${tmp_dir}"
