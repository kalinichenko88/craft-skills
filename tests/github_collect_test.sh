#!/usr/bin/env bash
# Runs collect.sh of the github skill against the fake gh of
# tests/github_harness.sh.

set -eu

# shellcheck source=tests/github_harness.sh
. "$(dirname "$0")/github_harness.sh"

# status: and also: of a host. As recorded, #5's one open pull request is #9,
# which you wrote and which only names #5.
answer .
check 'status of an issue whose one open PR is yours' "$(printf 'state: open\nstatus: PR #9 by you\nalso: 0')" \
  "$(bash "$scripts/collect.sh" status 5)"
check 'status takes the number with its #' "$(bash "$scripts/collect.sh" status 5)" \
  "$(bash "$scripts/collect.sh" status '#5')"

answer '.timelineItems.nodes = []'
check 'status of a free issue' "$(printf 'state: open\nstatus: free\nalso: 0')" \
  "$(bash "$scripts/collect.sh" status 5)"

# An assignee says who may take an issue, not that its work runs (#285): your
# own assignee alone leaves it free. The label in progress, in any case, makes
# it busy.
answer '.timelineItems.nodes = [] | .assignees.nodes = [{login: "kalinichenko88"}]'
check 'status of an issue whose one mark is your assignee' "$(printf 'state: open\nstatus: free\nalso: 0')" \
  "$(bash "$scripts/collect.sh" status 5)"
answer '.timelineItems.nodes = [] | .assignees.nodes = [{login: "kalinichenko88"}] | .labels.nodes += [{name: "In Progress"}]'
check 'status of an issue in progress' 'status: assigned to you, label in progress' \
  "$(bash "$scripts/collect.sh" status 5 | sed -n '/^status: /p')"

answer '.assignees.nodes = [{login: "someone"}]
  | .linkedBranches.nodes = [{ref: {name: "fix/5-citations"}}, {ref: null}]
  | .closedByPullRequestsReferences.nodes = [{number: 12, state: "OPEN", author: {login: "someone"}},
      {number: 11, state: "MERGED", author: {login: "someone"}}]
  | .timelineItems.nodes += [
      {isCrossRepository: false, source: {__typename: "PullRequest", number: 12, title: "t", state: "OPEN", author: {login: "someone"}}},
      {isCrossRepository: false, source: {__typename: "PullRequest", number: 13, title: "t", state: "OPEN", author: null}},
      {isCrossRepository: true, source: {__typename: "PullRequest", number: 14, title: "t", state: "OPEN", author: {login: "someone"}}},
      {isCrossRepository: false, source: {__typename: "Issue", number: 15, title: "t", state: "OPEN"}}]'
check 'status of a busy issue' \
  "$(printf 'status: assigned to someone, branch fix/5-citations, PR #9 by you, PR #12 by someone, PR #13 by ghost\nalso: 0')" \
  "$(bash "$scripts/collect.sh" status 5 | sed 1d)"

answer '.body += "\n\n## Also: one\r\n\r\nx\n\n## Also: two\n\nNot a heading: ## Also: three\n### Also: four\n"'
check 'also: counts the added sections' 'also: 2' \
  "$(bash "$scripts/collect.sh" status 5 | sed -n '/^also: /p')"

# bodies gives no second entry to a number already in the file.
printf '== Bodies\n\n==> #5 The scout misses a cited line open\n' >"$tmp/collected"
: >"$tmp/calls"
out=$(bash "$scripts/collect.sh" bodies "$tmp/collected" '#5')
case $out in 'already in the file: #5'*) ;; *) fail 'bodies with a number already in the file' "$out" ;; esac
check 'bodies adds nothing for a number already in the file' 3 "$(wc -l <"$tmp/collected" | tr -d ' ')"
check 'bodies queries nothing for a number already in the file' '' "$(grep graphql "$tmp/calls" || true)"

# bodies gives no entry to the issue that a duplicate duplicates, when the
# file holds it already, nor to one in another repository.
here='{nameWithOwner: "kalinichenko88/agent-skills"}'
answer "{n7: (.n5 | .number = 7 | .state = \"CLOSED\" | .stateReason = \"DUPLICATE\" | .duplicateOf = {number: 5, repository: $here})}" .data.repository
: >"$tmp/calls"
bash "$scripts/collect.sh" bodies "$tmp/collected" 7 >/dev/null
check 'bodies does not fetch an issue already in the file' '' "$(grep 'n5: issueOrPullRequest' "$tmp/calls" || true)"
check 'bodies counts only the new entries' '== end: 1 entries' "$(tail -1 "$tmp/collected")"
answer '{n7: (.n5 | .number = 7 | .state = "CLOSED" | .stateReason = "DUPLICATE"
  | .duplicateOf = {number: 3, repository: {nameWithOwner: "other/repo"}})}' .data.repository
printf '== Bodies\n' >"$tmp/collected"
: >"$tmp/calls"
bash "$scripts/collect.sh" bodies "$tmp/collected" 7 >/dev/null
check 'bodies does not fetch a duplicate of another repository here' '' "$(grep 'n3: issueOrPullRequest' "$tmp/calls" || true)"
grep -q '^duplicate of: other/repo#3$' "$tmp/collected" || fail 'an entry names the other repository of its duplicate'

