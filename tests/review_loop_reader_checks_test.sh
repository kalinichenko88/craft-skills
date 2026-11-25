#!/usr/bin/env bash
# Runs tests/review_loop_reader_eval.sh with no model, with stubs of claude
# and codex first on PATH. A wrong call must exit 2 before a paid run starts.
# --check counts hand-written reports: the count of each defect, the floor of
# a case, a failed read, and a defect that the lens named before and names in
# no run now. One whole run of a case of two trees gives the stub of claude
# the prompt of the product, and counts its report.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
fixtures=tests/fixtures/review_loop_reader

stub=$(mktemp -d)
trap 'rm -rf "$stub"' EXIT
# claude records each call and its prompt, and answers with a stream that
# holds a call of worklist.sh and a report; codex records each exec, and
# fails `login status`.
cat >"$stub/claude" <<'EOF'
#!/usr/bin/env bash
here=$(dirname "$0")
touch "$here/called"
printf '%s\n' "$@" >"$here/args"
cat >"$here/prompt"
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"bash /x/skills/review-loop/scripts/worklist.sh abc def"}}]}}'
echo '{"type":"result","is_error":false,"result":"a.sh:2 | the check of the release is gone | an import that only the release build refuses\ncount: 1"}'
EOF
cat >"$stub/codex" <<'EOF'
#!/usr/bin/env bash
[ "$1" != exec ] || touch "$(dirname "$0")/called"
exit 1
EOF
chmod +x "$stub/claude" "$stub/codex"
for tool in claude codex; do
  found=$(PATH="$stub:$PATH" command -v "$tool" || true)
  [ "$found" = "$stub/$tool" ] || {
    echo "FAIL: $tool is '$found', not the stub $stub/$tool"
    exit 1
  }
done

# refused <message> <argument>...: the eval must exit 2 with <message> on
# stderr and run neither claude nor codex exec.
refused() {
  local message=$1 code=0 err
  shift
  rm -f "$stub/called"
  err=$(PATH="$stub:$PATH" tests/review_loop_reader_eval.sh "$@" 2>&1 >/dev/null) || code=$?
  if [ "$code" != 2 ] || [ "${err#*"$message"}" = "$err" ] || [ -e "$stub/called" ]; then
    echo "FAIL: '$*' exited $code with '$err': it must exit 2 with '$message' and start no run"
    exit 1
  fi
}
refused usage: 3 --codex
refused usage: --codex 3 4
refused usage: --check
refused usage: --check "$stub/nosuch"
refused 'not logged in' --codex
READER_CASES=nosuch refused 'no case nosuch'
READER_LEVEL=max refused usage:

# counted <folder> <exit>: --check on the folder prints its expected.txt.
counted() {
  local code=0 got
  got=$(PATH="$stub:$PATH" tests/review_loop_reader_eval.sh --check "$fixtures/$1" 2>&1) || code=$?
  if [ "$code" != "$2" ] || [ "$got" != "$(cat "$fixtures/$1/expected.txt")" ]; then
    echo "FAIL: --check $1 exited $code, not $2, or printed other lines than its expected.txt:"
    echo "$got"
    exit 1
  fi
}
counted named 0
counted below 1

# One whole run of a private case of two trees, as READER_LOCAL gives it.
mkdir -p "$stub/local/one/main" "$stub/local/one/review"
printf 'case\tone\tone\tcode-lens.md\t3\ndefect\tone\tX\ta\\.sh\trelease\t0\n' >"$stub/local/cases.tsv"
echo 'npm run build' >"$stub/local/one/main/a.sh"
echo 'npm run check' >"$stub/local/one/review/a.sh"
rm -f "$stub/called"
code=0
got=$(PATH="$stub:$PATH" READER_LOCAL="$stub/local" READER_CASES=one tests/review_loop_reader_eval.sh 1 2>&1) || code=$?
logs=$(printf '%s\n' "$got" | sed -n 's/^Logs: //p')
want="one X: 1 of 1, was 0
one: 1 of 1, floor 1, 0 failed reads, 1 findings a run, ran the list 1 of 1"
if [ "$code" != 0 ] || [ "$(printf '%s\n' "$got" | sed -n 1,2p)" != "$want" ] || [ -z "$logs" ]; then
  echo "FAIL: a run of one case exited $code with:"
  echo "$got"
  exit 1
fi
range="$(git -C "$logs/one-1" rev-parse main)..$(git -C "$logs/one-1" rev-parse review)"
want="Read $root/skills/review-loop/code-lens.md and do what it says.
Range: $range
Tree: $logs/one-1
Level: high"
[ "$(cat "$stub/prompt")" = "$want" ] || {
  echo 'FAIL: the prompt of a run is not the prompt of the product:'
  cat "$stub/prompt"
  rm -rf "$logs"
  exit 1
}
[ "$(git -C "$logs/one-1" show review:a.sh)" = 'npm run check' ] &&
  [ "$(git -C "$logs/one-1" show main:a.sh)" = 'npm run build' ] || {
  echo 'FAIL: the fixture of a case of two trees is not its two commits'
  rm -rf "$logs"
  exit 1
}
rm -rf "$logs"

echo 'review_loop_reader_checks_test: ok'
