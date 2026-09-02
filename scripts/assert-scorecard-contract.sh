#!/usr/bin/env bash
set -euo pipefail

: "${GRADE:?GRADE is required}"
: "${SCORE:?SCORE is required}"
: "${PASSED:?PASSED is required}"
: "${RESULT_JSON:?RESULT_JSON is required}"
: "${RESULT_HTML:?RESULT_HTML is required}"
# `?` rather than `:?`: DAYS must be wired up, but blank is a legitimate value
# for it. The action documents `days-to-expiry` as "published service days
# remaining, or blank when unavailable", and blank is the whole point of the
# check below.
: "${DAYS?DAYS is required (blank is allowed, unset is not)}"

case "$GRADE" in
  A|B|C|D|F) ;;
  *) echo "unexpected grade: $GRADE" >&2; exit 1 ;;
esac

if ! [[ "$SCORE" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
  echo "score is not numeric: $SCORE" >&2
  exit 1
fi

if ! awk -v score="$SCORE" 'BEGIN { exit !(score >= 0 && score <= 100) }'; then
  echo "score is outside 0..100: $SCORE" >&2
  exit 1
fi

test "$PASSED" = "true"
test -s "$RESULT_JSON"
test -s "$RESULT_HTML"

jq -e --arg grade "$GRADE" --argjson score "$SCORE" '
  .overall.grade == $grade
  and (.overall.score | type) == "number"
  and ((.overall.score - $score) | fabs) < 0.000001
' "$RESULT_JSON" >/dev/null

# `days-to-expiry` was the one published output nothing here checked, and it
# is the output most able to lie quietly. The action documents it as blank
# when unavailable, so the failure to guard against is a missing measurement
# arriving as `0` -- which would read as "expires today" and would satisfy the
# `min-days-to-expiry: 0` threshold the positive jobs configure, so nothing
# else in this workflow would notice.
#
# The check runs both ways, because either direction is a defect:
#   * a value present in the output must be an integer and must be the value
#     in the artifact, not a plausible-looking substitute; and
#   * a blank output must mean the artifact has no day count either. A blank
#     that discards a real measurement is a different bug of the same shape.
json_days=$(jq -r '
  .categories.freshness.details.days_until_expiry
  | if . == null then "" else tostring end
' "$RESULT_JSON")

if [ -n "$DAYS" ]; then
  if ! [[ "$DAYS" =~ ^-?[0-9]+$ ]]; then
    echo "days-to-expiry is not an integer: $DAYS" >&2
    exit 1
  fi
  if [ "$DAYS" != "$json_days" ]; then
    echo "days-to-expiry is $DAYS but the artifact says ${json_days:-<absent>}" >&2
    exit 1
  fi
elif [ -n "$json_days" ]; then
  echo "days-to-expiry is blank but the artifact measured $json_days days" >&2
  exit 1
fi

grep -Eiq '<!doctype html>|<html([[:space:]>])' "$RESULT_HTML"
