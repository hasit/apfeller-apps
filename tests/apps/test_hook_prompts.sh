#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT_DIR/tests/helpers/assert.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP

manifest_limit() {
  manifest_path=$1
  awk '$1 == "max_input_bytes" { print $3; exit }' "$manifest_path"
}

assert_prompt_fits() {
  manifest_path=$1
  prompt_text=$2

  limit=$(manifest_limit "$manifest_path")
  bytes=$(LC_ALL=C printf '%s' "$prompt_text" | wc -c | awk '{print $1}')

  if [ "$bytes" -gt "$limit" ]; then
    printf 'Prompt exceeded max_input_bytes for %s (%s > %s)\n' "$manifest_path" "$bytes" "$limit" >&2
    exit 1
  fi
}

setup_repo() {
  repo_path=$1

  git init -q "$repo_path"
  git -C "$repo_path" config user.name "Test User"
  git -C "$repo_path" config user.email "test@example.com"
}

commit_file() {
  repo_path=$1
  file_name=$2
  content=$3
  message=$4

  printf '%s\n' "$content" >"$repo_path/$file_name"
  git -C "$repo_path" add "$file_name"
  git -C "$repo_path" commit -q -m "$message"
}

wtd_clean="$tmp_dir/wtd-clean"
mkdir -p "$wtd_clean/src"
printf '%s\n' "# Sample App" "A tiny Node app." >"$wtd_clean/README.md"
printf '%s\n' '{' '  "name": "sample-app",' '  "scripts": {"start": "node src/index.js"}' '}' >"$wtd_clean/package.json"
printf '%s\n' 'console.log("hello")' >"$wtd_clean/src/index.js"
wtd_clean_prompt=$(APFELLER_INPUT="$wtd_clean" sh "$ROOT_DIR/apps/wtd/hooks/build_prompt.sh")
assert_contains "$wtd_clean_prompt" "Directory: $wtd_clean" "wtd should include the requested path"
assert_contains "$wtd_clean_prompt" "package.json:" "wtd should include key manifest files"
assert_prompt_fits "$ROOT_DIR/apps/wtd/app.toml" "$wtd_clean_prompt"

wtd_noisy="$tmp_dir/wtd-noisy"
mkdir -p "$wtd_noisy/src"
setup_repo "$wtd_noisy"
printf '%s\n' "# Service" "Python worker." >"$wtd_noisy/README.md"
printf '%s\n' '[project]' 'name = "worker"' >"$wtd_noisy/pyproject.toml"
printf '%s\n' 'print("worker")' >"$wtd_noisy/src/app.py"
git -C "$wtd_noisy" add README.md pyproject.toml src/app.py
git -C "$wtd_noisy" commit -q -m "Initial worker"
printf '%s\n' 'debug = true' >"$wtd_noisy/local.toml"
wtd_noisy_prompt=$(APFELLER_INPUT="$wtd_noisy" sh "$ROOT_DIR/apps/wtd/hooks/build_prompt.sh")
assert_contains "$wtd_noisy_prompt" "Git:" "wtd should include git metadata when present"
assert_contains "$wtd_noisy_prompt" "status:" "wtd should include git status when dirty"
assert_prompt_fits "$ROOT_DIR/apps/wtd/app.toml" "$wtd_noisy_prompt"

wtd_minimal="$tmp_dir/wtd-minimal"
mkdir -p "$wtd_minimal"
wtd_minimal_prompt=$(APFELLER_INPUT="$wtd_minimal" sh "$ROOT_DIR/apps/wtd/hooks/build_prompt.sh")
assert_contains "$wtd_minimal_prompt" "Directory listing:" "wtd should handle empty directories"
assert_prompt_fits "$ROOT_DIR/apps/wtd/app.toml" "$wtd_minimal_prompt"

explain_clean=$(APFELLER_INPUT='git diff --stat HEAD~1' sh "$ROOT_DIR/apps/explain/hooks/build_prompt.sh")
assert_contains "$explain_clean" "Argument input:" "explain should include positional input"
assert_prompt_fits "$ROOT_DIR/apps/explain/app.toml" "$explain_clean"

