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
# holds a report; codex records each exec and writes that report, is logged
# in when the file logged-in is beside it, and fails when the file fails is.
cat >"$stub/claude" <<'EOF'
#!/usr/bin/env bash
here=$(dirname "$0")
touch "$here/called"
printf '%s\n' "$@" >"$here/args"
cat >"$here/prompt"
echo '{"type":"result","is_error":false,"result":"a.sh:2 | the check of the release is gone | an import that only the release build refuses\ncount: 1"}'
EOF
cat >"$stub/codex" <<'EOF'
#!/usr/bin/env bash
here=$(dirname "$0")
case $1 in
  login) [ -e "$here/logged-in" ] ;;
  exec)
    touch "$here/called"
    printf '%s\n' "$@" >"$here/codex-args"
    while [ $# -gt 0 ]; do
      [ "$1" != -o ] || out=$2
      shift
    done
    printf '%s\n' 'a.sh:2 | the check of the release is gone | an import that only the release build refuses' 'count: 1' >"$out"
    [ ! -e "$here/fails" ]
    ;;
  *) exit 1 ;;
esac
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
# On macOS `seq 0` prints 1 and 0: two paid runs.
refused usage: 0
refused usage: x
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
# A case whose reads all failed has no mean of findings to divide.
counted failed 0
# A security case counts the things that are no hole and that a run reports.
# A note with two separators and no path:line names no defect, as the check
# of a report counts no finding for it.
counted noise 0

# Two real reports of each public case, with the cases.tsv of the eval: its
# patterns must give the table that a person made by reading the reports. One
# report is inside a code block, and one goes on after its count line. The
# "was" of a defect changes with each recorded pass, so it is cut off here,
# with the lines and the exit code that come from it.
got=$(tests/review_loop_reader_eval.sh --check "$fixtures/recorded" 2>&1 | sed -e 's/, was [0-9]*$//' -e '/^lost: /d' || true)
if [ "$got" != "$(cat "$fixtures/recorded/expected.txt")" ]; then
  echo 'FAIL: --check recorded: the patterns of cases.tsv do not give the table by reading:'
  echo "$got"
  exit 1
fi

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
one: 1 of 1, floor 1, 0 failed reads, 1 findings a run"
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

# A security case from a repository whose main moved past the branch point.
# The prompt has three lines, its range starts at the merge base, and the
# reader has the effort of the product, whatever the level of the pass.
repo=$stub/local/two
git init -q -b main "$repo"
commit() { git -C "$repo" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -qam "$1"; }
echo 'npm run build' >"$repo/a.sh"
git -C "$repo" add a.sh
commit base
git -C "$repo" checkout -qb review
echo 'npm run check' >"$repo/a.sh"
commit change
git -C "$repo" checkout -q main
echo later >>"$repo/a.sh"
commit later
printf 'case\ttwo\ttwo\tsecurity-lens.md\t0\ndefect\ttwo\tX\ta\\.sh\trelease\t0\n' >>"$stub/local/cases.tsv"
got=$(PATH="$stub:$PATH" READER_LOCAL="$stub/local" READER_CASES=two READER_LEVEL=low tests/review_loop_reader_eval.sh 1 2>&1) || true
logs=$(printf '%s\n' "$got" | sed -n 's/^Logs: //p')
want="Read $root/skills/review-loop/security-lens.md and do what it says.
Range: $(git -C "$repo" merge-base main review)..$(git -C "$repo" rev-parse review)
Tree: $logs/two-1"
[ -n "$logs" ] && [ "$(cat "$stub/prompt")" = "$want" ] || {
  echo 'FAIL: the prompt of a security case is not the prompt of the product:'
  cat "$stub/prompt"
  exit 1
}
[ "$(grep -A1 -xF -- --effort "$stub/args" | sed -n 2p)" = high ] || {
  echo 'FAIL: a security case does not run at the effort high:'
  cat "$stub/args"
  exit 1
}
rm -rf "$logs"

# Codex reads a case in its read-only sandbox, and a run of Codex that fails
# is a failed read, also when it wrote a report.
touch "$stub/logged-in"
got=$(PATH="$stub:$PATH" READER_LOCAL="$stub/local" READER_CASES=one tests/review_loop_reader_eval.sh --codex 1 2>&1) || true
logs=$(printf '%s\n' "$got" | sed -n 's/^Logs: //p')
if [ "$(printf '%s\n' "$got" | sed -n 2p)" != 'one: 1 of 1, floor 1, 0 failed reads, 1 findings a run' ] ||
  [ "$(grep -A1 -xF -- -s "$stub/codex-args" | sed -n 2p)" != read-only ] ||
  ! grep -qxF "Read $root/skills/review-loop/code-lens.md and do what it says." "$stub/codex-args"; then
  echo 'FAIL: a run of Codex on one case:'
  echo "$got"
  cat "$stub/codex-args"
  exit 1
fi
rm -rf "$logs"
touch "$stub/fails"
got=$(PATH="$stub:$PATH" READER_LOCAL="$stub/local" READER_CASES=one tests/review_loop_reader_eval.sh --codex 1 2>&1) || true
logs=$(printf '%s\n' "$got" | sed -n 's/^Logs: //p')
[ "$(printf '%s\n' "$got" | sed -n 2p)" = 'one: 0 of 1, floor 1, 1 failed reads, 0 findings a run' ] || {
  echo 'FAIL: a run of Codex that fails after its report is no failed read:'
  echo "$got"
  exit 1
}
rm -rf "$logs"
rm "$stub/logged-in" "$stub/fails"

# A case from a linked worktree, and a case from a repository whose branch
# review is checked out in a linked worktree: the eval reads each from a
# clone, and moves no branch of the source.
git -C "$repo" worktree add -q "$stub/local/three" review
printf 'case\tthree\tthree\tcode-lens.md\t0\n' >>"$stub/local/cases.tsv"
got=$(PATH="$stub:$PATH" READER_LOCAL="$stub/local" READER_CASES='two three' tests/review_loop_reader_eval.sh 1 2>&1) || true
logs=$(printf '%s\n' "$got" | sed -n 's/^Logs: //p')
if [ "$(printf '%s\n' "$got" | grep -c ', 0 failed reads, 1 findings a run$')" != 2 ] ||
  [ "$(git -C "$repo" symbolic-ref --short HEAD)" != main ] ||
  [ "$(git -C "$stub/local/three" symbolic-ref --short HEAD)" != review ] ||
  [ "$(git -C "$logs/three-1" symbolic-ref --short HEAD)" != review ]; then
  echo 'FAIL: a case whose source has a linked worktree:'
  echo "$got"
  exit 1
fi
rm -rf "$logs"

echo 'review_loop_reader_checks_test: ok'
