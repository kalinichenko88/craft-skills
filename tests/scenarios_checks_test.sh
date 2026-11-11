#!/usr/bin/env bash
# Runs the checks of tests/scenarios_eval.sh on recorded runs, with no model.
# tests/fixtures/scenarios/take-in/ holds the events, the tracker, the
# branches and the workspace of one probe run of each case: free, other and
# down of 2026-11-03, dup and busy of 2026-11-10, and the other eight of
# 2026-11-11, which also keep the workspace and the branches of their Given.
# The runs of free, other, down, dup and busy kept none: theirs is the one
# that setup makes now. In the runs of
# free, dup and busy, no message about #91 comes before the branch, but think
# lines do: the log cannot show whether a message told the gist (#206), so
# the two gist items give SKIP; in the run of inws, the gist item does. The
# run of dup carries one line of the stack trace of #95 to #91, not the trace,
# and fails that item. Every other item passes. A copy with one change to a
# recorded run changes the verdicts it names and no other; a read added to a
# run changes none. Each heading of
# scenarios/github/take-in.md is a scenario that the checks name or that the
# eval lists as not run, and nothing else is.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
eval=$root/tests/scenarios_eval.sh
fixtures=$root/tests/fixtures/scenarios/take-in
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_checks_test: $1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
  exit 1
}
# checks <folder>...: the item lines of the report.
checks() {
  local r
  r=$("$eval" --check "$@") || return
  grep -E '^(PASS|FAIL|SKIP) ' <<<"$r"
}

report=$("$eval" --check "$fixtures")
out=$(grep -E '^(PASS|FAIL|SKIP) ' <<<"$report")
[ "$(grep '^pass' <<<"$report" | grep -v ': PASS, 1 of 1 runs pass$')" = 'pass^1 dup: FAIL, 0 of 1 runs pass' ] &&
  [ "$(grep -c '^pass' <<<"$report")" = 13 ] || fail 'the recorded runs do not give pass^1 to each of the 13 cases but dup' "$report"
[ "$(grep -c '^PASS ' <<<"$out")" = 79 ] || fail 'the recorded runs do not pass 79 items' "$out"
[ "$(grep -v '^PASS ' <<<"$out")" = 'SKIP A busy duplicate: the first message about #91 tells its gist: a think line comes before it
SKIP A busy duplicate: the gist comes before any change: only a think line comes before the change
FAIL A free duplicate: a comment on #91 holds the stack trace of #95
SKIP A free duplicate: the first message about #91 tells its gist: a think line comes before it
SKIP A free duplicate: the gist comes before any change: only a think line comes before the change
SKIP A free task: the first message about #91 tells its gist: a think line comes before it
SKIP A free task: the gist comes before any change: only a think line comes before the change
SKIP The person'"'"'s work is in the workspace: the first message about #91 tells its gist: a think line comes before it' ] ||
  fail 'the recorded runs do not give only the seven gist SKIPs and the FAIL of the trace' "$out"

# coverage <scenario file>: "< heading" for each heading that no case runs and
# the eval does not list as not run, "> name" for each name that the eval
# runs or lists that is no heading, and for a name that it both runs and
# lists.
coverage() {
  diff <(sed -n 's/^## //p' "$1" | sort -u) \
    <({ sed -E 's/^(PASS|FAIL|SKIP) ([^:]*):.*/\2/' <<<"$out" | sort -u; "$eval" --not-run; } | sort) | grep '^[<>]' || true
}
take_in=$root/scenarios/github/take-in.md
[ -z "$(coverage "$take_in")" ] || fail 'the eval does not cover each scenario of take-in once' "$(coverage "$take_in")"
{ cat "$take_in"; printf '\n## A new scenario\n'; } >"$tmp/new.md"
[ "$(coverage "$tmp/new.md")" = '< A new scenario' ] || fail 'a heading with no case passes' "$(coverage "$tmp/new.md")"
grep -vxF "## The work on the person's task continues here" "$take_in" >"$tmp/gone.md"
[ "$(coverage "$tmp/gone.md")" = "> The work on the person's task continues here" ] ||
  fail 'a scenario listed as not run, with no heading, passes' "$(coverage "$tmp/gone.md")"

n=0
copy() {
  n=$((n + 1))
  cp -R "$fixtures" "$tmp/$n"
}
scenario() {
  case $1 in
    free) echo 'A free task' ;; other) echo 'A task that another person is assigned to' ;;
    down) echo 'The tracker does not answer' ;; dup) echo 'A free duplicate' ;; busy) echo 'A busy duplicate' ;;
    closed) echo 'A closed task' ;; otherpr) echo "A task with another person's pull request" ;;
    mypr) echo "A task with the person's pull request" ;; assigned) echo 'A task assigned to the person, with no branch' ;;
    linked) echo 'A linked branch with no assignee' ;; inws) echo "The person's work is in the workspace" ;;
    moved) echo "The person's branch moved on somewhere else" ;; otherrepo) echo 'A task of another repository' ;;
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

