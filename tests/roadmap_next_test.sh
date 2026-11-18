#!/usr/bin/env bash
# Runs next.sh of the roadmap skill against the fake gh of
# tests/roadmap_harness.sh.

# shellcheck disable=SC2016 # the single-quoted $ are jq's
set -eu

# shellcheck source=tests/roadmap_harness.sh
. "$(dirname "$0")/roadmap_harness.sh"

# next.sh: the tracks, ranked.
section() { sed -n "/^== $1/,/^== /p" | grep -E '^(#|and |none)' || true; }
reset
mark M1
put '19 20 21 22 40:M2 41:-'
blocks 20 21
blocks 19 20
edit 22 '.labels.nodes = [{name: "bug"}]'
out=$(bash "$scripts/next.sh")
check 'current line' 'current: M1 · Stage 1' "$(head -1 <<<"$out")"
check 'main path: a chain counts every step' '#21 Issue 21 (M1 · Stage 1), unblocks 2' "$(section 'main path' <<<"$out")"
check 'bugs' '#22 Issue 22 (M1 · Stage 1), unblocks 0' "$(section bugs <<<"$out")"
check 'secondary: next milestone, then none' \
  "$(printf '#40 Issue 40 (M2 · Stage 2), unblocks 0\n#41 Issue 41 (no milestone), unblocks 0')" "$(section secondary <<<"$out")"
check 'a Done when that names no issue' \
  'note: M1 · Stage 1 has no Done when that names an issue; the main path of M1 · Stage 1 is each of its issues without the bug label, and what they wait on' "$(grep '^note: ' <<<"$out")"
# A blocker in M3 of an M1 task is on the main path and ranks with M1.
reset
mark M1
put '19 20 21 40:M3'
blocks 19 40
blocks 20 40 21
check 'an M3 blocker ranks with M1 by its unblock count' \
  "$(printf '#40 Issue 40 (M3 · Stage 3), unblocks 2\n#21 Issue 21 (M1 · Stage 1), unblocks 1')" "$(bash "$scripts/next.sh" | section 'main path')"
# A sub-issue in a later milestone of an M1 parent is on the main path.
reset
mark M1
put '19 30:M3'
edit 30 ".parent = {number: 19, milestone: {number: $(msno M1)}, repository: {nameWithOwner: \"kalinichenko88/agent-skills\"}}"
edit 19 '.subIssuesSummary = {total: 1, completed: 0}'
check 'a sub-issue of an M1 parent' '#30 Issue 30 (M3 · Stage 3), unblocks 1' "$(bash "$scripts/next.sh" | section 'main path')"
# A cycle made by hand: neither is free, and the script ends.
reset
mark M1
put '20 21'
blocks 20 21
blocks 21 20
check 'a cycle ends, nothing offered' 'none' "$(bash "$scripts/next.sh" | section 'main path')"
# Nothing free in M1: the main path is from the next milestone.
reset
mark M1
put '19 40:M2'
edit 19 '.assignees.nodes = [{login: "someone"}]'
out=$(bash "$scripts/next.sh")
check 'fallback notes' \
  "$(printf 'note: M1 · Stage 1 has no Done when that names an issue; the main path of M1 · Stage 1 is each of its issues without the bug label, and what they wait on\nnote: nothing on the main path of M1 · Stage 1 is free; it is from M2 · Stage 2')" "$(sed -n 2,3p <<<"$out")"
check 'busy issue in progress' '#19 Issue 19: assigned to someone' "$(section 'in progress' <<<"$out")"
# The goal is the first current milestone alone, and the next goal is the next
# milestone in order, not the next current one.
reset
mark M1
mark M3
put '19 30:M3 40:M2 50:M4'
edit 19 '.assignees.nodes = [{login: "someone"}]'
out=$(bash "$scripts/next.sh")
check 'fallback by order' 'note: nothing on the main path of M1 · Stage 1 is free; it is from M2 · Stage 2' "$(grep '^note: nothing ' <<<"$out")"
check 'fallback main path' '#40 Issue 40 (M2 · Stage 2), unblocks 0' "$(section 'main path' <<<"$out")"
check 'a second current milestone is secondary' '#30 Issue 30 (M3 · Stage 3), unblocks 0' "$(section secondary <<<"$out" | head -1)"
# The main path is what the Done when of the goal names, with any label, and
# what that waits on. A number before the Done when, of another repository, or
# right after another number, as #41, names nothing: busy #41 is then not held
# on the main path. The rest of the goal milestone is secondary.
done_when() { ms 'map(if (.title | startswith("M1 ")) then .description = $d else . end)' --arg d "$1"; }
reset
done_when $'Fix #19 first.\n\nDone when:\n- a user signs up (#21)\n- the export works (#22, other/repo#23, #22#41)\n\nCurrent.'
put '19 20 21 22 23 40:M2 41:M2'
blocks 21 20
edit 22 '.labels.nodes = [{name: "bug"}]'
edit 41 '.assignees.nodes = [{login: "someone"}]'
out=$(bash "$scripts/next.sh")
check 'the goal and its Done when' \
  "$(printf 'goal: M1 · Stage 1\n  Done when:\n  - a user signs up (#21)\n  - the export works (#22, other/repo#23, #22#41)')" "$(sed -n 2,5p <<<"$out")"
