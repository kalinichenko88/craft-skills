#!/usr/bin/env bash
# Runs plan.sh of the roadmap skill against the fake gh of
# tests/roadmap_harness.sh.

# shellcheck disable=SC2016 # the single-quoted $ are jq's
set -eu

# shellcheck source=tests/roadmap_harness.sh
. "$(dirname "$0")/roadmap_harness.sh"

# plan.sh refuses a link that makes a cycle, and sends nothing.
reset
put '19 20 21'
blocks 20 21
: >"$FAKE/calls"
check 'block refuses a cycle' 'refused: it makes a cycle: #21 → #20 → #21' "$(bash "$scripts/plan.sh" block 21 20 2>&1 || true)"
check 'a refused block sends no mutation' 0 "$(grep -c mutation "$FAKE/calls" || true)"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" block 19 21)
case $out in *'dry run: gh api graphql'*addBlockedBy*) ;; *) fail 'block prints its mutation in a dry run' "$out" ;; esac
out=$(DRY_RUN=1 bash "$scripts/plan.sh" unblock 20 21)
case $out in *'dry run: gh api graphql'*removeBlockedBy*) ;; *) fail 'unblock prints its mutation in a dry run' "$out" ;; esac
check 'a dry run sends no mutation' 0 "$(grep -c mutation "$FAKE/calls" || true)"
check 'block to itself' 'refused: an issue cannot wait on itself' "$(bash "$scripts/plan.sh" block 19 19 2>&1 || true)"
# A cycle through an inherited blocker: #11 is a sub-issue of #10, and #12
# waits on #11. Blocking #10 on #12 makes #11 wait on #12.
reset
put '10 11 12'
edit 11 '.parent = {number: 10, milestone: null, repository: {nameWithOwner: "kalinichenko88/agent-skills"}}'
blocks 12 11
check 'block refuses an inherited cycle' 'refused: it makes a cycle: #11 → #12 → #11' "$(bash "$scripts/plan.sh" block 10 12 2>&1 || true)"
check 'block refuses a parent blocked by its own sub-issue' 'refused: it makes a cycle: #11 would wait on itself through #10' \
  "$(bash "$scripts/plan.sh" block 10 11 2>&1 || true)"
# sub: the child would inherit #20, which waits on the child.
reset
put '19 20 21 22'
blocks 20 21
blocks 19 20
check 'sub refuses a cycle through the parent blockers' 'refused: it makes a cycle: #21 → #20 → #21' \
  "$(bash "$scripts/plan.sh" sub 19 21 2>&1 || true)"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" sub 22 19)
case $out in *'dry run: gh api graphql'*addSubIssue*) ;; *) fail 'sub prints its mutation in a dry run' "$out" ;; esac

# plan.sh on milestones.
reset
put '19 20 21'
ms '(.[] | select(.title | startswith("M1 ")) | .description) = "Goal."'
out=$(DRY_RUN=1 bash "$scripts/plan.sh" current M1)
check 'current adds the mark after a blank line' "$(printf 'Goal.\n\nCurrent.')" "$(cat "$(sed -n 's/.*description=@\([^ ]*\).*/\1/p' <<<"$out")")"
mark M1
check 'current twice' 'M1 · Stage 1 is current already' "$(bash "$scripts/plan.sh" current M1)"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" not-current M1)
check 'not-current removes the mark' 'Goal.' "$(cat "$(sed -n 's/.*description=@\([^ ]*\).*/\1/p' <<<"$out")")"
check 'Later is never current' 'refused: Later is never current' "$(bash "$scripts/plan.sh" current later 2>&1 || true)"
check 'create refuses an existing title in any case' 'refused: m1 · stage 1 exists' "$(bash "$scripts/plan.sh" create 'm1 · stage 1' /dev/null 2>&1 || true)"
ms '. + [{number: 999, title: "C:\\new", description: "", state: "open", open_issues: 0, closed_issues: 0}]'
check 'create refuses an existing title with a backslash' 'refused: C:\new exists' "$(bash "$scripts/plan.sh" create 'C:\new' /dev/null 2>&1 || true)"
check 'close refuses open issues' 'refused: M1 · Stage 1 has 3 open issues: #19 Issue 19, #20 Issue 20, #21 Issue 21' "$(bash "$scripts/plan.sh" close M1 2>&1 || true)"
printf 'New goal.\n' >"$tmp/goal"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" describe M1 "$tmp/goal")
check 'describe keeps the mark' "$(printf 'New goal.\n\nCurrent.')" "$(cat "$(sed -n 's/.*description=@\([^ ]*\).*/\1/p' <<<"$out")")"
# rename sends the title alone, so the description and its mark stay.
out=$(DRY_RUN=1 bash "$scripts/plan.sh" rename M1 'M1 · First demo')
check 'rename sends the title alone' "dry run: gh api -X PATCH repos/\{owner\}/\{repo\}/milestones/$(msno M1) -f title=M1\ ·\ First\ demo --silent" "$out"
check 'rename refuses a title another milestone has, in any case' 'refused: m2 · stage 2 exists' \
  "$(bash "$scripts/plan.sh" rename M1 'm2 · stage 2' 2>&1 || true)"
