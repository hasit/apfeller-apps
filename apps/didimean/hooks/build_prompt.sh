#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

cat <<'EOF'
Find likely English dictionary words for the clue below.

Rules:
If the clue starts with "word for" or describes a meaning, suggest words that mean the described idea.
Do not suggest the opposite meaning.
For "word for saying a lot in few words", good answers are succinct, concise, and terse. Bad answer: verbose.
For "sussinct" or "susinct", good answer: succinct.
Return unique suggestions only.
Do not use bullets, numbering, labels, or markdown.
Do not start any line with *, -, or a number.
Each candidate line starts with the word itself, like succinct * /səkˈsɪŋkt/.

Output shape:
Did you mean:

word * pronunciation
meaning
example sentence
EOF

printf '\nClue:\n%s\n' "$APFELLER_INPUT"
