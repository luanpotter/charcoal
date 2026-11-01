#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root="$PWD"

libraries=(charcoal json_serializable dart_mappable freezed)
if [[ "${1:-}" == "--only" ]]; then
  libraries=("$2")
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/results"

build() {
  local library="$1"
  local project="$work/$library"
  mkdir "$project"
  cp -r benchmark/shared/. "benchmark/$library/." "$project"

  (
    cd "$project"
    if [[ "$library" == "charcoal" ]]; then
      dart pub add "override:charcoal:{path: $root/packages/charcoal}" \
        "override:charcoal_builder:{path: $root/packages/charcoal_builder}"
    fi
    dart pub get
    local start="$SECONDS"
    dart run build_runner build
    echo "$((SECONDS - start))" >"$work/results/$library.seconds"
    dart analyze
    dart compile exe bin/main.dart -o bench
  ) >&2
}

for library in "${libraries[@]}"; do
  build "$library"
  "$work/$library/bench" | tee "$work/results/$library.txt"
done

if [[ "${#libraries[@]}" -gt 1 ]]; then
  echo
  (cd "$work/results" && awk -v libraries="${libraries[*]}" -f "$root/benchmark/table.awk" ./*.txt)

  echo
  printf '%-20s%16s%16s%16s\n' library 'build (s)' 'generated (KB)' 'exe (KB)'
  for library in "${libraries[@]}"; do
    project="$work/$library"
    generated="$(find "$project/lib" \( -name '*.g.dart' -o -name '*.mapper.dart' -o -name '*.freezed.dart' \) -exec cat {} + | wc -c)"
    exe="$(wc -c <"$project/bench")"
    printf '%-20s%16s%16s%16s\n' "$library" "$(cat "$work/results/$library.seconds")" "$((generated / 1024))" "$((exe / 1024))"
  done
fi
