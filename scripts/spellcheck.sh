#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

dictionary=.github/.cspell/words_dictionary.txt
spellcheck=(cspell --no-progress -c .github/cspell.json '**/*.{md,dart}')

"${spellcheck[@]}"
LC_ALL=C sort -c "$dictionary"

words=$("${spellcheck[@]}" --disable-dictionary words_dictionary --no-summary --unique --words-only || true)
unused=$(LC_ALL=C comm -23 "$dictionary" <(tr '[:upper:]' '[:lower:]' <<<"$words" | LC_ALL=C sort -u))
if [[ -n "$unused" ]]; then
  echo "Unused words in $dictionary: $unused" >&2
  exit 1
fi