# A failed query stops bodies before it writes: the duplicateOf query, and the
# one that reads the entries.
answer .
printf '== Bodies\n' >"$tmp/collected"
for failing in '{ ... on Issue { repository { nameWithOwner } duplicateOf' 'comments(first'; do
  FAKE_FAIL=$failing bash "$scripts/collect.sh" bodies "$tmp/collected" 5 >/dev/null 2>&1 &&
    fail "bodies exits 0 when the query with \"$failing\" fails"
  check "bodies writes nothing when the query with \"$failing\" fails" '== Bodies' "$(cat "$tmp/collected")"
done

# filing writes the open titles, each search, and the bodies of its open hits.
out=$(bash "$scripts/collect.sh" filing scout.md)
collected=${out%%: *}
check 'filing lists every open issue' 5 "$(sed -n '/^== Open issues/,/^== Search/p' "$collected" | grep -c ' open$')"
check 'filing finds the hits when the remote holds the old name of the repository' 0 "$(grep -c '^none$' "$collected" || true)"
check 'filing gives a body to each open hit' \
  "$(printf '==> #5 \n==> #8 \n==> PR #9 \n==> #10 \n== end: 4 entries')" \
  "$(grep -E '^==> |^== end' "$collected" | sed -E 's/^(==> (PR )?#[0-9]+ ).*/\1/')"
out=$(bash "$scripts/collect.sh" filing typescript)
check 'filing ends the bodies with no open hit' '== end: 0 entries' "$(tail -1 "${out%%: *}")"

# Past the limit, the bodies of the hits that the most names found come first:
# #8 is found by both names here, and the ties go newest first.
jq '[.[] | select(.number == 8)]' "$fixtures/issues-scout.md.json" >"$tmp/issues-sheet.json"
out=$(COLLECT_LIMIT=1 bash "$scripts/collect.sh" filing scout.md sheet)
check 'past the limit, the file names the hits it left out, in rank order' \
  "$(printf '== end: 0 entries\n\n== Left out\n\nThe file reached its limit of 0 KB. These hits have no entry, the timeline first, then the ones the most names found: #8 #10 #9 #5')" \
  "$(sed -n '/^== end/,$p' "${out%%: *}")"
whole=$(bash "$scripts/collect.sh" filing scout.md sheet)
whole=${whole%%: *}
head=$(sed '/^== Bodies$/,$d' "$whole" | wc -c)
eight=$(awk '/^==> / { p = /^==> #8 / } /^== end/ { p = 0 } p' "$whole" | wc -c)
out=$(COLLECT_LIMIT=$((head + eight + 10)) bash "$scripts/collect.sh" filing scout.md sheet)
check 'the limit keeps the first hits that fit, and leaves out the rest' \
  "$(printf '==> #8 \n== end: 1 entries\nhave no entry, the timeline first, then the ones the most names found: #10 #9 #5')" \
  "$(grep -E '^==> |^== end|have no entry' "${out%%: *}" | sed -E 's/^(==> (PR )?#[0-9]+ ).*/\1/; s/.*(have no entry)/\1/')"
rm "$tmp/issues-sheet.json"

# A path is searched by its base name too; an empty name is not searched.
: >"$tmp/calls"
bash "$scripts/collect.sh" filing '' skills/github/scout.md/ >/dev/null
check 'filing searches each name and base name once' \
  "$(printf 'skills/github/scout.md\nscout.md')" \
  "$(sed -n 's/^issue list .* --search \(.*\) --json.*/\1/p' "$tmp/calls")"

# A failed query leaves no file behind.
collects() { find "$tmp" -maxdepth 1 -name 'collect.*' | wc -l | tr -d ' '; }
before=$(collects)
FAKE_FAIL='comments(first' bash "$scripts/collect.sh" filing scout.md >/dev/null 2>&1 &&
  fail 'filing exits 0 when a query fails'
check 'a failed filing leaves no file behind' "$before" "$(collects)"
stops collect.sh 2 filing scout.md
printf '== Bodies\n' >"$tmp/collected"
stops collect.sh 1 bodies "$tmp/collected" 5

# take-in starts with the issue and its timeline, then the bodies of the
# timeline and of the open hits. An issue with a bug or debt label that
# nothing else brings, as #6 and #7 here, has its open title only.
: >"$tmp/calls"
out=$(bash "$scripts/collect.sh" take-in '#5' 'enhancement, bug ' scout.md)
collected=${out%%: *}
check 'take-in lists the timeline' \
  "$(printf 'PR #4 \n#8 \nPR #9 \n#10 ')" \
  "$(sed -n '/^== Its timeline/,/^== Open issues/p' "$collected" | sed -n -E 's/^((PR )?#[0-9]+ ).*/\1/p')"
check 'take-in gives the issue one entry, and a body to each hit' \
  "$(printf '==> #5 \n==> PR #4 \n==> #8 \n==> PR #9 \n==> #10 \n== end: 4 entries')" \
  "$(grep -E '^==> |^== end' "$collected" | sed -E 's/^(==> (PR )?#[0-9]+ ).*/\1/')"
check 'take-in names the bug and debt labels for the reader' \
  'Labels for bug and debt: enhancement, bug ' "$(grep '^Labels for bug and debt:' "$collected")"
grep -q '^#6 .* \[enhancement\] open$' "$collected" || fail 'take-in lists a bug or debt issue by its open title'
answer '.timelineItems.totalCount = 150'
out=$(bash "$scripts/collect.sh" take-in 5 '' scout.md)
grep -q '^Only the newest 100 of 150 references are here\.$' "${out%%: *}" ||
  fail 'take-in says when the timeline is cut'

check 'usage names every job' 4 "$(bash "$scripts/collect.sh" 2>&1 | grep -c '^usage: collect.sh ')"

echo 'github_collect_test: ok'
