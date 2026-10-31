#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

dart pub get
dart run melos bootstrap

melos_args=(--depends-on=build_runner --concurrency=1 --fail-fast)
dart run melos exec "${melos_args[@]}" -- dart run build_runner build
