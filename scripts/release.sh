#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

version() {
  awk '/^version:/ { print $2 }' packages/charcoal/pubspec.yaml
}

if [[ -n "$(git status --porcelain)" ]]; then
  echo 'The working tree must be clean to release.' >&2
  exit 1
fi

git pull --ff-only
scripts/check.sh

before="$(version)"

range=HEAD
if git rev-parse --quiet --verify "refs/tags/v$before" >/dev/null; then
  range="v$before..HEAD"
fi
echo "Current version: $before. Pending commits:"
git --no-pager log --oneline "$range" -- packages

dart run melos version "$@"
after="$(version)"

if [[ "$before" == "$after" ]]; then
  echo 'Nothing was released.'
  exit 0
fi

git push --atomic origin main "v$after"
