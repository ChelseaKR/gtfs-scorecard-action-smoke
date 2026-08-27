#!/usr/bin/env bash
# Fail when the newest published action release is not among the commits this
# smoke harness executes.
#
# Pinning to an immutable commit is right for supply-chain reasons, but a pin
# is also a thing that silently goes out of date: v1.4.0 shipped 2026-07-25
# and this repository went on testing v1.3.0 and a v1 alias frozen before it,
# so the current release had never been smoke-tested at all. A static pin will
# drift again, so the drift itself is the assertion.
#
# Only `v*` releases count. This repository also publishes dataset releases
# (`dataset-2026-08` and friends), which are data snapshots rather than action
# versions and carry nothing for a downstream consumer to execute.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: assert-latest-release-tested.sh <owner/repo> <tested-commit>..." >&2
  exit 2
fi

repository=$1
shift

latest_tag=$(
  gh api "repos/${repository}/releases?per_page=100" \
    --jq '[.[] | select(.draft == false and .prerelease == false)
           | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))]
          | first | .tag_name'
)

if [ -z "${latest_tag}" ] || [ "${latest_tag}" = "null" ]; then
  echo "no published v<major>.<minor>.<patch> release found for ${repository}" >&2
  exit 1
fi

latest_commit=$(
  gh api "repos/${repository}/git/ref/tags/${latest_tag}" --jq '.object.sha'
)
object_type=$(
  gh api "repos/${repository}/git/ref/tags/${latest_tag}" --jq '.object.type'
)
if [ "${object_type}" = "tag" ]; then
  latest_commit=$(gh api "repos/${repository}/git/tags/${latest_commit}" --jq '.object.sha')
fi

for tested in "$@"; do
  if [ "${tested}" = "${latest_commit}" ]; then
    echo "latest release ${latest_tag} (${latest_commit}) is under test."
    exit 0
  fi
done

cat >&2 <<MSG
The newest action release is not exercised by this smoke harness.

  latest release : ${latest_tag} -> ${latest_commit}
  under test     : $*

Update the pins in .github/workflows/verify.yml to include the new release,
then re-run. Release evidence that skips the current release is not evidence
for it.
MSG
exit 1
