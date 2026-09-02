#!/usr/bin/env bash
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

result_json="$root/scorecard.json"
result_html="$root/scorecard.html"

artifact() {
  # $1 is the JSON value for days_until_expiry: a number, or `null` for the
  # "the feed has no measurable expiry" case the action documents.
  printf '{"overall":{"grade":"%s","score":97.5},"categories":{"freshness":{"details":{"days_until_expiry":%s}}}}\n' \
    "${1:-A}" "${2:-120}" >"$result_json"
}

artifact A 120
printf '<!doctype html><html lang="en"><title>Scorecard</title></html>\n' >"$result_html"

run_contract() {
  GRADE="${GRADE_VALUE:-A}" \
  SCORE="${SCORE_VALUE:-97.5}" \
  PASSED="${PASSED_VALUE:-true}" \
  DAYS="${DAYS_VALUE-120}" \
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

artifact B 120
if run_contract 2>/dev/null; then
  echo "output/JSON mismatch unexpectedly passed" >&2
  exit 1
fi
artifact A 120

# days-to-expiry. The action documents it as blank when unavailable, so the
# defect to catch is a missing measurement arriving as a plausible number --
# and `0` in particular, which reads as "expires today" and would satisfy the
# `min-days-to-expiry: 0` threshold the positive jobs configure, so nothing
# else in the workflow would notice.
DAYS_VALUE=0
if run_contract 2>/dev/null; then
  echo "a fabricated days-to-expiry of 0 unexpectedly passed" >&2
  exit 1
fi

DAYS_VALUE=-1
if run_contract 2>/dev/null; then
  echo "a sentinel days-to-expiry of -1 unexpectedly passed" >&2
  exit 1
fi

DAYS_VALUE=soon
if run_contract 2>/dev/null; then
  echo "a non-integer days-to-expiry unexpectedly passed" >&2
  exit 1
fi

# The reverse direction is the same bug wearing different clothes: an output
# that discards a measurement the artifact holds.
DAYS_VALUE=""
if run_contract 2>/dev/null; then
  echo "a blank days-to-expiry over a measured artifact unexpectedly passed" >&2
  exit 1
fi

# Blank is correct, and must stay allowed, when the artifact has no day count.
artifact A null
DAYS_VALUE="" run_contract
unset DAYS_VALUE

# ...but a number over an artifact that measured nothing is an invention.
DAYS_VALUE=120
if run_contract 2>/dev/null; then
  echo "a days-to-expiry with no measurement behind it unexpectedly passed" >&2
  exit 1
fi
unset DAYS_VALUE
artifact A 120

# A genuinely negative count is a real measurement of an expired feed, not a
# sentinel, and must pass.
artifact A -30
DAYS_VALUE=-30 run_contract
unset DAYS_VALUE
artifact A 120

# Unset, as opposed to blank, means the workflow forgot to wire the output up
# at all. That must fail rather than silently skip the check.
if GRADE=A SCORE=97.5 PASSED=true \
   RESULT_JSON="$result_json" RESULT_HTML="$result_html" \
   bash scripts/assert-scorecard-contract.sh 2>/dev/null; then
  echo "an unwired DAYS unexpectedly passed" >&2
  exit 1
fi

printf 'scorecard\n' >"$result_html"
artifact A 120
if run_contract 2>/dev/null; then
  echo "non-HTML artifact unexpectedly passed" >&2
  exit 1
fi

printf 'contract assertions fail closed\n'
