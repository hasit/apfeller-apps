#!/bin/sh

set -eu

port=${APFELLER_INPUT:-}

case "$port" in
  ''|*[!0-9]*)
    printf '%s\n' "Error: port expects a numeric TCP port." >&2
    exit 1
    ;;
esac

if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  printf '%s\n' "Error: port must be between 1 and 65535." >&2
  exit 1
fi

listeners=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -20 || true)
process_details=

if [ -n "$listeners" ]; then
  pids=$(printf '%s\n' "$listeners" | awk 'NR > 1 { print $2 }' | sort -u)
  for pid in $pids; do
    detail=$(ps -p "$pid" -o pid=,%cpu=,%mem=,comm=,args= 2>/dev/null || true)
    [ -n "$detail" ] || continue
    process_details=${process_details}${detail}
    process_details=${process_details}"
"
  done
fi

printf '%s\n' "Explain what is using this TCP port."
printf 'Port: %s\n' "$port"

if [ -n "$listeners" ]; then
  printf '\nListeners:\n%s\n' "$listeners"
fi

if [ -n "$process_details" ]; then
  printf '\nProcess details:\n%s' "$process_details"
fi

if [ -z "$listeners" ]; then
  printf '\nNo process appears to be listening on this port right now.\n'
fi
