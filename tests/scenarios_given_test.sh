#!/usr/bin/env bash
# Sets up the Given of each case of tests/scenarios_take_in/ with no model:
# take-in-check.sh reads it through the fake gh of tests/fake_gh.sh as the
# scenario of the case gives it, a git step of a Given that fails stops its
# setup, and the fake gh marks the writes that come after the work started
# and answers the reads that the Givens need.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_given_test: $1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
  exit 1
}

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
fake issue close 95 --duplicate-of 91
git -C "$tmp/wt" add README.md
git -C "$tmp/wt" -c user.name=kim -c user.email=kim@example.com commit -q -m x
fake issue comment 95 --body b
[ "$(jq -c .log "$tmp/fake.state.json")" = '["comment 95","edit 95","close 95 +changes","comment 95 +changes"]' ] ||
  fail 'the fake gh does not mark the writes after a change in a worktree' "$(jq -c .log "$tmp/fake.state.json")"
[ "$(jq -c '.issues[0] | [.state, .stateReason, .duplicateOf]' "$tmp/fake.state.json")" = '["CLOSED","DUPLICATE",91]' ] ||
  fail 'the fake gh does not close #95 as a duplicate of #91' "$(jq -c .issues "$tmp/fake.state.json")"
# As gh: a label that the repository lacks stops an edit before any write, a
# label that it has stops a create, and a label of another case is the same.
fake issue edit 95 --add-assignee rivera --add-label 'in progress' 2>/dev/null && fail 'the fake gh adds a label that the repository lacks'
[ "$(jq -c '.issues[0].assignees' "$tmp/fake.state.json")" = '["kim"]' ] || fail 'a failed edit of the fake gh writes'
fake label create 'in progress'
fake label create 'In Progress' 2>/dev/null && fail 'the fake gh creates a label that the repository has'
fake issue edit 95 --add-label 'In Progress'
fake issue edit 95 --remove-label 'in progress'
[ "$(jq -c '[.labels, .issues[0].labels]' "$tmp/fake.state.json")" = '[["in progress"],[]]' ] ||
  fail 'the fake gh does not add and remove a label' "$(jq -c '[.labels, .issues[0].labels]' "$tmp/fake.state.json")"
fake issue edit 95 --body c
[ "$(jq -r '.log[-1]' "$tmp/fake.state.json")" = 'edit 95 body +changes' ] || fail 'the fake gh does not log an edit of the body' "$(jq -c .log "$tmp/fake.state.json")"

