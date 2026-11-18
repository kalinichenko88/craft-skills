#!/usr/bin/env bash
# Runs add-finding.sh, take-in-check.sh and keep-open.sh of the github skill
# against the fake gh of tests/github_harness.sh.

set -eu

# shellcheck source=tests/github_harness.sh
. "$(dirname "$0")/github_harness.sh"

# add-finding.sh refuses a busy host and a full one, and writes nothing.
printf '## Also: the scout misses a cited line\n\nWhere: scout.md:26.\n' >"$tmp/section.md"
add() { bash "$scripts/add-finding.sh" 5 "$tmp/section.md" 'New title' "$@"; }
# Sets #5 with no open pull request, so that its status: is free, changed by
# the jq filter $1.
host() { answer ".timelineItems.nodes = [] | $1"; }

# Your own entries make a host busy too: another session of yours can work on
# it, as #119 was while a session worked on it.
for case in 'yours|. + {assignees: {nodes: [{login: "kalinichenko88"}]}, linkedBranches: {nodes: [{ref: {name: "fix/5-citations"}}]}}|it is busy: assigned to you, branch fix/5-citations' \
  'busy|.assignees.nodes = [{login: "someone"}]|it is busy: assigned to someone' \
  'in progress|.labels.nodes += [{name: "in progress"}]|it is busy: label in progress' \
  'full|.body += "\n## Also: one\n## Also: two\n"|it holds 2 added findings already' \
  'closed|.state = "CLOSED"|it is closed' \
  'pull request|{__typename: "PullRequest", number: 5, title: "t", state: "OPEN", body: ""}|it is a pull request'; do
  IFS='|' read -r name change reason <<<"$case"
  host "$change"
  : >"$tmp/calls"
  out=$(add) && fail "add-finding.sh wrote to a $name host"
  case $out in *"$reason"*) ;; *) fail "add-finding.sh on a $name host" "$out" ;; esac
  check "add-finding.sh writes nothing to a $name host" '' "$(writes)"
done
# As recorded, #5's one open pull request is #9, which you wrote.
answer .
: >"$tmp/calls"
out=$(add) && fail 'add-finding.sh wrote to a host with your open PR'
case $out in *'it is busy: PR #9 by you'*) ;; *) fail 'add-finding.sh on a host with your open PR' "$out" ;; esac
check 'add-finding.sh writes nothing to a host with your open PR' '' "$(writes)"

# A free host takes the finding. DRY_RUN=1 prints the writes and runs none.
host .
: >"$tmp/calls"
out=$(DRY_RUN=1 add bug)
case $out in *'dry run: gh issue edit 5 --title New\ title --body-file '*'--add-label bug'*'dry run: gh issue comment 5'*) ;;
  *) fail 'add-finding.sh with DRY_RUN=1 prints its writes' "$out" ;;
esac
[ -f "$(sed -n 's/.*--body-file \([^ ]*\) .*/\1/p' <<<"$out")" ] || fail 'a dry run keeps the body it names'
check 'add-finding.sh with DRY_RUN=1 runs no write' '' "$(writes)"

# Without it, the body keeps the old text and gains the section.
host .
: >"$tmp/calls"
add >/dev/null
check 'add-finding.sh edits and comments' \
  "$(printf 'issue edit 5 --title New title --body-file %s\nissue comment 5 --body Added to the body: the scout misses a cited line.' \
    "$(sed -n 's/^issue edit 5 --title New title --body-file //p' "$tmp/calls")")" "$(writes)"
check 'the new body is the old one and the section' \
  "$(jq -r .data.repository.n5.body "$fixtures/tracker.json"; echo; cat "$tmp/section.md")" "$(cat "$tmp/body")"
stops add-finding.sh 1 5 "$tmp/section.md" 'New title'

# The comment fails after the edit. The rerun reads the edited body, finds the
# section there, adds the label again without the body or the title, and
# comments, on a host with no added finding before and on one with one before.
for change in . '.body += "\n## Also: one\n"'; do
  host "$change"
  rm -f "$tmp/body"
  FAKE_FAIL='issue comment' add bug >/dev/null 2>&1 && fail 'add-finding.sh passed with a failed comment'
  [ -f "$tmp/body" ] || fail "add-finding.sh did not edit before the comment ($change)"
  host ".body = $(jq -Rs . "$tmp/body")"
  : >"$tmp/calls"
  out=$(add bug) || fail "a rerun of add-finding.sh after a failed comment ($change)" "$out"
  check "a rerun after a failed comment leaves the body ($change)" \
    "$(printf 'issue edit 5 --add-label bug\nissue comment 5 --body Added to the body: the scout misses a cited line.')" \
    "$(writes)"
  check "the body holds the section once ($change)" 1 \
    "$(grep -cxF '## Also: the scout misses a cited line' "$tmp/body")"