check 'rename refuses an existing title with a backslash' 'refused: C:\new exists' "$(bash "$scripts/plan.sh" rename M1 'C:\new' 2>&1 || true)"
check 'rename changes the case of its own title' 'renamed M1 · Stage 1 to M1 · STAGE 1' \
  "$(bash "$scripts/plan.sh" rename M1 'M1 · STAGE 1' 2>&1)"
check 'create refuses the M<n> of another milestone' 'refused: M1 · Stage 1 is M1 already' \
  "$(bash "$scripts/plan.sh" create 'M1 · Another' /dev/null 2>&1 || true)"
check 'create refuses the M<n> of another milestone in lower case' 'refused: M1 · Stage 1 is M1 already' \
  "$(bash "$scripts/plan.sh" create 'm1 · another' /dev/null 2>&1 || true)"
check 'rename refuses the M<n> of another milestone' 'refused: M1 · Stage 1 is M1 already' \
  "$(bash "$scripts/plan.sh" rename M2 'M01 · Third' 2>&1 || true)"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" create 'M10 · Ten' /dev/null)
case $out in *'dry run: gh api -X POST'*) ;; *) fail 'create takes M10 next to M1' "$out" ;; esac
# bash 3.2 runs an EXIT trap with $? at 0 when set -u stops a script. A copy of
# plan.sh gets a stop after its trap and runs with a finished from the
# environment. Two stops: an unbound variable, the case itself, and an exit 0,
# which gives the trap the $? of 0 of bash 3.2 on any bash. Each must exit
# non-zero, show that it reached the stop, and leave nothing in TMPDIR.
cp -R "$scripts" "$tmp/stopped"
for stop in unbound exit; do
  awk -v stop="$stop" '{ print } !/^[ \t]*#/ && /trap .* EXIT/ {
    print (stop == "exit" ? "echo stop-after-trap; exit 0" : ": \"$unbound_after_trap\"") }' "$scripts/plan.sh" >"$tmp/stopped/plan.sh"
  mark='stop-after-trap'
  [ "$stop" = exit ] || mark='unbound_after_trap: unbound variable'
  before=$(ls -A "$tmp")
  out=$(finished=1 bash "$tmp/stopped/plan.sh" create 'M10 · Ten' /dev/null 2>&1) && fail "create exits 0 after its $stop stop" "$out"
  case $out in *"$mark"*) ;; *) fail "create stops before its $stop stop" "$out" ;; esac
  check "create leaves nothing in TMPDIR after its $stop stop" "$before" "$(ls -A "$tmp")"
done
check 'rename refuses Later before it reads' 'refused: a milestone does not become Later: plan.sh later puts off one task at a time' \
  "$(bash "$scripts/plan.sh" rename NoSuch later 2>&1 || true)"
# due sends noon UTC, the same day in UTC and in the US time zones that
# GitHub keeps due dates in; none clears it.
out=$(DRY_RUN=1 bash "$scripts/plan.sh" due M1 2026-12-01)
check 'due sends noon UTC' "dry run: gh api -X PATCH repos/\{owner\}/\{repo\}/milestones/$(msno M1) -F due_on=2026-12-01T12:00:00Z --silent" "$out"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" due M1 none)
check 'due none clears it' "dry run: gh api -X PATCH repos/\{owner\}/\{repo\}/milestones/$(msno M1) -F due_on=null --silent" "$out"
check 'due takes a day only' 2 "$(bash "$scripts/plan.sh" due M1 12/01/2026 >/dev/null 2>&1; echo $?)"
check 'due refuses a day that does not exist' 'plan.sh: 2026-02-30 is not a day' "$(bash "$scripts/plan.sh" due M1 2026-02-30 2>&1)"
check 'due takes February 29 of a leap year' 0 "$(DRY_RUN=1 bash "$scripts/plan.sh" due M1 2028-02-29 >/dev/null 2>&1; echo $?)"
check 'due refuses February 29 of 2100' 2 "$(bash "$scripts/plan.sh" due M1 2100-02-29 >/dev/null 2>&1; echo $?)"
# An open sub-issue with no milestone takes it from its parent, closed or not.
reset
put '11:-'
edit 11 ".parent = {number: 10, milestone: {number: $(msno M1)}, repository: {nameWithOwner: \"kalinichenko88/agent-skills\"}}"
check 'close counts a sub-issue in the milestone of its parent' 'refused: M1 · Stage 1 has 1 open issues: #11 Issue 11' \
  "$(bash "$scripts/plan.sh" close M1 2>&1 || true)"
