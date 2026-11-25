#!/usr/bin/env bash
# Runs read.sh, roadmap.sh and board.sh of the roadmap skill against the fake
# gh of tests/roadmap_harness.sh. A case of read.sh milestone runs plan.sh too,
# as a script that reads through it.

# shellcheck disable=SC2016 # the single-quoted $ are jq's
set -eu

# shellcheck source=tests/roadmap_harness.sh
. "$(dirname "$0")/roadmap_harness.sh"

# A title keeps its backslashes: golang/go#82205's.
reset
put '19'
edit 19 '.title = "strconv: Unquote(`'"'"'\\xff'"'"'`) returns \"\\xff\" (invalid UTF-8) instead of the encoding of U+00FF"'
check 'a title with backslashes' $'- #19 strconv: Unquote(`\'\\xff\'`) returns "\\xff" (invalid UTF-8) instead of the encoding of U+00FF: free' \
  "$(bash "$scripts/roadmap.sh" | grep '^- #19 ')"

# read.sh issues: every page, and each field of the record.
reset
pages 150
check 'issues reads every page' 150 "$(bash "$scripts/read.sh" issues | grep -c '^is	')"
reset
put '19 20 21'
# Your own assignee alone does not make #19 busy: an assignee says who may
# take an issue, not that its work runs (#285).
edit 19 '.blockedBy.nodes = [{number: 116, state: "CLOSED", repository: {nameWithOwner: "kalinichenko88/agent-skills"}}]
  | .assignees.nodes = [{login: "kalinichenko88"}]'
edit 20 '.assignees.nodes = [{login: "kalinichenko88"}] | .labels.nodes = [{name: "In Progress"}] | .linkedBranches.nodes = [{ref: {name: "fix/20-x"}}]
  | .closedByPullRequestsReferences.nodes = [{number: 9, state: "OPEN", author: {login: "someone"}}, {number: 8, state: "MERGED", author: {login: "someone"}}]'
blocks 21 19
edit 21 '.blockedBy.nodes += [{number: 3, state: "OPEN", repository: {nameWithOwner: "other/repo"}}] | .labels.nodes = [{name: "bug"}]
  | .parent = {number: 19, milestone: {number: 7}, repository: {nameWithOwner: "kalinichenko88/agent-skills"}} | .subIssuesSummary = {total: 3, completed: 1}'
out=$(bash "$scripts/read.sh" issues)
m1=$(msno M1)
check 'a closed blocker is not listed, and your assignee alone is not busy' "$(printf 'is\t19\t%s\t0\t-\t-\t0\t0\t0\tIssue 19' "$m1")" "$(grep '^is	19	' <<<"$out")"
check 'busy in collect.sh words' 'assigned to you, label in progress, branch fix/20-x, PR #9 by someone' \
  "$(awk -F'\t' '$1=="is" && $2==20 {print $5}' <<<"$out")"
check 'linked branch' "$(printf 'br\t20\tfix/20-x')" "$(grep '^br	' <<<"$out")"
check 'blockers, bug, parent, its milestone, open sub-issues' \
  "$(printf 'is\t21\t%s\t1\t-\t#19,other/repo#3\t19\t7\t2\tIssue 21' "$m1")" "$(grep '^is	21	' <<<"$out")"
check 'the repository' "$(printf 'repo\tkalinichenko88/agent-skills')" "$(grep '^repo	' <<<"$out" | tail -1)"
check 'another bug label' 0 "$(bash "$scripts/read.sh" issues defect | awk -F'\t' '$1=="is" && $2==21 {print $4}')"

# read.sh milestones: in order, the current mark, the description lines.
reset
check 'order, Later last' "$(printf 'M0 · Stage 0\nM1 · Stage 1\nM2 · Stage 2\nM3 · Stage 3\nM4 · Stage 4\nM5 · Stage 5\nLater')" \
  "$(bash "$scripts/read.sh" milestones | awk -F'\t' '$1=="ms" {print $6}')"
check 'the first is current when none is marked' 'M0 · Stage 0' \
  "$(bash "$scripts/read.sh" milestones | awk -F'\t' '$1=="ms" && $4==1 {print $6}')"