done

# A dry rerun with no label prints only the comment, and removes the body that
# no printed edit names.
rm -f "$tmp"/body.*
host '.body += "\n## Also: the scout misses a cited line\n"'
check 'a dry rerun with no label only comments' \
  'dry run: gh issue comment 5 --body Added\ to\ the\ body:\ the\ scout\ misses\ a\ cited\ line.' "$(DRY_RUN=1 add)"
check 'a dry rerun leaves no body' '' "$(find "$tmp" -maxdepth 1 -name 'body.*')"

# A refusal before the body read leaves the file that the caller's $body
# names. One after it, in a dry run, removes its own body.
touch "$tmp/keep"
for change in '.state = "CLOSED"' '.body += "\n## Also: one\n## Also: two\n"'; do
  host "$change"
  body=$tmp/keep DRY_RUN=1 add >/dev/null && fail "add-finding.sh passed on a refused host ($change)"
  [ -f "$tmp/keep" ] || fail "a refusal removed the file that \$body names ($change)"
  check "a refused dry run leaves no body ($change)" '' "$(find "$tmp" -maxdepth 1 -name 'body.*')"
done

# take-in-check.sh, in a checkout of its own: it reads the local branches.
git init -q "$tmp/repo"
take() { (cd "$tmp/repo" && bash "$scripts/take-in-check.sh" "$@" 2>&1) || echo "exit $?"; }
answer . .data.repository.issue take-in-20.json
check 'take-in-check.sh on a free issue' 'take #20' "$(take 20)"
# As recorded, #231 is assigned to you and has nothing else: an assignee says
# who may take an issue, not that its work runs (#285). #285 is assigned to
# you, with the label in progress and a linked branch.
answer . .data.repository.issue take-in-231.json
check 'take-in-check.sh on an issue whose one mark is your assignee' 'take #231' "$(take 231)"
answer . .data.repository.issue take-in-285.json
check 'take-in-check.sh on an issue in progress' \
  "$(printf '#285: assigned to you\n#285: label in progress\n#285: branch fix/285-busy-by-work-not-assignee, 0 commits ahead of main, last commit 2026-11-11T13:26:37Z\nexit 1')" \
  "$(take 285)"
answer '.labels.nodes = [{name: "In Progress"}]' .data.repository.issue take-in-20.json
check 'take-in-check.sh on an issue in progress with no assignee' "$(printf '#20: label in progress\nexit 1')" "$(take 20)"
answer '.state = "CLOSED" | .assignees.nodes = [{login: "someone"}, {login: "kalinichenko88"}]
  | .closedByPullRequestsReferences.nodes = [{number: 9, state: "OPEN", author: {login: "someone"}},
      {number: 10, state: "OPEN", author: {login: "kalinichenko88"}}]' .data.repository.issue take-in-20.json
check 'take-in-check.sh on an issue someone else has' \
  "$(printf '#20: closed\n#20: assigned to someone\n#20: assigned to you\n#20: PR #9 by someone is open and closes it\n#20: PR #10 by you is open and closes it\nexit 1')" \
  "$(take '#20')"
# As recorded, #167 is assigned to you and has a linked branch. With no local
# copy of the branch, the work can run on another computer.
answer . .data.repository.issue take-in-167.json
yours167='#167: assigned to you
#167: branch fix/167-architecture-lens-exit2, 0 commits ahead of main, last commit 2026-10-28T13:08:52Z'
check 'take-in-check.sh on an issue that is yours, with its branch not on this computer' \
  "$(printf '%s\nexit 1' "$yours167")" "$(take 167)"
# A local copy that lacks the remote's last commit: work went on somewhere else.
git -C "$tmp/repo" -c user.name=t -c user.email=t commit -q --allow-empty -m 'Pushed work'
pushed=$(git -C "$tmp/repo" rev-parse HEAD)
git -C "$tmp/repo" -c user.name=t -c user.email=t commit -q --allow-empty -m 'Work not pushed yet'
git -C "$tmp/repo" branch fix/167-architecture-lens-exit2
git -C "$tmp/repo" branch fix/153-worktree-branch-owner
check 'take-in-check.sh on an issue whose local branch lacks the remote commit' \
  "$(printf '%s\nexit 1' "$yours167")" "$(take 167)"
# The local copy has the remote's last commit, and more: the work continues here.
answer ".linkedBranches.nodes[0].ref.target.oid = \"$pushed\"" .data.repository.issue take-in-167.json
check 'take-in-check.sh continues an issue whose branch is on this computer' \
  "$(printf '%s\ncontinue #167 on fix/167-architecture-lens-exit2' "$yours167")" "$(take 167)"
