#!/usr/bin/env bash
# Assert that a feed the action could not score produced no grade at all.
#
# The property under test is narrow and load-bearing: when there is nothing to
# measure, the action must say so. A grade, a score, or a day count invented
# for a feed that was never read is worse than an error, because a downstream
# consumer cannot tell it apart from a real measurement -- it renders straight
# into a report, a badge, or a dashboard as though it meant something.
#
# `threshold-gate` already covers the other half: a feed that *was* measured
# and breached a threshold is refused. This covers the case where the
# measurement never happened.
set -euo pipefail

: "${OUTCOME:?OUTCOME is required}"

failures=0

note() {
  echo "$1" >&2
  failures=$((failures + 1))
}

if [ "$OUTCOME" != "failure" ]; then
  note "The action reported ${OUTCOME} for a feed it cannot read."
  note "An unscorable feed must fail the step, not pass quietly."
fi

# Every published fact must be absent. `${VAR:-}` rather than `${VAR:?}`
# because an unpublished output arrives as the empty string, which is exactly
# what this asserts, and a composite action that exits partway need not have
# published anything at all.
for pair in "grade:${GRADE:-}" "score:${SCORE:-}" "passed:${PASSED:-}" \
            "days-to-expiry:${DAYS:-}"; do
  field=${pair%%:*}
  value=${pair#*:}

  case "$field" in
    passed)
      # `passed` is a boolean, so "false" is its correct value for a feed that
      # did not pass; only "true" would be a lie.
      if [ "$value" = "true" ]; then
        note "The action could not score the feed but reported passed=true."
      fi
      ;;
    *)
      if [ -n "$value" ]; then
        note "The action published ${field}=${value} for a feed it could not read."
        note "A value nobody measured is not an answer; this must be blank."
      fi
      ;;
  esac
done

if [ "$failures" -gt 0 ]; then
  cat >&2 <<'MSG'

The action under test invented a result for a feed it could not read.
Do not relax this assertion to restore green. Either the action regressed
or its contract changed, and both belong in ChelseaKR/gtfs-scorecard.
MSG
  exit 1
fi

echo "Unscorable feed was refused with no invented grade, score or day count."
