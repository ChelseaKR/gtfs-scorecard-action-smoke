#!/usr/bin/env bash
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

result_json="$root/scorecard.json"
result_html="$root/scorecard.html"

printf '{"overall":{"grade":"A","score":97.5}}\n' >"$result_json"
printf '<!doctype html><html lang="en"><title>Scorecard</title></html>\n' >"$result_html"

run_contract() {
  GRADE="${GRADE_VALUE:-A}" \
  SCORE="${SCORE_VALUE:-97.5}" \
  PASSED="${PASSED_VALUE:-true}" \
  RESULT_JSON="$result_json" \
  RESULT_HTML="$result_html" \
    bash scripts/assert-scorecard-contract.sh
}

run_contract

GRADE_VALUE=Z
if run_contract 2>/dev/null; then
  echo "invalid grade unexpectedly passed" >&2
  exit 1
fi
unset GRADE_VALUE

SCORE_VALUE=101
if run_contract 2>/dev/null; then
  echo "out-of-range score unexpectedly passed" >&2
  exit 1
fi
unset SCORE_VALUE

printf '{"overall":{"grade":"B","score":97.5}}\n' >"$result_json"
if run_contract 2>/dev/null; then
  echo "output/JSON mismatch unexpectedly passed" >&2
  exit 1
fi

printf 'scorecard\n' >"$result_html"
printf '{"overall":{"grade":"A","score":97.5}}\n' >"$result_json"
if run_contract 2>/dev/null; then
  echo "non-HTML artifact unexpectedly passed" >&2
  exit 1
fi

printf 'contract assertions fail closed\n'
