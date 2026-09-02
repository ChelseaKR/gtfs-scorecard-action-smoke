#!/usr/bin/env bash
# Prove `scripts/assert-pinned-versions.sh` fails closed.
#
# Hermetic on purpose. The live check in `make verify` talks to github.com,
# but a test that needs the network is a test that gets skipped, so every case
# here runs against fixture repositories on disk via `--remote-base`.
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

remotes="$root/remotes"
mkdir -p "$remotes/actions"

# A fixture action repository with a lightweight tag `v7.0.1` and an annotated
# tag `v7`, so both tag shapes are exercised the way real actions publish
# them.
source_repo="$root/checkout-source"
git init -q "$source_repo"
git -C "$source_repo" config user.name Test
git -C "$source_repo" config user.email test@example.invalid
# See tests/test-release-ref.sh: a global `tag.gpgsign = true`, which anyone
# who signs release tags has, turns `git tag lightweight` into a signed tag
# and git then refuses it for want of a message.
git -C "$source_repo" config tag.gpgsign false
git -C "$source_repo" config commit.gpgsign false
printf 'action\n' >"$source_repo/action.yml"
git -C "$source_repo" add action.yml
git -C "$source_repo" commit -q -m v7.0.1
head_commit=$(git -C "$source_repo" rev-parse HEAD)
git -C "$source_repo" tag v7.0.1
git -C "$source_repo" tag -a v7 -m v7

printf 'older\n' >"$source_repo/action.yml"
git -C "$source_repo" add action.yml
git -C "$source_repo" commit -q -m v4.3.1
# `v4.3.1` deliberately names a *different* commit, so the "comment says v4,
# pin says something else" case is a real disagreement rather than a typo.
older_commit=$(git -C "$source_repo" rev-parse HEAD)
git -C "$source_repo" tag v4.3.1

git clone -q --bare "$source_repo" "$remotes/actions/checkout.git"

workflow() {
  local path=$1
  shift
  {
    printf 'name: fixture\non: workflow_dispatch\njobs:\n  build:\n'
    printf '    runs-on: ubuntu-latest\n    steps:\n'
    for step in "$@"; do
      printf '      - uses: %s\n' "$step"
    done
  } >"$path"
}

check() {
  bash scripts/assert-pinned-versions.sh --remote-base "$remotes/" "$@"
}

expect_fail() {
  local label=$1 file=$2 wanted=${3:-}
  local output
  if output=$(check "$file" 2>&1); then
    echo "$label unexpectedly passed" >&2
    exit 1
  fi
  if [ -n "$wanted" ] && ! grep -Fq "$wanted" <<<"$output"; then
    printf '%s failed for the wrong reason; expected to see %s in:\n%s\n' \
      "$label" "$wanted" "$output" >&2
    exit 1
  fi
}

# 1. A truthful lightweight tag, repeated, to exercise the resolution cache.
workflow "$root/truthful.yml" \
  "actions/checkout@${head_commit} # v7.0.1" \
  "actions/checkout@${head_commit} # v7.0.1"
check "$root/truthful.yml" >/dev/null

# 2. A truthful annotated tag: the comparison must peel the tag object.
workflow "$root/annotated.yml" "actions/checkout@${head_commit} # v7"
check "$root/annotated.yml" >/dev/null

# 3. Trailing prose after the tag is fine; the tag is the first token.
workflow "$root/prose.yml" \
  "actions/checkout@${head_commit} # v7.0.1 -- pinned deliberately"
check "$root/prose.yml" >/dev/null

# 4. The defect this script was written for: the SHA moved, the comment did
#    not. Dependabot produced exactly this in PR #8.
workflow "$root/lying.yml" "actions/checkout@${head_commit} # v4.3.1"
expect_fail "a comment naming a different commit" "$root/lying.yml" \
  "the comment says v4.3.1"

# 5. A comment naming a tag that does not exist upstream is not evidence of
#    anything, and must not be treated as an unknown to wave through.
workflow "$root/ghost.yml" "actions/checkout@${head_commit} # v9.9.9"
expect_fail "a comment naming a nonexistent tag" "$root/ghost.yml" \
  "does not exist upstream"

