#!/usr/bin/env bash
# Assert that every `uses:` reference in a workflow says what it does.
#
# This repository already refuses to let the *action under test* drift away
# from its version comment: `release-aliases` peels the public tags and fails
# if `v1.4.0` stops meaning the commit the workflow executes. It applied no
# such rule to its own tooling pins, and the gap was not hypothetical --
# Dependabot's checkout 4.3.1 -> 7.0.1 bump (#8) rewrote five SHAs and left
# every `# v4` comment behind, so each pin and its comment disagreed until a
# human noticed. A comment is the only thing that makes a 40-character hash
# reviewable, and an unreviewed pin is how a supply-chain change gets waved
# through.
#
# Three rules, each of which the fixtures in tests/test-pinned-versions.sh
# prove fails closed:
#
#   1. A SHA-pinned reference must carry a version comment, and the tag it
#      names must actually resolve to that commit upstream.
#   2. A SHA-pinned reference with no comment at all is rejected: nobody can
#      review what they cannot read.
#   3. A reference that is not SHA-pinned is rejected unless it is annotated
#      `zizmor: ignore[unpinned-uses]`, which marks it as a deliberate,
#      argued exception rather than an oversight. `floating-major` is the
#      one such exception here, and it is the thing that job exists to test.
#
# Local actions (`uses: ./...`) and reusable workflows referenced by path are
# out of scope; they carry no upstream tag to check.
set -euo pipefail

remote_base="https://github.com/"
files=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remote-base)
      shift
      [ "$#" -gt 0 ] || { echo "--remote-base needs a value" >&2; exit 2; }
      remote_base=$1
      ;;
    --remote-base=*)
      remote_base=${1#--remote-base=}
      ;;
    -h|--help)
      echo "usage: assert-pinned-versions.sh [--remote-base <url-or-path>] <workflow.yml>..." >&2
      exit 0
      ;;
    *)
      files+=("$1")
      ;;
  esac
  shift
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "usage: assert-pinned-versions.sh [--remote-base <url-or-path>] <workflow.yml>..." >&2
  exit 2
fi

failures=0
unreachable=0
# A newline-delimited "<repository>#<tag> <status> <commit>" cache. A plain string
# rather than an associative array so the script still runs under the bash 3.2
# that ships as /bin/bash on macOS, which is what a contributor without a
# newer bash on PATH will get.
resolved_cache=""

fail() {
  printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
  failures=$((failures + 1))
}

# Resolve `refs/tags/<tag>` on a remote to the commit it ultimately names,
# following an annotated tag through to its peeled target.
#
# Sets two globals rather than printing, because a `$(...)` substitution runs
# in a subshell and every cache write inside one is discarded when it exits.
# The first draft of this script did exactly that, so the cache never held
# anything, every reference cost a fresh round trip, and one of the ten
# lookups hit a transient `git ls-remote` failure.
#
#   RESOLVED_STATUS  ok | missing | unreachable
#   RESOLVED_COMMIT  the commit, when the status is `ok`
#
# `unreachable` is a distinct status on purpose. A network failure is not
# evidence that a tag is absent, and reporting it as "that tag does not exist"
# would be a failed read published as a finding.
RESOLVED_STATUS=""
RESOLVED_COMMIT=""

