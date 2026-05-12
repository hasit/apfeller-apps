#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

cat <<'EOF'
Find one best English word for this clue.

Output exactly 5 lines total:
Line 1: Did you mean:
Line 2: blank
Line 3: best word * simple pronunciation
Line 4: short meaning
Line 5: short example sentence using the word

Rules:
Choose one best match only.
For misspellings, use the corrected dictionary spelling.
For meaning clues, choose a word that matches the clue, not the opposite.
Do not list alternatives.
Do not repeat any line.
Do not write labels such as Example:.
Stop after line 5.
EOF
printf '\nClue:\n%s\n' "$APFELLER_INPUT"