# m2 is M2 for the order too, as it is for read.sh milestone and plan.sh.
ms 'map(if .title == "M2 · Stage 2" then .title = "m2 · Stage 2" else . end)'
check 'the order reads m<n> in any case' 2 "$(bash "$scripts/read.sh" milestones | awk -F'\t' '$6=="m2 · Stage 2" {print $3}')"
reset
mark M0
ms '(.[] | select(.title | startswith("M1 ")) | .description) += "\r\n Current. \r\n"'
out=$(bash "$scripts/read.sh" milestones)
check 'marked milestones are current' "$(printf 'M0 · Stage 0\nM1 · Stage 1')" "$(awk -F'\t' '$1=="ms" && $4==1 {print $6}' <<<"$out")"
check 'the mark is no description line' 0 "$(grep -c 'Current\.' <<<"$out")"
check 'no carriage return' 0 "$(grep -c $'\r' <<<"$out")"
mark Later
check 'Later is never current' 0 "$(bash "$scripts/read.sh" milestones | awk -F'\t' '$1=="ms" && $5==1 {print $4}')"
reset
check 'M1 resolves' "$(printf '%s\tM1 · Stage 1' "$(msno M1)")" "$(bash "$scripts/read.sh" milestone M1)"
check 'later resolves in any case' Later "$(bash "$scripts/read.sh" milestone later | cut -f2)"
bash "$scripts/read.sh" milestone M9 2>/dev/null && fail 'an unknown milestone exits 0'
ms 'map(if (.title | startswith("M1 ")) then .title = "M10 · Stage 10" else . end)'
bash "$scripts/read.sh" milestone M1 2>/dev/null && fail 'M1 matches M10'
# Two open titles that start with M1, as one made by hand on GitHub gives: M1
# names neither, in read.sh and in each script that reads through it.
reset
ms '. + [.[] | select(.title == "M1 · Stage 1") | .number = 999 | .title = "M1 · Other"]'
bash "$scripts/read.sh" milestone M1 >"$tmp/out" 2>&1 && fail 'M1 of two milestones exits 0'
check 'M1 of two milestones names both' \
  "$(printf 'read.sh: M1 matches more than one open milestone; name it by its whole title:\n  M1 · Stage 1\n  M1 · Other')" "$(cat "$tmp/out")"
check 'a whole title of the two resolves' 999 "$(bash "$scripts/read.sh" milestone 'm1 · other' | cut -f1)"
bash "$scripts/roadmap.sh" M1 >/dev/null 2>&1 && fail 'roadmap.sh M1 of two milestones exits 0'
out=$(DRY_RUN=1 bash "$scripts/plan.sh" current M1 2>&1) && fail 'plan.sh current M1 of two milestones exits 0'
check 'plan.sh current M1 of two milestones gives the reason' 1 "$(grep -c '^read.sh: M1 matches more than one' <<<"$out" || true)"
check 'plan.sh current M1 of two milestones writes nothing' 0 "$(grep -c '^dry run' <<<"$out" || true)"
# A title that is M1 alone is its own whole title, so M1 names it.
ms '. + [.[] | select(.title == "M1 · Stage 1") | .number = 998 | .title = "M1"]'
check 'the whole title M1 resolves next to M1 · ...' 998 "$(bash "$scripts/read.sh" milestone M1 | cut -f1)"

