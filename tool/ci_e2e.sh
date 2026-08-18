#!/usr/bin/env bash
set -eu

# Used by GitHub Actions emulator job. Secrets arrive as env vars, not argv.
if [ -z "${QA_A_EMAIL:-}" ] || [ -z "${QA_A_PASSWORD:-}" ]; then
  echo "QA_* environment variables are required."
  exit 1
fi

NAME_FILTER="${TEST_NAME:-}"
CMD=(
  flutter test integration_test/smoke_test.dart
  -d emulator-5554
  --dart-define="QA_A_EMAIL=${QA_A_EMAIL}"
  --dart-define="QA_A_PASSWORD=${QA_A_PASSWORD}"
  --dart-define="QA_B_EMAIL=${QA_B_EMAIL:-}"
  --dart-define="QA_B_PASSWORD=${QA_B_PASSWORD:-}"
)

if [ -n "$NAME_FILTER" ]; then
  CMD+=(--name "$NAME_FILTER")
fi

echo "Running: flutter test integration_test/smoke_test.dart --name=${NAME_FILTER:-<all>}"
"${CMD[@]}"