explain_noisy=$(printf '%s\n' 'Traceback (most recent call last):' 'ValueError: bad token' | sh "$ROOT_DIR/apps/explain/hooks/build_prompt.sh")
assert_contains "$explain_noisy" "Stdin input:" "explain should accept stdin"
assert_contains "$explain_noisy" "ValueError: bad token" "explain should preserve noisy input"
assert_prompt_fits "$ROOT_DIR/apps/explain/app.toml" "$explain_noisy"

explain_minimal=$(printf '%s\n' 'SIGPIPE' | sh "$ROOT_DIR/apps/explain/hooks/build_prompt.sh")
assert_contains "$explain_minimal" "SIGPIPE" "explain should handle minimal input"
assert_prompt_fits "$ROOT_DIR/apps/explain/app.toml" "$explain_minimal"

gitsum_clean="$tmp_dir/gitsum-clean"
mkdir -p "$gitsum_clean"
setup_repo "$gitsum_clean"
commit_file "$gitsum_clean" README.md "# Demo" "Add README"
commit_file "$gitsum_clean" app.txt "hello" "Add app"
gitsum_clean_prompt=$(cd "$gitsum_clean" && APFELLER_ARG_COUNT=5 sh "$ROOT_DIR/apps/gitsum/hooks/build_prompt.sh")
assert_contains "$gitsum_clean_prompt" "Recent commits:" "gitsum should include commit history"
assert_prompt_fits "$ROOT_DIR/apps/gitsum/app.toml" "$gitsum_clean_prompt"

gitsum_noisy="$tmp_dir/gitsum-noisy"
mkdir -p "$gitsum_noisy"
setup_repo "$gitsum_noisy"
commit_file "$gitsum_noisy" README.md "# Demo" "Initial commit"
printf '%s\n' "line one" "line two" >"$gitsum_noisy/README.md"
gitsum_noisy_prompt=$(cd "$gitsum_noisy" && APFELLER_ARG_DIFF=1 sh "$ROOT_DIR/apps/gitsum/hooks/build_prompt.sh")
assert_contains "$gitsum_noisy_prompt" "Diff stat:" "gitsum should include diff context in diff mode"
assert_prompt_fits "$ROOT_DIR/apps/gitsum/app.toml" "$gitsum_noisy_prompt"

gitsum_minimal="$tmp_dir/gitsum-minimal"
mkdir -p "$gitsum_minimal"
setup_repo "$gitsum_minimal"
gitsum_minimal_prompt=$(cd "$gitsum_minimal" && sh "$ROOT_DIR/apps/gitsum/hooks/build_prompt.sh")
assert_contains "$gitsum_minimal_prompt" "No commits yet." "gitsum should handle empty repositories"
assert_prompt_fits "$ROOT_DIR/apps/gitsum/app.toml" "$gitsum_minimal_prompt"

log_arg_prompt=$(APFELLER_INPUT='fatal error: missing module graph' sh "$ROOT_DIR/apps/log-digest/hooks/build_prompt.sh")
assert_contains "$log_arg_prompt" "Argument input:" "log-digest should include inline log input"
assert_prompt_fits "$ROOT_DIR/apps/log-digest/app.toml" "$log_arg_prompt"

log_stdin_prompt=$(printf '%s\n' 'FAIL test_login' 'AssertionError: expected 200 got 500' | sh "$ROOT_DIR/apps/log-digest/hooks/build_prompt.sh")
assert_contains "$log_stdin_prompt" "Stdin input:" "log-digest should accept stdin logs"
assert_contains "$log_stdin_prompt" "AssertionError: expected 200 got 500" "log-digest should preserve noisy log lines"
assert_prompt_fits "$ROOT_DIR/apps/log-digest/app.toml" "$log_stdin_prompt"

log_file="$tmp_dir/build.log"
printf '%s\n' 'CompileSwift normal arm64' 'error: cannot find type Config' >"$log_file"
log_file_prompt=$(APFELLER_ARG_FILE="$log_file" sh "$ROOT_DIR/apps/log-digest/hooks/build_prompt.sh")
assert_contains "$log_file_prompt" "File source: $log_file" "log-digest should include file input"
assert_prompt_fits "$ROOT_DIR/apps/log-digest/app.toml" "$log_file_prompt"

cliptag_clean=$(APFELLER_INPUT='Ship beta on Friday and email design before lunch.' sh "$ROOT_DIR/apps/cliptag/hooks/build_prompt.sh")
assert_contains "$cliptag_clean" "Argument input:" "cliptag should include argument input"
assert_prompt_fits "$ROOT_DIR/apps/cliptag/app.toml" "$cliptag_clean"

