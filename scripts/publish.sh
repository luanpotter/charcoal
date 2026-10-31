#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

dart pub get

packages=(charcoal charcoal_builder)

for package in "${packages[@]}"; do
  dart pub publish --dry-run --directory="packages/$package"
done

if [[ "${1:-}" == "--dry-run" ]]; then
  exit 0
fi

for package in "${packages[@]}"; do
  version="$(awk '/^version:/ { print $2 }' "packages/$package/pubspec.yaml")"
  if curl -fsS -o /dev/null "https://pub.dev/api/packages/$package/versions/$version" 2>/dev/null; then
    echo "$package $version is already on pub.dev, skipping."
    continue
  fi
  dart pub publish --force --directory="packages/$package"
done
