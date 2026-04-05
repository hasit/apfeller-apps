#!/bin/sh

set -eu

if [ "${APFELLER_ARG_WATCH:-0}" != "1" ]; then
  exit 0
fi

interval=${APFELLER_ARG_INTERVAL:-60}
case "$interval" in
  ''|*[!0-9]*|0)
    printf '%s\n' "Error: --interval must be a positive integer." >&2
    exit 1
    ;;
esac

printf '%s\n\n' "mac-narrator watching every ${interval}s (Ctrl+C to stop)"

while :; do
  apfeller __run-app "$APFELLER_APP_DIR" --interval "$interval"
  printf '\n'
  sleep "$interval"
done
