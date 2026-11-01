#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

format_args=(--output=none --set-exit-if-changed)
shfmt_args=(-d)
markdownlint_args=()
if [[ "${1:-}" == "--fix" ]]; then
  format_args=()
  shfmt_args=(-w)
  markdownlint_args=(--fix)
fi

dart format "${format_args[@]}" .
dart analyze --fatal-infos .

shellcheck scripts/*.sh
shfmt -i 2 "${shfmt_args[@]}" scripts/*.sh
actionlint
markdownlint . -p scripts/markdownlintignore -c scripts/markdownlint.yaml "${markdownlint_args[@]}"
scripts/spellcheck.sh