check 'the named issues, a bug too, and what they wait on' \
  "$(printf '#20 Issue 20 (M1 · Stage 1), unblocks 1\n#22 Issue 22 (M1 · Stage 1), unblocks 0')" "$(section 'main path' <<<"$out")"
check 'what holds the rest of the main path' '#21 Issue 21 (M1 · Stage 1): blocked by #20' "$(section 'held on the main path' <<<"$out")"
check 'the rest of the goal milestone' \
  "$(printf '#19 Issue 19 (M1 · Stage 1), unblocks 0\n#23 Issue 23 (M1 · Stage 1), unblocks 0\n#40 Issue 40 (M2 · Stage 2), unblocks 0')" "$(section secondary <<<"$out")"
check 'no note on a Done when that names open issues' 0 "$(grep -c '^note: ' <<<"$out" || true)"
# A Done when as one sentence: the description of this repository's
# M3 · Skills hold in real runs, as GitHub gave it on 2026-11-11.
reset
done_when $'The skills do what their rules say in real runs: the conventions load and hold in subagents, and the end of a task leaves nothing for the person to do by hand.\n\nDone when the runs of #196 load the conventions before the first edit in 5 of 5 per task, the runs of #197 keep one direction between features in 5 of 5, a review subagent on the task of #227 invokes the conventions skills in 5 of 5 runs, a session that went into its worktree with cd removes the worktree and the branch itself (#195), the command for the project scope runs as the docs give it (#165), and `collect.sh` finds the issues of a repository whose remote still has its old name (#252).\n\nCurrent.'
put '165 195 196 197 227 252 19'
out=$(bash "$scripts/next.sh")
check 'a Done when sentence names six' 6 "$(grep -c '^==> #.*\[main path, ' "$(sed -n 's/^overlap: \([^ ]*\) .*/\1/p' <<<"$out")")"
# The same description, and every issue that it names is closed: the next
# milestone is the goal.
put '19 20 40:M2'
check 'a Done when of closed issues' \
  "$(printf 'note: every issue that the Done when of M1 · Stage 1 names is closed; it names none of its 2 open issues\nnote: nothing on the main path of M1 · Stage 1 is free; it is from M2 · Stage 2\ngoal: M2 · Stage 2')" \
  "$(bash "$scripts/next.sh" | sed -n 2,4p)"
# Every issue that it names is busy: the next milestone is the goal, current
# too, with no note on the Done when.
done_when $'Done when:\n- a user signs up (#20)\n\nCurrent.'
mark M2
put '20 40:M2'
edit 20 '.assignees.nodes = [{login: "someone"}]'
check 'a Done when of busy issues' \
  "$(printf 'note: nothing on the main path of M1 · Stage 1 is free; it is from M2 · Stage 2\ngoal: M2 · Stage 2')" \
  "$(bash "$scripts/next.sh" | sed -n 2,3p)"
# Nothing on the path is free, and only Later comes after: the goal stays.
reset
mark M5
put '19:M5'
edit 19 '.assignees.nodes = [{login: "someone"}]'
check 'no next milestone' \
  "$(printf 'goal: M5 · Stage 5\nnote: M5 · Stage 5 has no Done when that names an issue; the main path of M5 · Stage 5 is each of its issues without the bug label, and what they wait on\n== main path')" \
  "$(bash "$scripts/next.sh" | sed -n 2,4p)"
# A task in Later that an issue outside Later waits on, through any chain, is
# offered; one that nothing outside Later waits on is not.
reset
mark M1
put '19 42:Later 43:Later 44:Later'
blocks 19 42
blocks 42 43
out=$(bash "$scripts/next.sh")
check 'a task in Later that M1 waits on' '#43 Issue 43 (Later), unblocks 2' "$(section 'main path' <<<"$out")"
check 'a task in Later that nothing waits on' 'none' "$(section secondary <<<"$out")"
# The top 5, the rest counted; Later never offered.
reset
put '1:- 2:- 3:- 4:- 5:- 6:- 7:- 8:Later'
check 'and k more' 'and 2 more' "$(bash "$scripts/next.sh" | section secondary | tail -1)"
check 'Later is not offered' 0 "$(bash "$scripts/next.sh" | grep -c '^#8 ' || true)"

