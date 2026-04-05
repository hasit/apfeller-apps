#!/bin/sh

set -eu

target=${APFELLER_INPUT:-.}

if [ ! -d "$target" ]; then
  printf '%s\n' "Error: $target is not a directory." >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)

print_file_excerpt() {
  path=$1
  [ -f "$path" ] || return 0
  printf '\n%s:\n' "$(basename "$path")"
  sed -n '1,30p' "$path"
}

printf '%s\n' "Summarize this local directory or project."
printf 'Directory: %s\n' "$target"

printf '\nDirectory listing:\n'
(CDPATH= cd -- "$target" && find . -maxdepth 2 \
  \( -name .git -o -name node_modules -o -name .venv -o -name vendor -o -name dist -o -name build \) -prune -o \
  -mindepth 1 -print 2>/dev/null | sort | head -40) || true

for candidate in \
  README.md \
  README \
  readme.md \
  Package.swift \
  package.json \
  Cargo.toml \
  go.mod \
  pyproject.toml \
  requirements.txt \
  Gemfile \
  Makefile \
  Dockerfile \
  docker-compose.yml
do
  print_file_excerpt "$target/$candidate"
done

if git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$target" branch --show-current 2>/dev/null || true)
  last_commit=$(git -C "$target" log --oneline -1 2>/dev/null || true)
  status=$(git -C "$target" status --short --untracked-files=all 2>/dev/null | head -20 || true)

  printf '\nGit:\n'
  printf 'branch: %s\n' "${branch:-detached-or-empty}"
  [ -n "$last_commit" ] && printf 'last commit: %s\n' "$last_commit"
  if [ -n "$status" ]; then
    printf 'status:\n%s\n' "$status"
  fi
fi
