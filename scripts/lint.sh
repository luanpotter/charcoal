#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

format_args=(--output=none --set-exit-if-changed)
if [[ "${1:-}" == "--fix" ]]; then
  format_args=()
fi

dart format "${format_args[@]}" .
dart analyze --fatal-infos .
