#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

melos_args=(--dir-exists=test --concurrency=1 --fail-fast)
dart run melos exec "${melos_args[@]}" -- dart test
