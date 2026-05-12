#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

case "$APFELLER_INPUT" in
  *" "*)
    input_kind="usage clue or phrase"
    input_rule="For this input, output up to three genuinely different suggestion blocks."
    ;;
  *)
    input_kind="single token"
    input_rule="For this input, output exactly one suggestion block unless two genuinely different common words are plausible. Do not pad to three."
    ;;
esac

cat <<'EOF'
Find likely English dictionary words for the clue below.

Rules:
If the clue starts with "word for" or describes a meaning, suggest words that mean the described idea.
Do not suggest the opposite meaning.
For "word for saying a lot in few words", good answers are succinct, concise, and terse. Bad answer: verbose.
For "sussinct" or "susinct", good answer: succinct.
Return unique suggestions only.
If there is only one plausible candidate, output exactly one block and stop.
For single-word misspellings, usually output exactly one correction block.
If you are about to repeat a candidate word, stop instead.
Do not use bullets, numbering, labels, or markdown.
Do not start any line with *, -, or a number.
Each candidate line starts with the word itself, like succinct * /səkˈsɪŋkt/.
Each suggestion block has exactly one candidate word.
Never put three candidate-word lines together as one block.
The meaning line must be a definition sentence, not another word with pronunciation.
The example line must be a complete sentence using the candidate word.
Do not repeat the same block.
Use simple readable pronunciation when IPA is uncertain.

Good output for "cannonical":
Did you mean:

canonical * kuh-NON-ih-kul
Accepted as authoritative or standard.
Use the canonical spelling in the documentation.

Bad output for "cannonical": three repeated canonical blocks.

Good output shape:
Did you mean:

succinct * /səkˈsɪŋkt/
Briefly and clearly expressed.
Her succinct answer explained the issue in one sentence.

concise * /kənˈsaɪs/
Giving much information clearly in few words.
The concise report was easy to understand.
EOF

printf '\nInput type: %s\n' "$input_kind"
printf '%s\n' "$input_rule"
printf '\nClue:\n%s\n' "$APFELLER_INPUT"
