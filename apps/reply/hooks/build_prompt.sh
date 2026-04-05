#!/bin/sh

set -eu

stdin_text=
if [ ! -t 0 ]; then
  stdin_text=$(cat)
fi

if [ -z "${APFELLER_INPUT:-}" ] && [ -z "$stdin_text" ]; then
  printf '%s\n' "Error: reply needs input from arguments or stdin." >&2
  exit 1
fi

printf '%s\n' "Draft a reply from the following context."
printf 'Tone: %s\n' "${APFELLER_ARG_TONE:-neutral}"
printf 'Length: %s\n' "${APFELLER_ARG_LENGTH:-short}"

if [ -n "${APFELLER_INPUT:-}" ]; then
  printf '\nArgument input:\n'
  printf '%s\n' "$APFELLER_INPUT" | sed -n '1,120p'
fi

if [ -n "$stdin_text" ]; then
  printf '\nStdin input:\n'
  printf '%s\n' "$stdin_text" | sed -n '1,120p'
fi