# The Given of each case, as take-in-check.sh reads it through the fake gh on
# the message of the case.
take_in=$root/tests/scenarios_take_in.sh
given() { # given <case> <what take-in-check.sh prints>
  local w=$tmp/given/$1 got m
  mkdir -p "$tmp/given"
  bash "$take_in" setup "$w" "$1"
  # The task of the message: "#91, a branch only" names #91.
  m=$(bash "$take_in" cases | awk -F'\t' -v c="$1" '$1 == c { print $4 }')
  got=$(cd "$w" && PATH="$w.bin:$PATH" bash "$root/skills/github/scripts/take-in-check.sh" "${m%%,*}" 2>&1 || true)
  [ "$got" = "$2" ] || fail "take-in-check.sh does not read the Given of $1" "$got"
}
ahead() { printf '#91: branch fix/91-typo, %s commits ahead of main, last commit 2026-11-03T00:00:00Z' "$1"; }
for c in free dup busy assigned settled seen cited also branchonly stay samename unread; do given $c 'take #91'; done
for c in other afterwait; do given $c '#91: assigned to rivera'; done
given down 'HTTP 502: Bad Gateway (https://api.github.com/graphql)'
for c in closed closeddup; do given $c '#91: closed'; done
given otherpr '#91: PR #96 by rivera is open and closes it'
given mypr '#91: PR #96 by you is open and closes it'
mine=$(printf '#91: assigned to you\n#91: label in progress')
for c in inprogress here there afterstop; do given $c "$mine"; done
for c in linked linkedother linkedmine linkedhere linkedthere; do given $c "$(ahead 0)"; done
given inws "$(printf '#91: assigned to you\n%s\ncontinue #91 on fix/91-typo' "$(ahead 0)")"
for c in conv ahead; do given $c "$(printf '%s\n%s\ncontinue #91 on fix/91-typo' "$mine" "$(ahead 0)")"; done
given myprws "$(printf '%s\n#91: PR #96 by you is open and closes it\ncontinue #91 on fix/91-typo' "$mine")"
given forkonly "$(printf '%s\n%s' "$mine" "$(ahead 0)")"
given otherws "$(printf '#91: assigned to rivera\n%s' "$(ahead 0)")"
given moved "$(printf '#91: assigned to you\n%s' "$(ahead 1)")"
given otherrepo '#91 is in acme/lib, and this checkout is acme/shop: stop'
# A git step of a Given that fails stops setup, at that step: a clone that has
# no place, a branch with a lock file on the origin or in the workspace, and a
# push to a branch with a lock file on the origin. A step before the clone
# stops setup before it, so no clone is left.
for t in otherpr:clone mypr:clone linked:origin inws:workspace moved:origin moved:clone; do
  c=${t%%:*} w=$tmp/broken/${t%%:*}-${t#*:}
  case ${t#*:} in
    clone) mkdir -p "$w.elsewhere/x" && step='already exists' ;;
    origin) mkdir -p "$w.origin/refs/heads/fix" && : >"$w.origin/refs/heads/fix/91-typo.lock" && step=lock ;;
    workspace) mkdir -p "$w/.git/refs/heads/fix" && : >"$w/.git/refs/heads/fix/91-typo.lock" && step=lock ;;
  esac
  { ! err=$(bash "$take_in" setup "$w" "$c" 2>&1 >/dev/null) && grep -q "$step" <<<"$err"; } ||
    fail "the setup of $c does not stop at its git step that fails: $t" "$err"
  [ "${t#*:}" = clone ] || [ ! -e "$w.elsewhere" ] || fail "the setup of $c goes on to the clone after its git step fails: $t"
done
# The snapshot gives the last commit of a branch, and marks a branch whose
# worktree has a changed file.
w=$tmp/given/inws
git -C "$w" worktree add -q "$w.wt" fix/91-typo
echo x >>"$w.wt/README.md"
bash "$take_in" snapshot "$w" "$tmp/snap"
[ "$(grep '^fix/91-typo ' "$tmp/snap.workspace")" = "fix/91-typo $(git -C "$w" rev-parse fix/91-typo) changed" ] ||
  fail 'the snapshot does not give the last commit and the change of fix/91-typo' "$(cat "$tmp/snap.workspace")"
# The task of another repository reads by its link, and is no task of this one.
w=$tmp/given/otherrepo
[ "$(cd "$w" && PATH="$w.bin:$PATH" gh issue view https://github.com/acme/lib/issues/91 --json title --jq .title)" = \
  'README: the install command says npm instal' ] || fail 'the fake gh does not read #91 of acme/lib by its link'
[ "$(cd "$w" && PATH="$w.bin:$PATH" gh issue view 91 --repo acme/lib --json title --jq .title)" = \
  'README: the install command says npm instal' ] || fail 'the fake gh does not read #91 of acme/lib by --repo'
for call in 'issue view 91 --json title' 'issue edit 91 --add-assignee @me' 'issue develop 91 --name fix/91-x'; do
  # shellcheck disable=SC2086 # the words of the call
  ! (cd "$w" && PATH="$w.bin:$PATH" gh $call >/dev/null 2>&1) || fail "the fake gh takes #91 of acme/lib as a task of acme/shop: gh $call"
done
[ "$(cd "$w" && PATH="$w.bin:$PATH" bash "$root/skills/github/scripts/take-in-check.sh" 91 2>&1 || true)" = \
  'GraphQL: Could not resolve to an issue or pull request with the number of 91. (repository.issue)' ] ||
  fail 'take-in-check.sh 91 finds #91 of acme/lib in acme/shop'