resolve_tag() {
  local repository=$1 tag=$2 key cached listing direct peeled attempt rc

  key="${repository}#${tag}"
  cached=$(awk -v key="$key" '$1 == key { print $2, $3; found = 1; exit }
                              END { if (!found) print "" }' <<<"$resolved_cache")
  if [ -n "$cached" ]; then
    RESOLVED_STATUS=${cached%% *}
    RESOLVED_COMMIT=${cached#* }
    return 0
  fi

  listing=""
  rc=1
  for attempt in 1 2 3; do
    if listing=$(GIT_TERMINAL_PROMPT=0 git ls-remote "${remote_base}${repository}" \
        "refs/tags/${tag}" "refs/tags/${tag}^{}" 2>/dev/null); then
      rc=0
      break
    fi
    [ "$attempt" -lt 3 ] && sleep "$attempt"
  done

  if [ "$rc" -ne 0 ]; then
    RESOLVED_STATUS=unreachable
    RESOLVED_COMMIT=""
  else
    direct=$(awk -v ref="refs/tags/${tag}" '$2 == ref { print $1 }' <<<"$listing")
    peeled=$(awk -v ref="refs/tags/${tag}^{}" '$2 == ref { print $1 }' <<<"$listing")
    RESOLVED_COMMIT=${peeled:-$direct}
    if [ -n "$RESOLVED_COMMIT" ]; then
      RESOLVED_STATUS=ok
    else
      RESOLVED_STATUS=missing
    fi
  fi

  # Never memoise a transport failure as a verdict; a later attempt may reach
  # the remote, and a cached `unreachable` would turn one flaky round trip
  # into a confident answer about every other reference to the same tag.
  if [ "$RESOLVED_STATUS" != unreachable ]; then
    resolved_cache="${resolved_cache}"$'\n'"${key} ${RESOLVED_STATUS} ${RESOLVED_COMMIT}"
  fi
}

checked=0

for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "no such workflow file: $file" >&2
    exit 2
  fi

  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    # `uses:` as a mapping key, optionally the first entry of a list item.
    # A leading `#` is a comment, not a step.
    [[ "$line" =~ ^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*(.+)$ ]] || continue
    value=${BASH_REMATCH[2]}

    reference=${value%%#*}
    reference=${reference%"${reference##*[![:space:]]}"}
    comment=""
    if [[ "$value" == *"#"* ]]; then
      comment=${value#*#}
      comment=${comment#"${comment%%[![:space:]]*}"}
    fi

    # Local composite actions and path-referenced reusable workflows.
    [[ "$reference" == ./* || "$reference" == .github/* ]] && continue

    if [[ "$reference" != *@* ]]; then
      fail "$file" "$lineno" "action reference has no ref at all: ${reference}"
      continue
    fi

    repository=${reference%@*}
    ref=${reference##*@}
    checked=$((checked + 1))

    if ! [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
      if [[ "$comment" == *"zizmor: ignore[unpinned-uses]"* ]]; then
        printf '%s@%s is deliberately unpinned (annotated).\n' "$repository" "$ref"
      else
        fail "$file" "$lineno" \
          "${repository}@${ref} is not SHA-pinned. A mutable ref decides what executes; if that is intended, annotate the line 'zizmor: ignore[unpinned-uses]' and say why."
      fi
      continue
    fi

    # The comment may carry trailing prose; the tag is its first token.
    tag=${comment%%[[:space:]]*}
    if [ -z "$tag" ]; then
      fail "$file" "$lineno" \
        "${repository}@${ref} is pinned with no version comment. A bare 40-character hash cannot be reviewed."
      continue
    fi

    resolve_tag "$repository" "$tag"
    case "$RESOLVED_STATUS" in
      unreachable)
        # Reported as an unverified reference rather than a bad one: the read
        # failed, so this script knows nothing about the pin either way. It
        # still exits non-zero, because "could not check" is not "checked".
        unreachable=$((unreachable + 1))
        fail "$file" "$lineno" \
          "${repository}: could not reach the remote to check ${tag}. UNVERIFIED -- this says nothing about whether the pin is correct."
        continue
        ;;
      missing)
        fail "$file" "$lineno" \
          "${repository}: the comment names ${tag}, which does not exist upstream."
        continue
        ;;
    esac

    if [ "$RESOLVED_COMMIT" != "$ref" ]; then
      fail "$file" "$lineno" \
        "${repository}: the comment says ${tag}, but ${tag} is ${RESOLVED_COMMIT} and the pin is ${ref}."
      continue
    fi

    printf '%s@%s == %s\n' "$repository" "$tag" "$ref"
  done <"$file"
done

if [ "$checked" -eq 0 ]; then
  # A check that inspects nothing is not a check. If the parser stops matching
  # the workflow's syntax, that must be a failure rather than a silent pass.
  echo "no action references found in: ${files[*]}" >&2
  exit 1
fi

if [ "$failures" -gt 0 ]; then
  if [ "$unreachable" -gt 0 ]; then
    printf '\n%d reference(s) failed the check, %d of them because the remote could not be reached.\n' \
      "$failures" "$unreachable" >&2
  else
    printf '\n%d pinned reference(s) disagree with their version comment.\n' "$failures" >&2
  fi
  exit 1
fi

printf 'every action reference says what it does (%d checked).\n' "$checked"
