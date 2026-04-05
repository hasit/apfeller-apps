#!/bin/sh

set -eu

count=${APFELLER_ARG_COUNT:-10}

case "$count" in
  ''|*[!0-9]*|0)
    printf '%s\n' "Error: --count must be a positive integer." >&2
    exit 1
    ;;
esac

in_repo=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  in_repo=1
fi

if [ "$in_repo" = "0" ] && [ -z "${APFELLER_INPUT:-}" ]; then
  printf '%s\n' "Error: standup needs a git repository or an explicit note." >&2
  exit 1
fi

printf '%s\n' "Prepare a daily standup update."

if [ "$in_repo" = "1" ]; then
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  branch=$(git branch --show-current 2>/dev/null || true)
  status=$(git status --short --untracked-files=all 2>/dev/null | head -40 || true)
  diffstat=$(git diff --no-color --stat HEAD 2>/dev/null | head -30 || true)

  if git rev-parse HEAD >/dev/null 2>&1; then
    commits=$(git log --date=short --pretty=format:'%ad %h %s' -n "$count" 2>/dev/null || true)
  else
    commits="No commits yet."
  fi

  printf 'Repository: %s\n' "$repo_root"
  printf 'Branch: %s\n' "${branch:-detached-or-empty}"
  printf '\nRecent commits:\n%s\n' "$commits"
  if [ -n "$status" ]; then
    printf '\nWorking tree status:\n%s\n' "$status"
  fi
  if [ -n "$diffstat" ]; then
    printf '\nDiff stat:\n%s\n' "$diffstat"
  fi
fi

if [ -n "${APFELLER_INPUT:-}" ]; then
  printf '\nExtra note:\n%s\n' "$APFELLER_INPUT"
fi
