#!/usr/bin/env bash
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

source_repo="$root/source"
remote_repo="$root/remote.git"
git init -q "$source_repo"
git -C "$source_repo" config user.name Test
git -C "$source_repo" config user.email test@example.invalid
# Neutralise the developer's global signing config inside the fixture. With a
# global `tag.gpgsign = true` -- which anyone who signs release tags will have
# -- `git tag lightweight` becomes a signed tag and git rejects it with
# "fatal: no tag message?", so the lightweight case below could not be built
# and this test failed on exactly the machines most likely to run it.
git -C "$source_repo" config tag.gpgsign false
git -C "$source_repo" config commit.gpgsign false
printf 'release\n' >"$source_repo/release.txt"
git -C "$source_repo" add release.txt
git -C "$source_repo" commit -q -m release
commit=$(git -C "$source_repo" rev-parse HEAD)
git -C "$source_repo" tag lightweight
git -C "$source_repo" tag -a annotated -m annotated
git clone -q --bare "$source_repo" "$remote_repo"

bash scripts/assert-release-ref.sh "$remote_repo" lightweight "$commit"
bash scripts/assert-release-ref.sh "$remote_repo" annotated "$commit"

wrong=0000000000000000000000000000000000000000
if bash scripts/assert-release-ref.sh "$remote_repo" annotated "$wrong" 2>/dev/null; then
  echo "mismatched release ref unexpectedly passed" >&2
  exit 1
fi

if bash scripts/assert-release-ref.sh "$remote_repo" missing "$commit" 2>/dev/null; then
  echo "missing release ref unexpectedly passed" >&2
  exit 1
fi

printf 'release-ref assertions fail closed\n'
