#!/bin/sh

set -eu

stdin_text=
if [ ! -t 0 ]; then
  stdin_text=$(cat)
fi

if [ -z "${APFELLER_INPUT:-}" ] && [ -z "$stdin_text" ]; then
  printf '%s\n' "Error: naming needs input from arguments or stdin." >&2
  exit 1
fi

printf '%s\n' "Suggest names for the described thing."
printf 'Requested style: %s\n' "${APFELLER_ARG_STYLE:-mixed}"

if [ -n "${APFELLER_INPUT:-}" ]; then
  printf '\nArgument input:\n'
  printf '%s\n' "$APFELLER_INPUT" | sed -n '1,80p'
fi

if [ -n "$stdin_text" ]; then
  printf '\nStdin input:\n'
  printf '%s\n' "$stdin_text" | sed -n '1,80p'
fi
