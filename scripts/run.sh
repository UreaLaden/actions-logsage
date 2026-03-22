#!/bin/bash
# run.sh — execute LogSage and persist output as step outputs.
# Reads: LOGSAGE_LOG_FILE (optional), LOGSAGE_OUTPUT_FILE, GITHUB_OUTPUT
# Always exits 0 — this action must never block the caller workflow.
set -uo pipefail

OUTPUT_FILE="${LOGSAGE_OUTPUT_FILE:-${RUNNER_TEMP}/logsage-output.md}"
mkdir -p "$(dirname "${OUTPUT_FILE}")"

# ── Run LogSage — capture output; ignore exit code ───────────────────────────

if [ -n "${LOGSAGE_LOG_FILE:-}" ]; then
  logsage ci "${LOGSAGE_LOG_FILE}" --ci-summary > "${OUTPUT_FILE}" 2>&1 || true
else
  # No log file: attempt stdin analysis; skip gracefully if stdin yields nothing.
  logsage analyze --stdin > "${OUTPUT_FILE}" 2>&1 < /dev/stdin || true
fi

# Ensure output file exists even on complete failure
touch "${OUTPUT_FILE}"

# ── Persist step outputs ──────────────────────────────────────────────────────

{
  echo "result<<EOF"
  cat "${OUTPUT_FILE}"
  echo "EOF"
  echo "result-file=${OUTPUT_FILE}"
} >> "${GITHUB_OUTPUT}"

exit 0
