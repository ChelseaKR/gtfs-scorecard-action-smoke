#!/usr/bin/env bash
set -euo pipefail

: "${GRADE:?GRADE is required}"
: "${SCORE:?SCORE is required}"
: "${PASSED:?PASSED is required}"
: "${RESULT_JSON:?RESULT_JSON is required}"
: "${RESULT_HTML:?RESULT_HTML is required}"

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

grep -Eiq '<!doctype html>|<html([[:space:]>])' "$RESULT_HTML"
