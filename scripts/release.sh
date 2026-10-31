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

if [[ "$(git branch --show-current)" != main ]]; then
  echo 'Releases must start from main.' >&2
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

dart run melos version --no-git-commit-version "$@"
after="$(version)"

if [[ "$before" == "$after" ]]; then
  echo 'Nothing to release.'
  exit 0
fi

branch="release/v$after"
title="chore(release): Publish v$after"

git switch -c "$branch"
git add -A
git commit -m "$title"
git push -u origin "$branch"
gh pr create --base main --title "$title" --body "Merging this publishes v$after."

git switch main
