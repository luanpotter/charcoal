#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

dictionary=.github/.cspell/words_dictionary.txt
spellcheck=(cspell --no-progress -c .github/cspell.json '**/*.{md,dart}')

"${spellcheck[@]}"
LC_ALL=C sort -fc "$dictionary"

normalize() {
  tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
}

words=$("${spellcheck[@]}" --disable-dictionary words_dictionary --no-summary --unique --words-only || true)
unused=$(LC_ALL=C comm -23 <(normalize <"$dictionary") <(normalize <<<"$words"))
if [[ -n "$unused" ]]; then
  echo "Unused words in $dictionary: $unused" >&2
  exit 1
fi
