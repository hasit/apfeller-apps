#!/bin/sh

set -eu

excerpt_file() {
  path=$1
  head_lines=$2
  tail_lines=$3

  total_lines=$(wc -l <"$path" | awk '{print $1}')

  if [ "$total_lines" -le $((head_lines + tail_lines)) ]; then
    sed -n "1,${total_lines}p" "$path"
    return 0
  fi

  sed -n "1,${head_lines}p" "$path"
  printf '\n[... %s lines omitted ...]\n' "$((total_lines - head_lines - tail_lines))"
  tail -n "$tail_lines" "$path"
}

stdin_text=
if [ ! -t 0 ]; then
  stdin_text=$(cat)
fi

if [ -n "${APFELLER_ARG_FILE:-}" ] && [ ! -f "$APFELLER_ARG_FILE" ]; then
  printf '%s\n' "Error: $APFELLER_ARG_FILE does not exist." >&2
  exit 1
fi

if [ -z "${APFELLER_INPUT:-}" ] && [ -z "$stdin_text" ] && [ -z "${APFELLER_ARG_FILE:-}" ]; then
  printf '%s\n' "Error: log-digest needs input from arguments, stdin, or --file." >&2
  exit 1
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/log-digest.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

printf '%s\n' "Digest these logs into a first diagnosis."

if [ -n "${APFELLER_ARG_FILE:-}" ]; then
  printf '\nFile source: %s\n' "$APFELLER_ARG_FILE"
  excerpt_file "$APFELLER_ARG_FILE" 60 30
fi

if [ -n "${APFELLER_INPUT:-}" ]; then
  arg_path="$tmp_dir/arg.txt"
  printf '%s\n' "$APFELLER_INPUT" >"$arg_path"
  printf '\nArgument input:\n'
  excerpt_file "$arg_path" 40 20
fi

if [ -n "$stdin_text" ]; then
  stdin_path="$tmp_dir/stdin.txt"
  printf '%s\n' "$stdin_text" >"$stdin_path"
  printf '\nStdin input:\n'
  excerpt_file "$stdin_path" 60 30
fi
