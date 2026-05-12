#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

cat <<'EOF'
Find one best English word for this clue.

Rules:
Choose one best match only.
For misspellings, use the corrected dictionary spelling.
For meaning clues, choose a word that matches the clue, not the opposite.
First output exactly: Did you mean:
Second output a blank line.
Third output the corrected word, space, *, space, and the pronunciation.
Fourth output a short definition sentence.
Fifth output one short example sentence using the corrected word.
Keep word and pronunciation together on the third line.
Never output the misspelled clue itself as the corrected word.
Never output the literal words "meaning" or "example sentence".
Never write Note:, Example:, or any other label.
Never start a line with *, -, or a number.
Do not list alternatives.
Stop immediately after the fifth line.
EOF
printf '\nClue:\n%s\n' "$APFELLER_INPUT"