# A task whose title and body no read gives: a view of either fails with a
# 502, a view of another field does not, and a list leaves the task out.
w=$tmp/given/unread
un_gh() { (cd "$w" && PATH="$w.bin:$PATH" gh "$@" 2>&1); }
{ [ "$(un_gh issue view 91 --json title,body || true)" = 'HTTP 502: Bad Gateway (https://api.github.com/graphql)' ] &&
  [ "$(un_gh issue view 91 || true)" = 'HTTP 502: Bad Gateway (https://api.github.com/graphql)' ] &&
  [ "$(un_gh issue view 91 --json assignees)" = '{"assignees":[]}' ] && [ "$(un_gh issue list --json number)" = '[]' ]; } ||
  fail 'the fake gh gives the title or the body of a task that no read gives, or no other field of it'
# The entries of collect.sh: none for that task, and the name of a linked
# branch of another repository.
entry='query { repository { n91: issueOrPullRequest(number: 91) { __typename } } }'
[ "$(un_gh api graphql -f query="$entry" --jq .data.repository)" = '{}' ] || fail 'collect.sh gets an entry of a task that no read gives'
w=$tmp/given/forkonly
[ "$(cd "$w" && PATH="$w.bin:$PATH" gh api graphql -f query="$entry" --jq '.data.repository.n91.linkedBranches.nodes[0].ref.name')" = fix/91-typo ] ||
  fail 'collect.sh gets no name of the linked branch of another repository'
# A linked branch of another repository: its link names that repository.
w=$tmp/given/forkonly
[ "$(cd "$w" && PATH="$w.bin:$PATH" gh issue develop --list 91)" = "$(printf 'fix/91-typo\thttps://github.com/lee/shop/tree/fix/91-typo')" ] ||
  fail 'the fake gh does not list the linked branch of another repository by its link'
# A branch that the origin has, made for #91 again: it stays as it is, and is
# linked once.
w=$tmp/given/linkedhere
was=$(git -C "$w.origin" rev-parse fix/91-typo)
(cd "$w" && PATH="$w.bin:$PATH" gh issue develop 91 --name fix/91-typo >/dev/null)
{ [ "$(git -C "$w.origin" rev-parse fix/91-typo)" = "$was" ] && [ "$(jq -c '.issues[0].linked' "$w.state.json")" = '["fix/91-typo"]' ]; } ||
  fail 'the fake gh makes again a branch that the origin has, or links it twice'
# A task that the fake gh made has no list of linked branches: a branch of it
# is linked all the same.
(cd "$w" && PATH="$w.bin:$PATH" gh issue create --title x >/dev/null && PATH="$w.bin:$PATH" gh issue develop 92 --name fix/92-x >/dev/null)
[ "$(jq -c '.issues[] | select(.number == 92) | .linked' "$w.state.json")" = '["fix/92-x"]' ] ||
  fail 'the fake gh links no branch to a task that it made'
# The pull request of another person, by number and by branch, and the lists
# that take it or not by its branch and its state.
w=$tmp/given/otherpr
pr_gh() { (cd "$w" && PATH="$w.bin:$PATH" gh "$@"); }
[ "$(pr_gh pr view 96 --json author --jq .author.login)" = rivera ] || fail 'the fake gh does not read #96'
[ "$(pr_gh pr view fix/91-install --json number --jq .number)" = 96 ] || fail 'the fake gh does not read #96 by its branch'
[ "$(pr_gh pr view fix/91-other --json number 2>&1)" = 'no pull requests found for branch "fix/91-other"' ] ||
  fail 'the fake gh does not say that a branch has no pull request'
[ "$(pr_gh pr list --head fix/91-install --json number)" = '[{"number":96}]' ] || fail 'the fake gh does not list #96 by its branch'
for list in '--head fix/91-other' '--state merged'; do
  # shellcheck disable=SC2086 # the words of the flags
  [ "$(pr_gh pr list $list --json number)" = '[]' ] || fail "the fake gh lists #96 for pr list $list"
done

echo 'scenarios_given_test: ok'
