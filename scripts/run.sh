#!/bin/bash
# run.sh — execute LogSage and persist output as step outputs.
# Reads: LOGSAGE_RUN_CMD (optional), LOGSAGE_LOG_FILE (optional), LOGSAGE_OUTPUT_FILE, GITHUB_OUTPUT
# Precedence: LOGSAGE_RUN_CMD > LOGSAGE_LOG_FILE > stdin
# When LOGSAGE_RUN_CMD is set, exits with the original command exit code.
# Otherwise always exits 0 — this action must never block the caller workflow.
set -uo pipefail

OUTPUT_FILE="${LOGSAGE_OUTPUT_FILE:-${RUNNER_TEMP}/logsage-output.md}"
mkdir -p "$(dirname "${OUTPUT_FILE}")"

# ── run mode: execute command, analyze on failure ─────────────────────────────

if [ -n "${LOGSAGE_RUN_CMD:-}" ]; then
  cmd_output_file="${RUNNER_TEMP}/logsage-cmd-output.txt"

  # Execute command, capture combined stdout+stderr
  bash -c "${LOGSAGE_RUN_CMD}" > "${cmd_output_file}" 2>&1
  cmd_exit=$?

  if [ "${cmd_exit}" -ne 0 ]; then
    # Command failed — run LogSage against captured output
    logsage ci "${cmd_output_file}" --ci-summary > "${OUTPUT_FILE}" 2>&1 || true

    # Ensure output file exists even if logsage errors
    touch "${OUTPUT_FILE}"

    # Persist step outputs
    echo "result<<EOF" >> "${GITHUB_OUTPUT}"
    cat "${OUTPUT_FILE}" >> "${GITHUB_OUTPUT}"
    echo "EOF" >> "${GITHUB_OUTPUT}"
    echo "result-file=${OUTPUT_FILE}" >> "${GITHUB_OUTPUT}"
  fi

  # Propagate original exit code — action step fails when command fails
  exit ${cmd_exit}
fi

# ── log-file / stdin mode: run LogSage — capture output; ignore exit code ────

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