# A last message that names #95, and a close of something else in another
# sentence.
copy
add dup $'text\t#95 reports the same typo. I closed the worktree.'
flips dup 'the last message names #95 as closed'

# #91 closed.
copy
state dup '(.issues[] | select(.number == 91) | .state) = "CLOSED"'
flips dup 'never: #91 closes'

# A busy duplicate: #95 closed in the tracker, closed in the log, given a
# second assignee, and named with no word of why it stays open.
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
sed -i.bak '/^text.*#95/{s/busy/taken/g; s/rivera/someone/g;}' "$tmp/$n/busy.events"
flips busy 'the person is told that #95 stays open because it is busy'

# A closed task reopened, and told with no word that it is closed.
copy
state closed '.issues[0].state = "OPEN"'
flips closed 'never: the state of #91 changes'
copy
sed -i.bak '/^text/{s/closed/done/g; s/Closed/Done/g;}' "$tmp/$n/closed.events"
flips closed 'the person is told that #91 is closed'

# #96 named with no word of whose it is; a new branch on the origin.
copy
sed -i.bak '/^text/s/rivera/someone/g' "$tmp/$n/otherpr.events"
flips otherpr 'the person is told that #96 of another person closes #91'
copy
echo fix/91-new >>"$tmp/$n/mypr.branches"
flips mypr 'never: a branch for #91 is created'

# The person's task: told it is theirs with no word of an assignee, and asked
# nothing.
copy
sed -i.bak '/^text/s/assigned to you/yours/g' "$tmp/$n/assigned.events"
flips assigned 'the person is told that #91 is assigned to the person already'
copy
sed -i.bak '/^text/s/?/./g' "$tmp/$n/assigned.events"
flips assigned 'the person is asked whether the work on #91 runs somewhere else or continues here'

# A linked branch: asked nothing, and a second branch linked.
copy
sed -i.bak '/^text/s/?/./g' "$tmp/$n/linked.events"
flips linked 'the person is asked whose branch fix/91-typo is'
copy
state linked '.issues[0].linked += ["fix/91-other"]'
flips linked 'never: a branch for #91 is created'

# The work in the workspace: no commit and no change on fix/91-typo, and a
# question whether the work runs somewhere else.
copy
cp "$fixtures/inws.given.workspace" "$tmp/$n/inws.workspace"
flips inws 'the work goes on, on fix/91-typo'
copy
add inws $'text\tDoes the work on #91 run somewhere else, or here?'
flips inws 'never: the person is asked whether the work runs somewhere else'
copy
sed -i.bak '/^text/s/continu/kept/g' "$tmp/$n/inws.events"
flips inws 'the person is told in one line that the work on #91 continues on fix/91-typo'
# A question about something else, after a sentence that names another
# session.
copy
add inws $'text\tNo other session works on #91. Shall I open a draft PR?'
stays

# Told with no number of the pull request, and with no name of the linked
# branch.
copy
sed -i.bak '/^text/s/#96/the pull request/g' "$tmp/$n/mypr.events"
flips mypr 'the person is told that the work on #91 has pull request #96'
for c in linked moved; do
  copy
  sed -i.bak '/^text/s#fix/91-typo#the branch#g' "$tmp/$n/$c.events"
  flips $c 'the person is told that fix/91-typo is linked to #91'
done

# The branch that moved on: the workspace's fix/91-typo pulled.
copy
sed -i.bak 's/^fix\/91-typo .*/fix\/91-typo 0000000000000000000000000000000000000000/' "$tmp/$n/moved.workspace"
flips moved "never: the workspace's fix/91-typo changes" 'the run waits: no change'

# A task of another repository: told with no name of it, and assigned.
copy
sed -i.bak '/^text/s#acme/lib#there#g' "$tmp/$n/otherrepo.events"
flips otherrepo 'the person is told that #91 is in another repository'
copy
state otherrepo '.issues[0].assignees += ["kim"]'
flips otherrepo 'never: the assignees of #91 change'

echo 'scenarios_checks_test: ok'