# read.sh prs. The recorded pull requests are the owner's, so each author is you.
reset
first=$(jq -r '.data.repository.pullRequests.nodes[0] | "\(.number)\t\(.files.totalCount)"' "$fixtures/prs-1.json")
check 'pr record: number, you, file count' "$(printf 'pr\t%s\tyou\t%s' "${first%%	*}" "${first##*	}")" \
  "$(bash "$scripts/read.sh" prs | grep '^pr	' | head -1 | cut -f1-3,6)"
check 'usage' 2 "$(bash "$scripts/read.sh" >/dev/null 2>&1; echo $?)"

# roadmap.sh: each milestone in order, its issues in dependency order with
# their state.
reset
mark M1
put '19 20 21 22 23 42:Later 50:M2'
blocks 20 21
edit 22 '.assignees.nodes = [{login: "kalinichenko88"}] | .labels.nodes = [{name: "in progress"}]'
edit 23 '.blockedBy.nodes = [{number: 3, state: "OPEN", repository: {nameWithOwner: "other/repo"}}]'
out=$(bash "$scripts/roadmap.sh")
check 'dependency order and states' \
  "$(printf -- '- #19 Issue 19: free\n- #21 Issue 21: free\n- #20 Issue 20: blocked by #21\n- #22 Issue 22: assigned to you, label in progress\n- #23 Issue 23: blocked by other/repo#3')" \
  "$(sed -n '/^## M1 /,/^## /p' <<<"$out" | grep '^- ')"
progress() {
  jq -r --argjson n "$(msno "$1")" '.data.repository.milestones.nodes[] | select(.number == $n)
    | "\(.closedIssues.totalCount) of \(.openIssues.totalCount + .closedIssues.totalCount) closed"' "$fixtures/milestone-counts-1.json"
}
check 'a current milestone' "current, $(progress M1)" "$(sed -n '/^## M1 /{n;p;}' <<<"$out")"
# REST's counts of a milestone take in its pull requests: recorded at one
# moment, M2 has 1057 open and 3748 closed in REST, and 1056 open and 3710
# closed issues. The line counts issues only.
check 'a milestone that is not current, without its pull requests' "$(progress M2)" "$(sed -n '/^## M2 /{n;p;}' <<<"$out")"
check 'Later shows titles only' '- #42 Issue 42' "$(sed -n '/^## Later/,/^## /p' <<<"$out" | grep '^- ')"
# The description shows line by line, one blank line under the progress line.
ms 'map(if (.title | startswith("M2 ")) then .description = "Goal of stage 2.\nDone when it shows." else . end)'
check 'the description lines' "$(printf '%s\n\nGoal of stage 2.\nDone when it shows.' "$(progress M2)")" \
  "$(bash "$scripts/roadmap.sh" | sed -n '/^## M2 /,/^- /p' | sed -n '2,5p')"
check 'Later by name shows states' '- #42 Issue 42: free' "$(bash "$scripts/roadmap.sh" Later | grep '^- ')"
# A cycle made by hand in GitHub ends, and both issues show.
blocks 21 20
check 'a cycle prints each issue once' 2 "$(bash "$scripts/roadmap.sh" | grep -cE '^- #2[01] ')"
# A due date shows as its day: golang/go's Unplanned is due 2099-12-31T05:00:00Z.
ms 'map(if (.title | startswith("M1 ")) then .due_on = "2099-12-31T05:00:00Z" else . end)'
check 'a due date' "current, $(progress M1), due 2099-12-31" "$(bash "$scripts/roadmap.sh" | sed -n '/^## M1 /{n;p;}')"
# A milestone closed between the list read and the count read has no count.
ms '. + [{number: 998, title: "M9 · Stage 9", description: "", state: "open", open_issues: 0, closed_issues: 0}]'
check 'a milestone with no count' 'not counted' "$(bash "$scripts/roadmap.sh" | sed -n '/^## M9 /{n;p;}')"

# A sub-issue takes its parent's milestone and blockers; a parent waits on its
# open sub-issues, also those in another repository.
reset
put '19 30:- 31:M2'
edit 30 ".parent = {number: 19, milestone: {number: $(msno M1)}, repository: {nameWithOwner: \"kalinichenko88/agent-skills\"}}"
blocks 19 31
edit 19 '.subIssuesSummary = {total: 2, completed: 0}'
out=$(bash "$scripts/roadmap.sh")
check 'a sub-issue under its parent milestone, blocked through it' '- #30 Issue 30: blocked by #31' \
  "$(sed -n '/^## M1 /,/^## /p' <<<"$out" | grep '^- #30 ')"
check 'a parent waits on all its open sub-issues' '- #19 Issue 19: blocked by #31; open sub-issues: 2' "$(grep '^- #19 ' <<<"$out")"
check 'one milestone with a blocker elsewhere' '- #31 Issue 31 (M2 · Stage 2): free' "$(bash "$scripts/roadmap.sh" M1 | grep '^- #31 ')"
check 'one milestone has one section' 1 "$(bash "$scripts/roadmap.sh" M1 | grep -c '^## ')"

# A closed milestone counts as none.
reset
put '19 24'
edit 24 '.milestone = {number: 999999}'
# Each issue with no milestone comes with its title, so the agent can name it
# to the person by its title (#277).
check 'an issue in a closed milestone' "$(printf '1 open\n\n- #24 Issue 24')" \
  "$(bash "$scripts/roadmap.sh" | sed -n '/^## No milestone/,$p' | sed 1d)"

# No milestones at all, as in a new project.
reset
ms '[]'
put '19:-'
check 'no milestones' "$(printf '# Roadmap of kalinichenko88/agent-skills\n\nNo open milestones.')" "$(bash "$scripts/roadmap.sh" | sed -n '1,3p')"

# A failed read stops the script.
check 'roadmap.sh prints nothing when a read fails' '' "$(FAKE_FAIL='milestones?' bash "$scripts/roadmap.sh" 2>/dev/null || true)"
check 'roadmap.sh prints nothing when the count read fails' '' "$(FAKE_FAIL='milestones(states' bash "$scripts/roadmap.sh" 2>/dev/null || true)"

# board.sh: a project found by title among the owner's projects, not linked
# yet, is linked, not created again.
reset
pages 3
jq '.projects[0].title = "agent-skills roadmap"' "$fixtures/project-list.json" >"$FAKE/project-list.json"
jq '.items[0].content = {number: 1, repository: "kalinichenko88/agent-skills", type: "Issue"}' "$fixtures/project-items.json" >"$FAKE/project-items.json"
out=$(DRY_RUN=1 bash "$scripts/board.sh")
check 'no create' 0 "$(grep -c 'project create' <<<"$out" || true)"
check 'links a project found by title' 'linked kalinichenko88/agent-skills' "$(grep '^linked ' <<<"$out")"
check 'adds only the missing issues' 'issues to add: 2' "$(grep '^issues to add: ' <<<"$out")"
check 'both views missing' "$(printf 'view Unassigned: missing\nview By milestone: missing')" "$(grep '^view ' <<<"$out")"
check 'the filter of Unassigned' 1 "$(grep -c 'is:issue\\ is:open\\ no:assignee\\ -milestone:Later' <<<"$out" || true)"
# Each setting that the API cannot make is told only while it is not made
# (#507). Auto-add is on in the recorded workflows of this repository's board;
# a missing view has no grouping.
check 'only the grouping step' "$(printf -- '- In the view "By milestone", group by Milestone.')" "$(grep '^- ' <<<"$out")"
check 'the manual steps' 1 "$(grep -c '^Settings the API cannot make. Open ' <<<"$out" || true)"
# A project where it was never turned on lists no node of that name.
jq '.data.node.workflows.nodes |= map(select(.name != "Auto-add to project"))' \
  "$fixtures/project-workflows.json" >"$FAKE/project-workflows.json"
out=$(DRY_RUN=1 bash "$scripts/board.sh")
check 'the step for an auto-add that is off' \
  '- Under Workflows, turn on "Auto-add to project" for kalinichenko88/agent-skills with the filter is:issue is:open.' "$(grep '^- Under ' <<<"$out")"
rm "$FAKE/project-workflows.json"
# A linked project of that title is not linked again; views there are not
# made again.
jq '.data.repository.projectsV2.nodes = [{number: 6, title: "agent-skills roadmap", url: "https://github.com/users/kalinichenko88/projects/6", closed: false}]' \
  "$fixtures/projects-linked.json" >"$FAKE/projects-linked.json"
# By milestone is grouped by its milestone, as on this repository's board.
jq '.data.node.views.nodes = [{id: "PVV_1", name: "Unassigned", filter: "is:open", groupByFields: {nodes: []}},
    {id: "PVV_2", name: "By milestone", filter: "is:open", groupByFields: {nodes: [{dataType: "MILESTONE"}]}}]' \
  "$fixtures/project-views.json" >"$FAKE/project-views.json"
