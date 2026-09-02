#!/usr/bin/env bash
# Prove `scripts/assert-unscorable.sh` fails closed.
#
# The job it backs is the only place in this repository that asks what the
# action does when it has nothing to measure. If this assertion can be
# satisfied by an invented grade, that job is decoration.
set -euo pipefail

run_unscorable() {
  OUTCOME="${OUTCOME_VALUE:-failure}" \
  GRADE="${GRADE_VALUE-}" \
  SCORE="${SCORE_VALUE-}" \
  DAYS="${DAYS_VALUE-}" \
  PASSED="${PASSED_VALUE-false}" \
    bash scripts/assert-unscorable.sh
}

expect_fail() {
  local label=$1 wanted=$2 output
  if output=$(run_unscorable 2>&1); then
    echo "$label unexpectedly passed" >&2
    exit 1
  fi
  if ! grep -Fq "$wanted" <<<"$output"; then
    printf '%s failed for the wrong reason; expected %s in:\n%s\n' \
      "$label" "$wanted" "$output" >&2
    exit 1
  fi
}

# The shape a refusal actually has: the step failed and published nothing.
run_unscorable >/dev/null

# A composite action that exits partway may publish `passed=false` and leave
# the rest blank. That is still a clean refusal.
PASSED_VALUE=false run_unscorable >/dev/null

# The defect: the step failed, but a grade came out anyway.
GRADE_VALUE=F expect_fail "an invented grade" "published grade=F"
unset GRADE_VALUE

# A zero score for a feed that was never read is the same defect. `0` is the
# most dangerous value here precisely because it looks like a measurement of a
# very bad feed rather than the absence of one.
SCORE_VALUE=0 expect_fail "an invented score" "published score=0"
unset SCORE_VALUE

DAYS_VALUE=0 expect_fail "an invented day count" "published days-to-expiry=0"
unset DAYS_VALUE

# Scoring failed, yet the gate says it passed.
PASSED_VALUE=true expect_fail "a passing gate over an unreadable feed" \
  "reported passed=true"
unset PASSED_VALUE

# The step succeeded outright. Either the action scored a file that is not a
# GTFS feed, or the fixture stopped being unscorable; both need a human.
OUTCOME_VALUE=success expect_fail "a successful step" \
  "reported success for a feed it cannot read"
unset OUTCOME_VALUE

# OUTCOME is the one variable with no safe default: an unwired step outcome
# must fail rather than be read as "no news is good news".
if OUTCOME="" GRADE="" SCORE="" DAYS="" PASSED=false \
   bash scripts/assert-unscorable.sh >/dev/null 2>&1; then
  echo "an unwired OUTCOME unexpectedly passed" >&2
  exit 1
fi

printf 'unscorable-feed assertions fail closed\n'