# plan.sh later puts a task off, unless an issue outside Later waits on it:
# a task in Later is never offered, so that issue would wait for good.
reset
put '19 20 21 42:Later'
blocks 20 21
blocks 42 19
check 'later refuses a task that a blocked issue waits on' 'refused: these wait on it outside Later: #20 Issue 20' \
  "$(bash "$scripts/plan.sh" later 21 2>&1 || true)"
out=$(DRY_RUN=1 bash "$scripts/plan.sh" later 19)
case $out in *'dry run: gh issue edit 19 --milestone Later'*) ;; *) fail 'later moves a task that only Later waits on' "$out" ;; esac
check 'later on a task in Later' '#42 is in Later already' "$(bash "$scripts/plan.sh" later 42)"
reset
put '10 11'
edit 11 '.parent = {number: 10, milestone: null, repository: {nameWithOwner: "kalinichenko88/agent-skills"}}'
check 'later refuses a sub-issue whose parent waits on it' 'refused: these wait on it outside Later: #10 Issue 10' \
  "$(bash "$scripts/plan.sh" later 11 2>&1 || true)"
# A sub-issue with no milestone goes into Later with its parent.
reset
put '10 11:- 20'
edit 11 ".parent = {number: 10, milestone: {number: $(msno M1)}, repository: {nameWithOwner: \"kalinichenko88/agent-skills\"}}"
blocks 20 11
check 'later refuses a task whose sub-issue an issue waits on' 'refused: these wait on it outside Later: #20 Issue 20' \
  "$(bash "$scripts/plan.sh" later 10 2>&1 || true)"
# A wait through a task in Later counts too: #19 waits on #42, which waits on #50.
reset
mark M1
put '19 42:Later 50:M2'
blocks 19 42
blocks 42 50
check 'later refuses a task that an issue waits on through Later' 'refused: these wait on it outside Later: #19 Issue 19' \
  "$(bash "$scripts/plan.sh" later 50 2>&1 || true)"
reset
put '10:Later 11:- 20'
blocks 20 11
check 'sub refuses a child that goes into Later' 'refused: #11 goes into Later with #10, and these wait on it outside Later: #20 Issue 20' \
  "$(bash "$scripts/plan.sh" sub 10 11 2>&1 || true)"
# No Later milestone yet: it is made first.
reset
ms 'map(select(.title != "Later"))'
put '19'
out=$(DRY_RUN=1 bash "$scripts/plan.sh" later 19)
case $out in *'dry run: gh api -X POST'*'title=Later'*'dry run: gh issue edit 19 --milestone Later'*) ;;
  *) fail 'later makes the Later milestone first' "$out" ;;
esac
# A closed Later is opened again.
reset
jq '[.[] | select(.title == "Later") | .state = "closed"]' "$fixtures/milestones.json" >"$FAKE/milestones-closed.json"
ms 'map(select(.title != "Later"))'
put '19'
out=$(DRY_RUN=1 bash "$scripts/plan.sh" later 19)
case $out in *'dry run: gh api -X PATCH'*"milestones/$(msno Later)"*'state=open'*'dry run: gh issue edit 19 --milestone Later'*) ;;
  *) fail 'later opens a closed Later again' "$out" ;;
esac
# The issues of a closed Later are in Later when it opens again.
reset
jq '[.[] | select(.title == "Later") | .state = "closed"]' "$fixtures/milestones.json" >"$FAKE/milestones-closed.json"
ms 'map(select(.title != "Later"))'
put '19 5:Later'
blocks 5 19
out=$(DRY_RUN=1 bash "$scripts/plan.sh" later 19 2>&1 || true)
case $out in *'state=open'*'dry run: gh issue edit 19 --milestone Later'*) ;; *) fail 'later counts the issues of a closed Later as in Later' "$out" ;; esac
check 'usage names every subcommand' 11 "$(bash "$scripts/plan.sh" 2>&1 | grep -c 'plan.sh ' || true)"
echo 'roadmap_plan_test: ok'