answer ".linkedBranches.nodes[0].ref.target.oid = \"$pushed\" | .labels.nodes = [{name: \"in progress\"}]" \
  .data.repository.issue take-in-167.json
check 'take-in-check.sh continues an issue in progress whose branch is on this computer' \
  "$(printf '#167: assigned to you\n#167: label in progress\n%s\ncontinue #167 on fix/167-architecture-lens-exit2' \
    "$(sed 1d <<<"$yours167")")" "$(take 167)"
answer ".linkedBranches.nodes[0].ref.target.oid = \"$pushed\" | .assignees.nodes = []" .data.repository.issue take-in-167.json
check 'take-in-check.sh does not continue an issue that nobody is assigned to' 'exit 1' "$(take 167 | tail -1)"
answer ".linkedBranches.nodes[0].ref.target.oid = \"$pushed\" | .assignees.nodes = [] | .labels.nodes = [{name: \"in progress\"}]" \
  .data.repository.issue take-in-167.json
check 'take-in-check.sh does not continue an issue in progress that nobody is assigned to' 'exit 1' "$(take 167 | tail -1)"
answer ".linkedBranches.nodes[0].ref.target.oid = \"$pushed\"
  | .linkedBranches.nodes[0].ref.repository.nameWithOwner = \"someone/agent-skills\"" .data.repository.issue take-in-167.json
check 'take-in-check.sh does not continue on a branch of another repository' 'exit 1' "$(take 167 | tail -1)"
# As recorded, #153 has your open pull request #181 and, so, no linked branch:
# the pull request's branch is the one the work continues on.
answer ".closedByPullRequestsReferences.nodes[0].headRefOid = \"$pushed\"" .data.repository.issue take-in-153.json
check 'take-in-check.sh continues an issue with your open pull request' \
  "$(printf '#153: assigned to you\n#153: PR #181 by you is open and closes it\ncontinue #153 on fix/153-worktree-branch-owner')" \
  "$(take 153)"
answer ".closedByPullRequestsReferences.nodes[0].headRefOid = \"$pushed\"
  | .assignees.nodes += [{login: \"someone\"}]" .data.repository.issue take-in-153.json
check 'take-in-check.sh does not continue an issue that someone else is assigned to' 'exit 1' "$(take 153 | tail -1)"
# Another account can have the login "you": the check compares logins.
answer ".closedByPullRequestsReferences.nodes[0].headRefOid = \"$pushed\"
  | .assignees.nodes = [{login: \"you\"}]" .data.repository.issue take-in-153.json
check 'take-in-check.sh does not continue an issue of the account "you"' 'exit 1' "$(take 153 | tail -1)"
# Two branches of yours, both here: which one holds the work is not sure.
answer "$(jq -c .data.repository.issue.linkedBranches "$fixtures/take-in-167.json") as \$linked
  | .closedByPullRequestsReferences.nodes[0].headRefOid = \"$pushed\"
  | .linkedBranches = \$linked | .linkedBranches.nodes[0].ref.target.oid = \"$pushed\"" \
  .data.repository.issue take-in-153.json
check 'take-in-check.sh does not continue an issue with two branches' 'exit 1' "$(take 153 | tail -1)"
check 'take-in-check.sh on an issue of another repository' \
  "$(printf '#179 is in octo-org/octo-repo, and this checkout is kalinichenko88/agent-skills: stop\nexit 1')" \
  "$(take https://github.com/octo-org/octo-repo/issues/179)"

# keep-open.sh removes the pull request's link to the one issue it is given.
# keep-open-21.json is PR #21's answer, with its link to #14 and a description
# that closes #14 with a keyword. $partof, the description of a Part of PR in a
# private tracker rewritten, puts the number before the word: it closes nothing.
# Its last line is PR #15's, with #14 for #13: the keyword is before #11 only.
# The cases add a link to #5, and one to another repository's #14.
export KEEP_OPEN_TRIES=1
refs=.data.repository.pullRequest.closingIssuesReferences.nodes
body=.data.repository.pullRequest.body
partof=$'Part of #14\n\nThe scaffold only. The service is made after the merge; then #14 closes.
Closes #11. #14 did the first half: it left out the bodies of label-only bug and debt issues.'
pr21=$(jq -r .data.repository.pullRequest.id "$fixtures/keep-open-21.json")
i14=$(jq -r "${refs}[0].id" "$fixtures/keep-open-21.json")
removed() { grep 'removeCloseIssueReferences' "$tmp/calls" | grep -oE 'pr=[^ ]+ -f issue=[^ ]+' || true; }
# A merge closes the issue from a keyword in the description whatever the
# script removes, as the merge of that private PR did: keep-open.sh refuses.
cp "$fixtures/keep-open-21.json" "$tmp/graphql.json"
: >"$tmp/calls"
out=$(bash "$scripts/keep-open.sh" 21 14) && fail 'keep-open.sh exits 0 on a description that closes the issue' "$out"
case $out in *$'\n  Closes #14.\n'*) ;; *) fail 'keep-open.sh names the line that closes the issue' "$out" ;; esac
check 'keep-open.sh removes nothing when the description closes the issue' '' "$(removed)"
check 'keep-open.sh takes #1 for #1, not for #14' 'PR #21 does not close #1: nothing to do' \
  "$(bash "$scripts/keep-open.sh" 21 1)"
# After a removal by an older keep-open.sh, the keyword stays and the link is gone.
jq "$refs = []" "$fixtures/keep-open-21.json" >"$tmp/graphql.json"
out=$(bash "$scripts/keep-open.sh" 21 14) && fail 'keep-open.sh exits 0 on a keyword whose link is gone' "$out"
jq --arg b "$partof"$'\nCloses #14.\n\nThen check the host, and close #14.' "$body = \$b" "$fixtures/keep-open-21.json" >"$tmp/graphql.json"
out=$(bash "$scripts/keep-open.sh" 21 14) && fail 'keep-open.sh exits 0 on "close #14" in a sentence' "$out"
case $out in *$'\n  Closes #14.\n  Then check the host, and close #14.\n'*) ;;
  *) fail 'keep-open.sh names each line that closes the issue, "close #14" in a sentence too' "$out" ;;
