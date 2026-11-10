#!/usr/bin/env bash
# Runs the checks of tests/scenarios_eval.sh on recorded runs, with no model.
# tests/fixtures/scenarios/take-in/ holds the events, the tracker, the
# branches and the workspace of one probe run of each case: free, other and
# down of 2026-11-03, dup and busy of 2026-11-10. In the runs of free, dup and
# busy, no message about #91 comes before the branch, but think lines do: the
# log cannot show whether a message told the gist (#206), so the two gist
# items give SKIP. The run of dup carries one line of the stack trace of #95
# to #91, not the trace, and fails that item. Every other item passes. A copy with
# one change to a recorded run changes the verdicts it names and no other; a
# read added to a run changes none. Each scenario that the checks name is a
# heading of scenarios/github/take-in.md.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fixtures=$root/tests/fixtures/scenarios/take-in
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_checks_test: $1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
  exit 1
}
checks() { "$root/tests/scenarios_eval.sh" --check "$1"; }

out=$(checks "$fixtures")
[ "$(grep -c '^PASS ' <<<"$out")" = 34 ] || fail 'the recorded runs do not pass 34 items' "$out"
[ "$(grep -v '^PASS ' <<<"$out")" = 'SKIP A busy duplicate: the first message about #91 tells its gist: a think line comes before it
SKIP A busy duplicate: the gist comes before any change: only a think line comes before the change
FAIL A free duplicate: a comment on #91 holds the stack trace of #95
SKIP A free duplicate: the first message about #91 tells its gist: a think line comes before it
SKIP A free duplicate: the gist comes before any change: only a think line comes before the change
SKIP A free task: the first message about #91 tells its gist: a think line comes before it
SKIP A free task: the gist comes before any change: only a think line comes before the change' ] ||
  fail 'the recorded runs do not give only the six gist SKIPs and the FAIL of the trace' "$out"

while IFS= read -r scenario; do
  grep -qxF "## $scenario" "$root/scenarios/github/take-in.md" || fail "no scenario named $scenario" "$out"
done < <(sed -E 's/^(PASS|FAIL|SKIP) ([^:]*):.*/\2/' <<<"$out" | sort -u)

n=0
copy() {
  n=$((n + 1))
  cp -R "$fixtures" "$tmp/$n"
}
scenario() {
  case $1 in
    free) echo 'A free task' ;; other) echo 'A task that another person is assigned to' ;;
    down) echo 'The tracker does not answer' ;; dup) echo 'A free duplicate' ;; busy) echo 'A busy duplicate' ;;
  esac
}
state() { jq "$2" "$tmp/$n/$1.state.json" >"$tmp/state" && mv "$tmp/state" "$tmp/$n/$1.state.json"; }
add() { printf '%s\n' "$2" >>"$tmp/$n/$1.events"; }
first() { { printf '%s\n' "$2"; cat "$fixtures/$1.events"; } >"$tmp/$n/$1.events"; }
# flips <case> <item> ...: the copy changes the verdict of each item named,
# as the checks print it after the scenario, and of no other item.
flips() {
  local c=$1 item was now got
  shift
  got=$(checks "$tmp/$n")
  for item; do
    was=$(grep -F "$(scenario "$c"): $item" <<<"$out")
    now=$(grep -F "$(scenario "$c"): $item" <<<"$got")
    [ -n "$was" ] && [ "${was%% *}" != "${now%% *}" ] || fail "copy $n does not flip: $item" "$got"
  done
  [ "$(diff <(echo "$out") <(echo "$got") | grep -c '^>')" = $# ] || fail "copy $n flips another item too" "$got"
}
# stays: the copy changes no verdict.
stays() { [ "$(checks "$tmp/$n")" = "$out" ] || fail "copy $n changes a verdict" "$(checks "$tmp/$n")"; }

# The gist told first, before the branch.
copy
first free $'text\t#91: README: the install command says npm instal. The README has a wrong command.'
flips free 'the first message about #91 tells its gist' 'the gist comes before any change'

# A message about #91 with no title, before the branch.
copy
first free $'text\tI take #91 now.'
flips free 'the first message about #91 tells its gist' 'the gist comes before any change'

# No think line: the run told nothing about #91 before the branch.
copy
grep -v '^think' "$fixtures/free.events" >"$tmp/$n/free.events"
flips free 'the first message about #91 tells its gist' 'the gist comes before any change'

# A message about #91 before its gist, on another person's task.
copy
{ head -n 4 "$fixtures/other.events"
  printf 'text\t#91 belongs to rivera, so I stop.\n'
  tail -n +5 "$fixtures/other.events"; } >"$tmp/$n/other.events"
flips other 'the first message about #91 tells its gist'

# The person added to another person's task.
copy
state other '.issues[0].assignees += ["kim"]'
flips other 'never: the assignees of #91 change'

# Writes on another person's task: to the tracker, in the shell, with git -C,
# and on the second line of a command.
for write in 'gh issue edit 91 --add-assignee @me' "sed -i '' s/instal/install/ README.md" \
  'git -C <work> commit -qam fix' 'cd <work>; bash <craft>/skills/github/scripts/worktree.sh 91 docs/91-x'; do
  copy
  add other "$(printf 'Bash\t%s' "$write")"
  flips other 'the run waits: no change'
done

# Changes to the workspace that the log does not show: a changed file, and a
# commit on main.
copy
{ echo ' M README.md'; cat "$fixtures/other.workspace"; } >"$tmp/$n/other.workspace"
flips other 'the run waits: no change'
copy
sed -i.bak 's/^main 1$/main 2/' "$tmp/$n/other.workspace"
flips other 'the run waits: no change'

# Reads on another person's task.
# shellcheck disable=SC2016 # the commands are data
for read in 'git diff $(git merge-base origin/main HEAD)' 'git branch 2>&1 | head' 'git stash list' \
  'gh issue develop 91 -l' 'sed -n 1,80p <craft>/skills/github/scripts/worktree.sh'; do
  copy
  add other "$(printf 'Bash\t%s' "$read")"
  stays
done

# A second linked branch on the free task.
copy
state free '.issues[0].linked += ["fix/91-other"]'
flips free 'never: #91 gets a second linked branch'

# No branch linked to the free task.
copy
state free '.issues[0].linked = []'
flips free 'that branch is made from the default branch' 'that branch is linked to #91'

# The linked branch of the free task is not made from main.
copy
sed -i.bak 's#^docs/91-fix-install-command$#&, not from main#' "$tmp/$n/free.branches"
flips free 'that branch is made from the default branch'

# A title that the run could not read, told when the tracker is down.
copy
add down $'text\tREADME: the install command says npm instal'
flips down 'never: a gist of #91 that the run did not read'

# No error of the tracker told.
copy
sed -i.bak 's/502/5xx/g' "$tmp/$n/down.events"
flips down 'the person is told the error of the tracker'

# A free duplicate. The stack trace of #95 in a comment on #91, its indent
# lost.
copy
state dup '(.issues[] | select(.number == 91) | .comments) +=
  [{author: "kim", body: (.issues[] | select(.number == 95) | .body | split("```")[1] | gsub("\n +"; "\n"))}]'
flips dup 'a comment on #91 holds the stack trace of #95'

# #95 closed, but not as a duplicate.
copy
state dup '(.issues[] | select(.number == 95)) |= (.stateReason = "COMPLETED" | .duplicateOf = null)'
flips dup '#95 is closed as a duplicate of #91'

# #95 closed before the comment on #91.
copy
state dup '.log = ["close 95"] + (.log - ["close 95"])'
flips dup 'the comment on #91 comes before #95 closes'

# #95 closed after the work started: the fake gh marks the close.
copy
state dup '.log |= map(if . == "close 95" then "close 95 +changes" else . end)'
flips dup '#95 closes before the work starts'

# A last message that does not name #95.
copy
add dup $'text\tThe pull request waits for you.'
flips dup 'the last message names #95 as closed'

# #91 closed.
copy
state dup '(.issues[] | select(.number == 91) | .state) = "CLOSED"'
flips dup 'never: #91 closes'

# A busy duplicate: #95 closed in the tracker, closed in the log, given a
# second assignee, and named in no message.
copy
state busy '(.issues[] | select(.number == 95) | .state) = "CLOSED"'
flips busy '#95 stays open'
copy
state busy '.log += ["close 95"]'
flips busy 'never: #95 closes'
copy
state busy '(.issues[] | select(.number == 95) | .assignees) += ["kim"]'
flips busy 'never: the assignees of #95 change'
copy
sed -i.bak '/^text/s/#95/#96/g' "$tmp/$n/busy.events"
flips busy 'the person is told that #95 stays open because it is busy'

# The fake gh marks a write that comes after a change in a worktree of the
# workspace: a changed file, or a commit past main.
git init -q -b main "$tmp/ws"
git -C "$tmp/ws" -c user.name=kim -c user.email=kim@example.com commit -q --allow-empty -m start
jq -n --arg w "$tmp/ws" '{me: "kim", repo: "acme/shop", workspace: $w,
  issues: [{number: 95, title: "t", body: "b", state: "OPEN", assignees: [], labels: [], comments: []}]}' >"$tmp/fake.state.json"
fake() { bash "$root/tests/fake_gh.sh" "$tmp/fake.state.json" "$@" >/dev/null; }
fake issue comment 95 --body a
git -C "$tmp/ws" worktree add -q -b docs/95-x "$tmp/wt"
fake issue edit 95 --add-assignee @me
echo x >"$tmp/wt/README.md"
fake issue close 95
git -C "$tmp/wt" add README.md
git -C "$tmp/wt" -c user.name=kim -c user.email=kim@example.com commit -q -m x
fake issue comment 95 --body b
[ "$(jq -c .log "$tmp/fake.state.json")" = '["comment 95","edit 95","close 95 +changes","comment 95 +changes"]' ] ||
  fail 'the fake gh does not mark the writes after a change in a worktree' "$(jq -c .log "$tmp/fake.state.json")"

echo 'scenarios_checks_test: ok'
