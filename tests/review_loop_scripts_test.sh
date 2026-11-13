#!/usr/bin/env bash
# Runs the review-loop skill's codex-review.sh against a fake codex. The fake
# answers with findings that codex exec wrote on the final head of PR #9, and
# logs the arguments of each call, so no test reaches Codex.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/review-loop/scripts/codex-review.sh
fixtures=$root/tests/fixtures/review_loop
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/bin"
cat >"$tmp/bin/codex" <<'EOF'
#!/usr/bin/env bash
case $1 in
  login)
    [ "${FAKE_LOGGED_IN:-1}" = 1 ] || { echo 'Not logged in'; exit 1; }
    echo 'Logged in using ChatGPT' ;;
  exec)
    printf '%s\n' "$@" >"$FAKE/args"
    while [ $# -gt 0 ]; do
      case $1 in
        --output-schema) cp "$2" "$FAKE/schema.json"; shift ;;
        -o) out=$2; shift ;;
      esac
      shift
    done
    echo 'codex prints its session here'
    # A run that hangs, as in #313. Under codex runs a server that ends when
    # codex ends, as a stdio MCP server on EOF, and under it a process.
    [ -z "${FAKE_HANG:-}" ] || { exec 3> >(sleep 30 & echo $! >"$FAKE/hung"; read -r _); sleep 30 3>&-; }
    [ -z "${FAKE_FAIL:-}" ] || { echo 'ERROR: stream disconnected before completion'; exit 1; }
    [ -z "${FAKE_NO_MESSAGE:-}" ] || exit 0
    cp "$FIXTURES/codex-findings.json" "$out" ;;
  *) echo "fake codex: no answer for: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/codex"
export FAKE="$tmp" FIXTURES="$fixtures"

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
check() { [ "$2" = "$3" ] || fail "$1" "$(printf 'want: %s\ngot:  %s' "$2" "$3")"; }
# running <pid>: the process runs. kill -0 also passes on a killed child that
# its new parent has not reaped yet.
running() { case $(ps -o stat= -p "$1") in '' | Z*) return 1 ;; esac; }

# A branch with one commit past its base, which adds a file.
repo=$tmp/repo
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m base
base=$(git -C "$repo" rev-parse HEAD)
echo change >"$repo/a.txt"
git -C "$repo" add a.txt
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q -m change
head=$(git -C "$repo" rev-parse HEAD)
review() { (cd "$repo" && PATH="$tmp/bin:$PATH" bash "$script" "$@"); }
# A PATH with git and no codex.
mkdir "$tmp/nocodex"
ln -s "$(command -v git)" "$tmp/nocodex/git"
nocodex() { (cd "$repo" && PATH="$tmp/nocodex" "$BASH" "$script" "$@"); }

out=$(review "$base")
check 'prints the findings that codex wrote, and nothing of its session' "$(cat "$fixtures/codex-findings.json")" "$out"
check 'codex runs in the read-only sandbox' read-only "$(grep -A1 -xF -- -s "$tmp/args" | sed -n 2p)"
grep -qxF -- '--ephemeral' "$tmp/args" || fail 'codex keeps no session files' "$(cat "$tmp/args")"
grep -qF 'file nothing' "$tmp/args" || fail 'the prompt tells codex, which loads rules.md too, to file nothing' "$(cat "$tmp/args")"
grep -qF "git diff $base...$head" "$tmp/args" ||
  fail 'the prompt names the range of the whole branch, from the merge base to the SHA of HEAD' "$(cat "$tmp/args")"
if grep -qF 'the code that it describes' "$tmp/args"; then fail 'without --docs, the prompt has no brief for documents' "$(cat "$tmp/args")"; fi

# A change to documents only gets one Codex read with the brief of the review
# subagent for documents (#152).
rm -f "$tmp/args"
check 'with --docs: prints the findings that codex wrote' "$(cat "$fixtures/codex-findings.json")" "$(review --docs "$base")"
grep -qF 'the code that it describes' "$tmp/args" ||
  fail 'with --docs: the prompt reads the text against the code that it describes' "$(cat "$tmp/args")"
if grep -qF 'code that gives a wrong result' "$tmp/args"; then fail 'with --docs: the prompt has no brief for code' "$(cat "$tmp/args")"; fi
grep -qF 'file nothing' "$tmp/args" || fail 'with --docs: the prompt tells codex to file nothing' "$(cat "$tmp/args")"
grep -qF "git diff $base...$head" "$tmp/args" || fail 'with --docs: the prompt names the range of the whole branch' "$(cat "$tmp/args")"
code=0
review --docs >/dev/null 2>"$tmp/err" || code=$?
check '--docs with no base is a usage error' 2 "$code"
grep -qxF 'usage: codex-review.sh [--docs] <base>' "$tmp/err" || fail 'the usage line names --docs' "$(cat "$tmp/err")"
rm -f "$tmp/args"
review HEAD~1 >/dev/null
grep -qF "git diff $base...$head" "$tmp/args" || fail 'a base given as a name goes into the prompt as its SHA' "$(cat "$tmp/args")"
check 'the schema asks for the fields of a finding' 'file line summary failure_scenario' \
  "$(jq -r '.properties.findings.items.required | join(" ")' "$tmp/schema.json")"
check 'the recorded findings fit the schema' 'true' \
  "$(jq --slurpfile s "$tmp/schema.json" '[.findings[] | keys_unsorted] | all(. == $s[0].properties.findings.items.required)' "$fixtures/codex-findings.json")"