cliptag_noisy=$(printf '%s\n' 'Customer sounded relieved but still wants a refund and a follow-up call.' | sh "$ROOT_DIR/apps/cliptag/hooks/build_prompt.sh")
assert_contains "$cliptag_noisy" "Stdin input:" "cliptag should accept stdin"
assert_prompt_fits "$ROOT_DIR/apps/cliptag/app.toml" "$cliptag_noisy"

cliptag_minimal=$(printf '%s\n' 'invoice' | sh "$ROOT_DIR/apps/cliptag/hooks/build_prompt.sh")
assert_contains "$cliptag_minimal" "invoice" "cliptag should handle minimal text"
assert_prompt_fits "$ROOT_DIR/apps/cliptag/app.toml" "$cliptag_minimal"

todo_clean=$(APFELLER_INPUT='Send revised contract by Tuesday and book follow-up.' sh "$ROOT_DIR/apps/todo/hooks/build_prompt.sh")
assert_contains "$todo_clean" "Argument input:" "todo should include argument input"
assert_prompt_fits "$ROOT_DIR/apps/todo/app.toml" "$todo_clean"

todo_noisy=$(printf '%s\n' 'Alice owns launch checklist.' 'Demo next Thursday at 3pm.' | sh "$ROOT_DIR/apps/todo/hooks/build_prompt.sh")
assert_contains "$todo_noisy" "Stdin input:" "todo should accept stdin"
assert_prompt_fits "$ROOT_DIR/apps/todo/app.toml" "$todo_noisy"

todo_minimal=$(printf '%s\n' 'Call finance.' | sh "$ROOT_DIR/apps/todo/hooks/build_prompt.sh")
assert_contains "$todo_minimal" "Call finance." "todo should handle brief notes"
assert_prompt_fits "$ROOT_DIR/apps/todo/app.toml" "$todo_minimal"

reply_clean=$(APFELLER_INPUT='Can we move the demo to tomorrow?' APFELLER_ARG_TONE=warm APFELLER_ARG_LENGTH=short sh "$ROOT_DIR/apps/reply/hooks/build_prompt.sh")
assert_contains "$reply_clean" "Tone: warm" "reply should include tone"
assert_contains "$reply_clean" "Length: short" "reply should include length"
assert_prompt_fits "$ROOT_DIR/apps/reply/app.toml" "$reply_clean"

reply_noisy=$(printf '%s\n' 'Hi team,' 'The build is still broken on CI and we need a status update.' | APFELLER_ARG_TONE=firm APFELLER_ARG_LENGTH=medium sh "$ROOT_DIR/apps/reply/hooks/build_prompt.sh")
assert_contains "$reply_noisy" "Stdin input:" "reply should accept stdin"
assert_prompt_fits "$ROOT_DIR/apps/reply/app.toml" "$reply_noisy"

reply_minimal=$(printf '%s\n' 'Thanks!' | sh "$ROOT_DIR/apps/reply/hooks/build_prompt.sh")
assert_contains "$reply_minimal" "Thanks!" "reply should handle short context"
assert_prompt_fits "$ROOT_DIR/apps/reply/app.toml" "$reply_minimal"

standup_clean="$tmp_dir/standup-clean"
mkdir -p "$standup_clean"
setup_repo "$standup_clean"
commit_file "$standup_clean" plan.md "todo" "Add plan"
standup_clean_prompt=$(cd "$standup_clean" && sh "$ROOT_DIR/apps/standup/hooks/build_prompt.sh")
assert_contains "$standup_clean_prompt" "Recent commits:" "standup should include git history"
assert_prompt_fits "$ROOT_DIR/apps/standup/app.toml" "$standup_clean_prompt"

standup_noisy="$tmp_dir/standup-noisy"
mkdir -p "$standup_noisy"
setup_repo "$standup_noisy"
commit_file "$standup_noisy" notes.md "done" "Initial notes"
printf '%s\n' 'follow-up' >"$standup_noisy/today.md"
standup_noisy_prompt=$(cd "$standup_noisy" && APFELLER_INPUT='Need to mention QA is blocked.' sh "$ROOT_DIR/apps/standup/hooks/build_prompt.sh")
assert_contains "$standup_noisy_prompt" "Working tree status:" "standup should include dirty tree context"
assert_contains "$standup_noisy_prompt" "Extra note:" "standup should include optional notes"
assert_prompt_fits "$ROOT_DIR/apps/standup/app.toml" "$standup_noisy_prompt"