esac
case $out in *'then #14 closes'* | *'#14 did the first half'*) fail 'keep-open.sh names a line with no keyword before #14' "$out" ;; esac
for kw in 'Fixes #14' 'fixed: #14' 'fix #14' 'RESOLVES #14' 'resolved #14' 'resolve #14' 'closed #14'; do
  jq --arg b "$partof"$'\n'"$kw" "$body = \$b" "$fixtures/keep-open-21.json" >"$tmp/graphql.json"
  if bash "$scripts/keep-open.sh" 21 14 >/dev/null; then fail "keep-open.sh exits 0 on \"$kw\""; fi
done
jq --arg b "$partof" "$body = \$b | $refs |= [{id: \"I_5\", number: 5, repository: .[0].repository},
  {id: \"I_other\", number: 14, repository: {id: \"R_other\"}}] + ." "$fixtures/keep-open-21.json" >"$tmp/graphql.json"
: >"$tmp/calls"
check 'keep-open.sh says what it removed' 'PR #21 no longer closes #14' "$(bash "$scripts/keep-open.sh" '#21' 14)"
check 'keep-open.sh removes only the link to the issue it is given, in this repository' \
  "pr=$pr21 -f issue=$i14" "$(removed)"
: >"$tmp/calls"
out=$(DRY_RUN=1 bash "$scripts/keep-open.sh" 21 '#5')
case $out in "dry run: gh api graphql --silent -f pr=$pr21 -f issue=I_5 "*) ;;
  *) fail 'keep-open.sh prints its write in a dry run' "$out" ;;
esac
check 'keep-open.sh writes nothing in a dry run' '' "$(removed)"
check 'keep-open.sh on an issue the pull request does not close' 'PR #21 does not close #7: nothing to do' \
  "$(bash "$scripts/keep-open.sh" 21 7)"
check 'keep-open.sh writes nothing for an issue the pull request does not close' '' "$(removed)"
FAKE_FAIL=closingIssuesReferences bash "$scripts/keep-open.sh" 21 14 >/dev/null 2>&1 &&
  fail 'keep-open.sh exits 0 when it cannot read the links'
check 'keep-open.sh writes nothing when it cannot read the links' '' "$(removed)"
FAKE_FAIL=removeCloseIssueReferences bash "$scripts/keep-open.sh" 21 14 >/dev/null 2>&1 &&
  fail 'keep-open.sh exits 0 when the removal fails'
bash "$scripts/keep-open.sh" 21 abc >/dev/null 2>&1 && fail 'keep-open.sh takes a word for an issue number'
# GitHub adds a linked branch's link about a second after the pull request
# opens, as the timelines of #16 and #22 show: keep-open.sh reads again.
jq --arg b "$partof" "$body = \$b | $refs = []" "$fixtures/keep-open-21.json" >"$tmp/graphql.json"
jq --arg b "$partof" "$body = \$b" "$fixtures/keep-open-21.json" >"$tmp/graphql.next.json"
check 'keep-open.sh waits for the link GitHub adds after the pull request opens' 'PR #21 no longer closes #14' \
  "$(KEEP_OPEN_TRIES=2 bash "$scripts/keep-open.sh" 21 14)"

echo 'github_scripts_test: ok'
