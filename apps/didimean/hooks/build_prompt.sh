#!/bin/sh

set -eu

if [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: didimean needs a word, misspelling, or usage clue." >&2
  exit 1
fi

dictionary_candidate() {
  token=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')

  case "$token" in
    ''|*[!abcdefghijklmnopqrstuvwxyz]*)
      return 0
      ;;
  esac

  [ -r /usr/share/dict/words ] || return 0

  awk -v target="$token" '
    function min3(a, b, c) {
      m = a
      if (b < m) m = b
      if (c < m) m = c
      return m
    }

    function distance(a, b,    la, lb, i, j, cost, prev, curr) {
      la = length(a)
      lb = length(b)
      for (j = 0; j <= lb; j++) prev[j] = j
      for (i = 1; i <= la; i++) {
        curr[0] = i
        for (j = 1; j <= lb; j++) {
          cost = (substr(a, i, 1) == substr(b, j, 1)) ? 0 : 1
          curr[j] = min3(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
        }
        for (j = 0; j <= lb; j++) prev[j] = curr[j]
      }
      return prev[lb]
    }

    BEGIN {
      first = substr(target, 1, 1)
      best = ""
      best_distance = 999
    }

    /^[[:alpha:]]+$/ {
      word = tolower($0)
      if (word != $0) next
      if (substr(word, 1, 1) != first) next

      length_delta = length(word) - length(target)
      if (length_delta < 0) length_delta = -length_delta
      if (length_delta > 2) next

      d = distance(target, word)
      if (d < best_distance || (d == best_distance && length(word) < length(best))) {
        best_distance = d
        best = word
      }
    }

    END {
      if (best != "" && best_distance <= 2) {
        print best
      }
    }
  ' /usr/share/dict/words
}

candidate=
case "$APFELLER_INPUT" in
  *" "*)
    ;;
  *)
    candidate=$(dictionary_candidate "$APFELLER_INPUT")
    ;;
esac

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

if [ -n "$candidate" ]; then
  printf '\nLocal dictionary candidate: %s\n' "$candidate"
  printf 'Use the local dictionary candidate as the word.\n'
  printf 'The third output line must begin with: %s *\n' "$candidate"
fi

printf '\nClue:\n%s\n' "$APFELLER_INPUT"
