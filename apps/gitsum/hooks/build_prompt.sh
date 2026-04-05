#!/bin/sh

set -eu

count=${APFELLER_ARG_COUNT:-10}
diff_mode=${APFELLER_ARG_DIFF:-0}

case "$count" in
  ''|*[!0-9]*|0)
    printf '%s\n' "Error: --count must be a positive integer." >&2
    exit 1
    ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' "Error: gitsum must be run inside a git repository." >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
branch=$(git branch --show-current 2>/dev/null || true)
status=$(git status --short --untracked-files=all 2>/dev/null | head -40 || true)

printf '%s\n' "Summarize this git activity."
printf 'Repository: %s\n' "$repo_root"
printf 'Branch: %s\n' "${branch:-detached-or-empty}"

if [ -n "$status" ]; then
  printf '\nWorking tree status:\n%s\n' "$status"
fi

if [ "$diff_mode" = "1" ]; then
  diffstat=$(git diff --no-color --stat HEAD 2>/dev/null | head -40 || true)
  diff_excerpt=$(git diff --no-color --unified=1 HEAD 2>/dev/null | sed -n '1,120p' || true)

  printf '\nMode: current diff\n'
  if [ -n "$diffstat" ]; then
    printf '\nDiff stat:\n%s\n' "$diffstat"
  fi
  if [ -n "$diff_excerpt" ]; then
    printf '\nDiff excerpt:\n%s\n' "$diff_excerpt"
  fi
else
  if git rev-parse HEAD >/dev/null 2>&1; then
    commits=$(git log --date=short --pretty=format:'%ad %h %s' -n "$count" 2>/dev/null || true)
    authors=$(git log --format='%an' -n "$count" 2>/dev/null | sort | uniq -c | sort -rn | head -5 || true)
  else
    commits="No commits yet."
    authors=
  fi

  printf '\nMode: recent commits\n'
  printf '\nRecent commits:\n%s\n' "$commits"
  if [ -n "$authors" ]; then
    printf '\nAuthors:\n%s\n' "$authors"
  fi
fi
