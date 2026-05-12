#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

cat <<'EOF'
Find one best English word for this clue.

Return only this format, replacing the placeholders:
Did you mean:

word * pronunciation
meaning
example sentence

Rules:
Choose one best match only.
For misspellings, use the corrected dictionary spelling.
For meaning clues, choose a word that matches the clue, not the opposite.
Keep the word and pronunciation on the same line.
The only asterisk may be between the word and pronunciation.
Do not start any line with *, -, or a number.
Do not list alternatives.
Do not repeat any line.
Do not write labels such as Example:.
Do not write notes.
Stop after the example sentence.
EOF
printf '\nClue:\n%s\n' "$APFELLER_INPUT"