# 6. A bare hash with no comment cannot be reviewed.
workflow "$root/bare.yml" "actions/checkout@${head_commit}"
expect_fail "a pin with no version comment" "$root/bare.yml" \
  "no version comment"

# 7. An unpinned reference with no annotation is an oversight until argued.
workflow "$root/floating.yml" "actions/checkout@v7"
expect_fail "an unannotated floating ref" "$root/floating.yml" \
  "is not SHA-pinned"

# 8. An unpinned reference that is annotated is the documented exception --
#    `floating-major` is the whole point of this repository.
workflow "$root/annotated-floating.yml" \
  "actions/checkout@v7 # zizmor: ignore[unpinned-uses]"
check "$root/annotated-floating.yml" >/dev/null

# 9. A remote that cannot be reached must fail, and must say so in those
#    words. A failed read is not evidence that the tag is absent, and
#    reporting it as "that tag does not exist" would be this portfolio's
#    commonest defect: an unknown published as a finding.
workflow "$root/missing-remote.yml" "actions/absent@${head_commit} # v1.0.0"
if unreachable_output=$(check "$root/missing-remote.yml" 2>&1); then
  echo "an unreachable action repository unexpectedly passed" >&2
  exit 1
fi
grep -Fq "UNVERIFIED" <<<"$unreachable_output" || {
  printf 'an unreachable remote was not reported as unverified:\n%s\n' "$unreachable_output" >&2
  exit 1
}
if grep -Fq "does not exist upstream" <<<"$unreachable_output"; then
  printf 'an unreachable remote was reported as a missing tag:\n%s\n' "$unreachable_output" >&2
  exit 1
fi

# 10. A workflow the parser finds nothing in must fail. A check that inspects
#     zero references is the vacuous-assertion defect this repository exists
#     to avoid, and silence would look identical to success.
printf 'name: empty\non: workflow_dispatch\njobs: {}\n' >"$root/empty.yml"
expect_fail "a workflow with no action references" "$root/empty.yml"

# 11. `uses:` inside a comment is not a step.
{
  printf 'name: commented\non: workflow_dispatch\njobs:\n  build:\n'
  printf '    runs-on: ubuntu-latest\n'
  printf '    # uses: actions/checkout@deadbeef # v1\n'
  printf '    steps:\n      - uses: actions/checkout@%s # v7.0.1\n' "$head_commit"
} >"$root/commented.yml"
check "$root/commented.yml" >/dev/null

# 12. The older commit is genuinely a different one, so case 4 tested a real
#     disagreement rather than two names for one commit.
if [ "$older_commit" = "$head_commit" ]; then
  echo "fixture is degenerate: both tags name the same commit" >&2
  exit 1
fi

# 13. Four references to one tag must cost one round trip, not four.
#
#     A regression test for a real bug rather than a performance nicety. The
#     resolver was first written to print its answer, so every call ran inside
#     a `$(...)` subshell and every cache write died with it. The cache held
#     nothing, all ten references in the real workflow hit the network, and
#     one of them drew a transient failure that the script then reported as
#     "that tag does not exist upstream". Counting the round trips is the only
#     way to notice that regression from the outside.
real_git=$(command -v git)
mkdir -p "$root/bin"
counter="$root/ls-remote-count"
: >"$counter"
cat >"$root/bin/git" <<SHIM
#!/usr/bin/env bash
for arg in "\$@"; do
  if [ "\$arg" = ls-remote ]; then
    echo x >>"$counter"
    break
  fi
done
exec "$real_git" "\$@"
SHIM
chmod +x "$root/bin/git"

workflow "$root/repeated.yml" \
  "actions/checkout@${head_commit} # v7.0.1" \
  "actions/checkout@${head_commit} # v7.0.1" \
  "actions/checkout@${head_commit} # v7.0.1" \
  "actions/checkout@${head_commit} # v7.0.1"
PATH="$root/bin:$PATH" check "$root/repeated.yml" >/dev/null
calls=$(wc -l <"$counter" | tr -d ' ')
if [ "$calls" -ne 1 ]; then
  echo "four references to one tag cost ${calls} ls-remote calls; the cache is not working" >&2
  exit 1
fi

printf 'pinned-version assertions fail closed\n'