out=$(DRY_RUN=1 bash "$scripts/board.sh")
check 'a linked project is not linked again' 0 "$(grep -c '^linked ' <<<"$out" || true)"
check 'views there' "$(printf 'view Unassigned: there\nview By milestone: there')" "$(grep '^view ' <<<"$out")"
check 'no settings left when both are made' 0 "$(grep -ci 'settings the API cannot make' <<<"$out" || true)"
# A view whose filter was never set, as after a failed run, gets it.
# By milestone is there with no grouping, as on a board where nobody set it.
jq '.data.node.views.nodes = [{id: "PVV_1", name: "Unassigned", filter: null}, {id: "PVV_2", name: "By milestone", filter: "is:open", groupByFields: {nodes: []}}]' \
  "$fixtures/project-views.json" >"$FAKE/project-views.json"
out=$(DRY_RUN=1 bash "$scripts/board.sh")
check 'a view without its filter' "$(printf 'view Unassigned: no filter\nview By milestone: there')" "$(grep '^view ' <<<"$out")"
check 'the grouping step for a view with no grouping' 1 "$(grep -c '^- In the view "By milestone", group by Milestone\.$' <<<"$out" || true)"
check 'the filter goes to that view' 1 "$(grep -c 'view=PVV_1.*no:assignee' <<<"$out" || true)"
# None: create and link it, in a dry run.
reset
out=$(DRY_RUN=1 bash "$scripts/board.sh")
case $out in *'dry run: gh project create --owner kalinichenko88 --title agent-skills\ roadmap'*'dry run: gh project link'*'no project yet'*) ;;
  *) fail 'creates and links the project' "$out" ;;
esac
check 'a new project gets both steps' 2 "$(grep -c '^- ' <<<"$out" || true)"
# A failed create stops with the reason.
reset
FAKE_FAIL='project create' bash "$scripts/board.sh" >"$tmp/out" 2>&1 && fail 'board.sh exits 0 when create fails'
grep -q '^cannot create a project under kalinichenko88: ' "$tmp/out" || fail 'board.sh names the failed create' "$(cat "$tmp/out")"

# gh's --jq runs gojq, whose Go regexp takes (?<name>) only from Go 1.22.
grep -n '(?<' "$scripts"/*.sh && fail 'a named capture in a gh --jq filter'
echo 'roadmap_scripts_test: ok'