code=0
out=$(FAKE_FAIL=1 review "$base" 2>"$tmp/err") || code=$?
check 'a failed codex run exits 1' 1 "$code"
check 'a failed codex run prints no findings' '' "$out"
grep -qF 'stream disconnected' "$tmp/err" || fail 'a failed codex run shows its log on stderr' "$(cat "$tmp/err")"

code=0
out=$(FAKE_NO_MESSAGE=1 review "$base" 2>"$tmp/err") || code=$?
check 'codex that ends with no findings file exits 1, not with no output' 1 "$code"
grep -qF 'codex prints its session here' "$tmp/err" || fail 'codex with no findings file shows its log on stderr' "$(cat "$tmp/err")"

# Without the limit, the fake's sleep ends after 30 seconds and its findings
# come out with exit 0.
code=0
out=$(FAKE_HANG=1 CODEX_REVIEW_LIMIT=1 review "$base" 2>"$tmp/err") || code=$?
check 'a codex run past the time limit exits 1' 1 "$code"
check 'a codex run past the time limit prints no findings' '' "$out"
# Nothing else: bash's line on the killed job holds the whole codex command.
check 'a codex run past the time limit shows its log and says so on stderr, and nothing else' \
  "$(printf '%s\n' 'codex prints its session here' 'codex-review.sh: codex ran past 1 seconds and was stopped')" "$(cat "$tmp/err")"
[ -s "$tmp/hung" ] || fail 'the hung fake codex wrote the pid of its child'
if running "$(cat "$tmp/hung")"; then fail 'a codex run past the time limit leaves no child of codex running'; fi

# A review that is stopped, as when the agent stops its background task, stops
# its codex too. The limit keeps a failed case from leaving it running.
rm -f "$tmp/hung"
(cd "$repo" && FAKE_HANG=1 CODEX_REVIEW_LIMIT=5 PATH="$tmp/bin:$PATH" exec bash "$script" "$base") >/dev/null 2>&1 &
reviewer=$!
for _ in $(seq 50); do [ -s "$tmp/hung" ] && break; sleep 0.1; done
[ -s "$tmp/hung" ] || fail 'the hung fake codex wrote the pid of its child'
{ kill "$reviewer"; wait "$reviewer"; } 2>/dev/null || true
if running "$(cat "$tmp/hung")"; then fail 'a review that is stopped leaves no child of codex running'; fi

rm -f "$tmp/args"
check 'not logged in: skipped, with the reason' 'skipped: codex is not logged in' "$(FAKE_LOGGED_IN=0 review "$base")"
[ ! -f "$tmp/args" ] || fail 'not logged in: codex exec does not run'

check 'no codex on PATH: skipped, with the reason' 'skipped: the codex CLI is not installed' "$(nocodex "$base")"

code=0
review no-such-commit >/dev/null 2>"$tmp/err" || code=$?
check 'a base that is not a commit is a usage error' 2 "$code"
grep -qF 'no-such-commit is not a commit' "$tmp/err" || fail 'the usage error names the base' "$(cat "$tmp/err")"

code=0
out=$(nocodex no-such-commit 2>&1) || code=$?
check 'a bad base is a usage error with no codex too, not a skip' \
  '2 codex-review.sh: no-such-commit is not a commit' "$code $out"

# GIT_CEILING_DIRECTORIES keeps git from finding a repository above $tmp.
mkdir "$tmp/outside"
code=0
(cd "$tmp/outside" && GIT_CEILING_DIRECTORIES="$tmp" PATH="$tmp/bin:$PATH" bash "$script" "$base") \
  >/dev/null 2>"$tmp/err" || code=$?
check 'a working directory outside a repository is a usage error' 2 "$code"
grep -qF 'fatal: not a git repository' "$tmp/err" || fail "the usage error keeps git's own reason" "$(cat "$tmp/err")"
grep -qxF "codex-review.sh: no git repository at $tmp/outside" "$tmp/err" ||
  fail 'the usage error names the working directory' "$(cat "$tmp/err")"

rm -f "$tmp/args"
code=0
review HEAD >/dev/null 2>"$tmp/err" || code=$?
check 'a range that changes nothing is a usage error, not a clean review' 2 "$code"
grep -qF 'changes nothing' "$tmp/err" || fail 'the usage error says the range changes nothing' "$(cat "$tmp/err")"
[ ! -f "$tmp/args" ] || fail 'a range that changes nothing: codex exec does not run'

# A commit with no history in common with HEAD.
rm -f "$tmp/args"
orphan=$(git -C "$repo" -c user.name=t -c user.email=t@example.com \
  commit-tree -m orphan "$(git -C "$repo" hash-object -t tree /dev/null)")
code=0
review "$orphan" >/dev/null 2>"$tmp/err" || code=$?
check 'a range that git cannot diff is a usage error, not a clean review' 2 "$code"
grep -qF 'git cannot diff' "$tmp/err" || fail 'the usage error says git cannot diff the range' "$(cat "$tmp/err")"
grep -qF 'no merge base' "$tmp/err" || fail "the usage error keeps git's own reason for the range" "$(cat "$tmp/err")"
[ ! -f "$tmp/args" ] || fail 'a range that git cannot diff: codex exec does not run'

echo 'review_loop_scripts_test: ok'