standup_note_only=$(APFELLER_INPUT='Waiting on product copy approval.' sh "$ROOT_DIR/apps/standup/hooks/build_prompt.sh")
assert_contains "$standup_note_only" "Extra note:" "standup should handle note-only mode"
assert_prompt_fits "$ROOT_DIR/apps/standup/app.toml" "$standup_note_only"

naming_clean=$(APFELLER_INPUT='function that retries HTTP requests with backoff' APFELLER_ARG_STYLE=camel sh "$ROOT_DIR/apps/naming/hooks/build_prompt.sh")
assert_contains "$naming_clean" "Requested style: camel" "naming should include the requested style"
assert_prompt_fits "$ROOT_DIR/apps/naming/app.toml" "$naming_clean"

naming_noisy=$(printf '%s\n' 'internal dashboard for release readiness' | APFELLER_ARG_STYLE=title sh "$ROOT_DIR/apps/naming/hooks/build_prompt.sh")
assert_contains "$naming_noisy" "Stdin input:" "naming should accept stdin"
assert_prompt_fits "$ROOT_DIR/apps/naming/app.toml" "$naming_noisy"

naming_minimal=$(printf '%s\n' 'cache' | sh "$ROOT_DIR/apps/naming/hooks/build_prompt.sh")
assert_contains "$naming_minimal" "cache" "naming should handle minimal input"
assert_prompt_fits "$ROOT_DIR/apps/naming/app.toml" "$naming_minimal"

stub_dir="$tmp_dir/port-stubs"
mkdir -p "$stub_dir"

cat >"$stub_dir/lsof" <<'EOF'
#!/bin/sh

case "${PORT_SCENARIO:-none}" in
  clean)
    printf '%s\n' "COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME"
    printf '%s\n' "node     1234 hasit   22u  IPv4 0x000000000000      0t0  TCP *:3000 (LISTEN)"
    ;;
  noisy)
    printf '%s\n' "COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME"
    printf '%s\n' "node     1234 hasit   22u  IPv4 0x000000000000      0t0  TCP *:3000 (LISTEN)"
    printf '%s\n' "ruby     2345 hasit   11u  IPv4 0x000000000000      0t0  TCP 127.0.0.1:3000 (LISTEN)"
    ;;
  *)
    exit 0
    ;;
esac
EOF

cat >"$stub_dir/ps" <<'EOF'
#!/bin/sh

pid=
while [ $# -gt 0 ]; do
  case "$1" in
    -p)
      pid=$2
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

case "$pid" in
  1234)
    printf '%s\n' "1234 8.2 1.1 node node server.js"
    ;;
  2345)
    printf '%s\n' "2345 2.0 0.4 ruby ruby app.rb"
    ;;
esac
EOF

chmod +x "$stub_dir/lsof" "$stub_dir/ps"

port_clean=$(PATH="$stub_dir:$PATH" PORT_SCENARIO=clean APFELLER_INPUT=3000 sh "$ROOT_DIR/apps/port/hooks/build_prompt.sh")
assert_contains "$port_clean" "Listeners:" "port should include listener data"
assert_prompt_fits "$ROOT_DIR/apps/port/app.toml" "$port_clean"

port_noisy=$(PATH="$stub_dir:$PATH" PORT_SCENARIO=noisy APFELLER_INPUT=3000 sh "$ROOT_DIR/apps/port/hooks/build_prompt.sh")
assert_contains "$port_noisy" "Process details:" "port should include process metadata"
assert_prompt_fits "$ROOT_DIR/apps/port/app.toml" "$port_noisy"

port_minimal=$(PATH="$stub_dir:$PATH" PORT_SCENARIO=none APFELLER_INPUT=5432 sh "$ROOT_DIR/apps/port/hooks/build_prompt.sh")
assert_contains "$port_minimal" "No process appears to be listening" "port should handle unused ports"
assert_prompt_fits "$ROOT_DIR/apps/port/app.toml" "$port_minimal"