# The main path shows its top 5 too; the overlap file takes all of it.
reset
put '1 2 3 4 5 6 7'
out=$(bash "$scripts/next.sh")
check 'the main path shows its top 5' 'and 2 more' "$(section 'main path' <<<"$out" | tail -1)"
check 'the overlap file takes the whole main path' 7 \
  "$(grep -c '^==> #.*\[main path, ' "$(sed -n 's/^overlap: \([^ ]*\) .*/\1/p' <<<"$out")")"

# The overlap file.
overlap() { bash "$scripts/next.sh" | sed -n 's/^overlap: \([^ ]*\) .*/\1/p'; }
reset
put '19 21'
edit 21 '.assignees.nodes = [{login: "someone"}] | .linkedBranches.nodes = [{ref: {name: "fix/21-x"}}]'
printf 'Fix `src/server/log.ts:12-14` and src/app/main.ts, see https://github.com/x/y/blob/main/z.ts and e.g. this.\n' >"$FAKE/body-19"
f=$(overlap)
check 'cites' 'cites: src/server/log.ts, src/app/main.ts' "$(grep '^cites: ' "$f")"
printf 'Plan\n====\nFix src/a/b.ts\n' >"$FAKE/body-19"
check 'a body line that starts with == stays in its entry' ' ====' "$(sed -n '/^==> #19 /,/^==> /p' "$(overlap)" | grep '=====*$')"
check 'branch files from compare' "files: $(jq -r '[.files[].filename] | join(", ")' "$fixtures/compare.json")" \
  "$(sed -n '/^==> #21 /,/^==> /p' "$f" | grep '^files: ')"
check 'a failed compare is no diff yet' 'no diff yet' "$(sed -n '/^==> #21 /{n;p;}' "$(FAKE_FAIL='compare/' overlap)")"
check 'PRs closing no issue' "$(jq '.data.repository.pullRequests.nodes | length' "$fixtures/prs-1.json")" \
  "$(bash "$scripts/next.sh" | grep -c '^PR #.*: closes no open issue$')"
# An open PR that closes only issues closed already is work in progress too.
jq '.data.repository.pullRequests.nodes[].closingIssuesReferences.nodes = [{number: 999, repository: {nameWithOwner: "kalinichenko88/agent-skills"}}]' \
  "$fixtures/prs-1.json" >"$FAKE/prs-1.json"
check 'PRs closing only closed issues' "$(jq '.data.repository.pullRequests.nodes | length' "$fixtures/prs-1.json")" \
  "$(bash "$scripts/next.sh" | grep -c '^PR #.*: closes no open issue$')"
echo '{"files": []}' >"$FAKE/compare.json"
check 'no diff yet' 'no diff yet' "$(sed -n '/^==> #21 /{n;p;}' "$(overlap)")"
# The files of an open PR that closes the issue win over the branch, and past
# 100 they come from REST.
jq '.data.repository.pullRequests.nodes[0].closingIssuesReferences.nodes = [{number: 21, repository: {nameWithOwner: "kalinichenko88/agent-skills"}}]
  | .data.repository.pullRequests.nodes[0].files |= {totalCount: 150, nodes: .nodes[:1]}' "$fixtures/prs-1.json" >"$FAKE/prs-1.json"
check 'all the files of a large PR' "files: $(jq -r '[.[].filename] | join(", ")' "$fixtures/pr-files.json")" \
  "$(sed -n '/^==> #21 /,/^==> /p' "$(overlap)" | grep '^files: ')"
jq '.[0].filename = "docs/a\\new.md"' "$fixtures/pr-files.json" >"$FAKE/pr-files.json"
check 'a file name with a backslash' 'docs/a\new.md' "$(sed -n '/^==> #21 /,/^==> /p' "$(overlap)" | sed -n 's/^files: \([^,]*\),.*/\1/p')"
# GitHub can give no file list for a PR.
jq '.data.repository.pullRequests.nodes[0].files = null' "$fixtures/prs-1.json" >"$FAKE/prs-1.json"
bash "$scripts/next.sh" >/dev/null 2>&1 || fail 'next.sh stops on a PR without a file list'
# No milestones at all.
reset
ms '[]'
put '19:-'
check 'no milestones' 'current: none' "$(bash "$scripts/next.sh" | head -1)"
# A failed read stops the script.
FAKE_FAIL='pullRequests(' bash "$scripts/next.sh" >/dev/null 2>&1 && fail 'next.sh exits 0 when a read fails'
check 'next.sh prints nothing when a read fails' '' "$(FAKE_FAIL='milestones?' bash "$scripts/next.sh" 2>/dev/null || true)"
FAKE_FAIL='milestones(states' bash "$scripts/next.sh" >/dev/null 2>&1 || fail 'next.sh reads the counts it does not print'
echo 'roadmap_next_test: ok'
