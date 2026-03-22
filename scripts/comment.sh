#!/bin/bash
# comment.sh — post LogSage analysis as a PR comment (idempotent).
# Reads: LOGSAGE_POST_COMMENT, LOGSAGE_RESULT_FILE, GITHUB_TOKEN,
#        GITHUB_EVENT_NAME, GITHUB_EVENT_PATH, GITHUB_REPOSITORY
# Always exits 0 — must never block the caller workflow.
set -uo pipefail

# ── Guard 1: posting disabled ─────────────────────────────────────────────────

if [ "${LOGSAGE_POST_COMMENT:-true}" = "false" ]; then
  exit 0
fi

# ── Guard 2: not a pull_request event ────────────────────────────────────────

if [ "${GITHUB_EVENT_NAME:-}" != "pull_request" ] && \
   [ "${GITHUB_EVENT_NAME:-}" != "pull_request_target" ]; then
  echo "::notice::LogSage: skipping PR comment — event is '${GITHUB_EVENT_NAME:-unknown}', not pull_request"
  exit 0
fi

# ── Guard 3: no result file ───────────────────────────────────────────────────

if [ -z "${LOGSAGE_RESULT_FILE:-}" ] || [ ! -s "${LOGSAGE_RESULT_FILE}" ]; then
  echo "::notice::LogSage: skipping PR comment — result file is empty or not set"
  exit 0
fi

# ── Guard 4 & 5: extract PR number ───────────────────────────────────────────

PR_NUMBER=$(jq -r '.pull_request.number // empty' "${GITHUB_EVENT_PATH}" 2>/dev/null) || PR_NUMBER=""

if [ -z "${PR_NUMBER}" ] || [ "${PR_NUMBER}" = "null" ]; then
  echo "::warning::LogSage: skipping PR comment — could not extract PR number from event payload"
  exit 0
fi

# ── Build comment body (9.2.4 format) ────────────────────────────────────────

MARKER="<!-- logsage-pr-comment -->"
HEADLINE=$(head -n 1 "${LOGSAGE_RESULT_FILE}")
RESULT=$(cat "${LOGSAGE_RESULT_FILE}")

if [ "${HEADLINE}" = "No issues detected." ]; then
  BODY="${MARKER}
### 🔍 LogSage — Likely Root Cause

${HEADLINE}

---
_Analyzed by [LogSage](https://github.com/UreaLaden/log-sage) · Install locally for faster debugging_"
else
  BODY="${MARKER}
### 🔍 LogSage — Likely Root Cause

${HEADLINE}

<details>
<summary>Full analysis</summary>

${RESULT}

</details>

---
_Analyzed by [LogSage](https://github.com/UreaLaden/log-sage) · Install locally for faster debugging_"
fi

# ── Search for existing comment ──────────────────────────────────────────────

comment_id=$(gh api \
  "/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
  --paginate \
  --jq ".[] | select(.body | startswith(\"${MARKER}\")) | .id" \
  2>/dev/null | head -1) || comment_id=""

# ── PATCH existing or POST new ───────────────────────────────────────────────

if [ -n "${comment_id}" ]; then
  gh api \
    --method PATCH \
    "/repos/${GITHUB_REPOSITORY}/issues/comments/${comment_id}" \
    --field body="${BODY}" \
    > /dev/null \
    || echo "::warning::LogSage: failed to update PR comment (check pull-requests: write permission)"
else
  gh api \
    --method POST \
    "/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
    --field body="${BODY}" \
    > /dev/null \
    || echo "::warning::LogSage: failed to post PR comment (check pull-requests: write permission)"
fi

exit 0
