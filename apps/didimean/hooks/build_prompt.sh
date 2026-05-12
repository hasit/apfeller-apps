#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

case "$APFELLER_INPUT" in
  *" "*)
    cat <<'EOF'
Find likely English dictionary words for the usage clue or phrase below.

Rules:
If the clue starts with "word for" or describes a meaning, suggest words that mean the described idea.
Do not suggest the opposite meaning.
For "word for saying a lot in few words", good answers are succinct, concise, and terse. Bad answer: verbose.
Return unique suggestions only.
Output up to three genuinely different suggestion blocks.
Each suggestion block has exactly one candidate word.
Never put three candidate-word lines together as one block.
The meaning line must be a definition sentence, not another word with pronunciation.
The example line must be a complete sentence using the candidate word.
Do not repeat any candidate or block.
Do not use bullets, numbering, labels, markdown, or lines that start with *, -, or a number.

Output contract:
Line 1 is exactly: Did you mean:
Line 2 is blank.
Then write one or more blocks.
Each block has exactly 3 lines:
candidate word * pronunciation
concise definition sentence
natural example sentence using the candidate word
Put one blank line between blocks.
Stop immediately after the final example sentence.

Input type: usage clue or phrase
EOF
    ;;
  *)
    cat <<'EOF'
Find the likely corrected English dictionary word for the single-token clue below.

Rules:
Single-word misspellings usually need exactly one correction block.
If there is only one plausible candidate, output exactly one block and stop.
If you are about to repeat a candidate word, stop instead.
Use the corrected dictionary spelling, never the raw input unless it is already correctly spelled.
Use simple readable pronunciation when IPA is uncertain.
Do not use bullets, numbering, labels, markdown, or lines that start with *, -, or a number.
Do not write "Example:".
Do not output extra examples.

Output contract:
Output exactly 5 lines total.
Line 1 is exactly: Did you mean:
Line 2 is blank.
Line 3 is: corrected word * pronunciation
Line 4 is: concise definition sentence
Line 5 is: natural example sentence using the corrected word
Stop immediately after line 5.

Input type: single token
EOF
    ;;
esac
printf '\nClue:\n%s\n' "$APFELLER_INPUT"
