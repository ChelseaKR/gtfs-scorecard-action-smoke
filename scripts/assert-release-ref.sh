#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: assert-release-ref.sh <repository> <tag> <expected-commit>" >&2
  exit 2
fi

repository=$1
tag=$2
expected=$3

if ! [[ "$expected" =~ ^[0-9a-f]{40}$ ]]; then
  echo "expected commit must be a lowercase 40-character SHA" >&2
  exit 2
fi

listing=$(git ls-remote "$repository" "refs/tags/$tag" "refs/tags/$tag^{}")
direct=$(awk -v ref="refs/tags/$tag" '$2 == ref { print $1 }' <<<"$listing")
peeled=$(awk -v ref="refs/tags/$tag^{}" '$2 == ref { print $1 }' <<<"$listing")
resolved=${peeled:-$direct}

if ! [[ "$resolved" =~ ^[0-9a-f]{40}$ ]]; then
  echo "tag $tag did not resolve to one commit" >&2
  exit 1
fi

if [ "$resolved" != "$expected" ]; then
  echo "tag $tag resolved to $resolved, expected $expected" >&2
  exit 1
fi

printf '%s -> %s\n' "$tag" "$resolved"
