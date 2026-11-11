#!/usr/bin/env bash
# Runs tests/scenarios_eval.sh with no model: the fake gh of tests/fake_gh.sh
# marks the writes that come after the work started, take-in-check.sh reads
# the Given of each case of tests/scenarios_take_in.sh through the fake gh as
# the scenario of the case gives it, the pass^k lines count
# the runs of each case over the folders given, and a stub claude shows that a
# run takes --model and stops before --max-cost.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
eval=$root/tests/scenarios_eval.sh
fixtures=$root/tests/fixtures/scenarios/take-in
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_runner_test: $1" >&2
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

# The Given of each case, as take-in-check.sh reads it through the fake gh on
# the message of the case.
take_in=$root/tests/scenarios_take_in.sh
given() { # given <case> <what take-in-check.sh prints>
  local w=$tmp/given/$1 got
  mkdir -p "$tmp/given"
  bash "$take_in" setup "$w" "$1"
  got=$(cd "$w" && PATH="$w.bin:$PATH" bash "$root/skills/github/scripts/take-in-check.sh" \
    "$(bash "$take_in" cases | awk -v c="$1" '$1 == c { print $3 }')" 2>&1 || true)
  [ "$got" = "$2" ] || fail "take-in-check.sh does not read the Given of $1" "$got"
}
ahead() { printf '#91: branch fix/91-typo, %s commits ahead of main, last commit 2026-11-03T00:00:00Z' "$1"; }
for c in free dup busy; do given $c 'take #91'; done
given other '#91: assigned to rivera'
given down 'HTTP 502: Bad Gateway (https://api.github.com/graphql)'
given closed '#91: closed'
given otherpr '#91: PR #96 by rivera is open and closes it'
given mypr '#91: PR #96 by you is open and closes it'
given assigned '#91: assigned to you'
given linked "$(ahead 0)"
given inws "$(printf '#91: assigned to you\n%s\ncontinue #91 on fix/91-typo' "$(ahead 0)")"
given moved "$(printf '#91: assigned to you\n%s' "$(ahead 1)")"
given otherrepo '#91 is in acme/lib, and this checkout is acme/shop: stop'
# The task of another repository reads by its link, and is no task of this one.
w=$tmp/given/otherrepo
[ "$(cd "$w" && PATH="$w.bin:$PATH" gh issue view https://github.com/acme/lib/issues/91 --json title --jq .title)" = \
  'README: the install command says npm instal' ] || fail 'the fake gh does not read #91 of acme/lib by its link'
for call in 'issue view 91 --json title' 'issue edit 91 --add-assignee @me' 'issue develop 91 --name fix/91-x'; do
  # shellcheck disable=SC2086 # the words of the call
  ! (cd "$w" && PATH="$w.bin:$PATH" gh $call >/dev/null 2>&1) || fail "the fake gh takes #91 of acme/lib as a task of acme/shop: gh $call"
done
[ "$(cd "$w" && PATH="$w.bin:$PATH" bash "$root/skills/github/scripts/take-in-check.sh" 91 2>&1 || true)" = \
  'GraphQL: Could not resolve to an issue or pull request with the number of 91. (repository.issue)' ] ||
  fail 'take-in-check.sh 91 finds #91 of acme/lib in acme/shop'
# The pull request of another person, by number and by branch, and the lists
# that take it or not by its branch and its state.
w=$tmp/given/otherpr
pr_gh() { (cd "$w" && PATH="$w.bin:$PATH" gh "$@"); }
[ "$(pr_gh pr view 96 --json author --jq .author.login)" = rivera ] || fail 'the fake gh does not read #96'
[ "$(pr_gh pr view fix/91-install --json number --jq .number)" = 96 ] || fail 'the fake gh does not read #96 by its branch'
[ "$(pr_gh pr list --head fix/91-install --json number)" = '[{"number":96}]' ] || fail 'the fake gh does not list #96 by its branch'
for list in '--head fix/91-other' '--state merged'; do
  # shellcheck disable=SC2086 # the words of the flags
  [ "$(pr_gh pr list $list --json number)" = '[]' ] || fail "the fake gh lists #96 for pr list $list"
done

# pass^2 over the recorded runs and a copy: a second run in which free fails
# an item and busy has no run.
cp -R "$fixtures" "$tmp/2"
jq '.issues[0].linked += ["fix/91-other"]' "$fixtures/free.state.json" >"$tmp/2/free.state.json"
rm "$tmp/2"/busy.*
got=$("$eval" --check "$fixtures" "$tmp/2")
[ "$(grep '^pass' <<<"$got" | grep -v ': PASS, 2 of 2 runs pass$')" = 'pass^2 busy: not measured, 1 run of 2
pass^2 dup: FAIL, 0 of 2 runs pass
pass^2 free: FAIL, 1 of 2 runs pass' ] && [ "$(grep -c '^pass' <<<"$got")" = 13 ] ||
  fail 'pass^2 does not count the runs of each case' "$got"
[ "$(grep -E '^(round |busy: no run)' <<<"$got")" = "round 1 of 2
round 2 of 2
busy: no run: $tmp/2 has no busy.events, as when its setup fails" ] || fail 'the report does not name each round and the run that is missing' "$got"
# A round folder of a run that kept no snapshot of its Given: the case is not
# checked, and not measured.
cp -R "$fixtures" "$tmp/old"
rm "$tmp/old"/other.given.*
got=$("$eval" --check "$tmp/old" 2>/dev/null)
{ grep -qxF 'other: not checked, as its check says above' <<<"$got" && grep -qxF 'pass^1 other: not measured, 0 runs of 1' <<<"$got"; } ||
  fail 'a run with no snapshot of its Given is checked' "$got"

# A stub claude records its arguments and costs $1.50 a run. A folder that
# cannot run it, or a claude function, would leave the real claude in its place.
mkdir "$tmp/stub"
printf '#!/usr/bin/env bash\necho "$*" >>%q\necho %q\n' "$tmp/stub.args" \
  '{"type":"result","subtype":"success","total_cost_usd":1.5}' >"$tmp/stub/claude"
chmod +x "$tmp/stub/claude"
[ "$(PATH="$tmp/stub:$PATH" command -v claude || true)" = "$tmp/stub/claude" ] || fail 'claude is not the stub'
# stub <argument>...: the report of the eval with the stub claude.
stub() {
  local r
  rm -f "$tmp/stub.args"
  r=$(PATH="$tmp/stub:$PATH" "$eval" "$@") || fail "the eval with a stub claude exits with an error: $*" "$r"
  rm -rf "$(sed -n 's/^runs: //p' <<<"$r")"
  printf '%s\n' "$r"
}
# By default, a run of free is on opus with a cap of $4.
got=$(stub free)
grep -qe '--model opus .*--max-budget-usd 4 --disallowedTools ListAgents ' "$tmp/stub.args" ||
  fail 'free does not run on opus with a cap of 4 dollars and no ListAgents' "$(cat "$tmp/stub.args")"
# A round of other and down can cost $4: with a cap of $10, the third round
# runs at $6.00 spent, and the fourth does not at $9.00.
got=$(stub --runs 4 --model haiku --max-cost 10 other down)
[ "$(grep -ce '--model haiku .*--max-budget-usd 2 ' "$tmp/stub.args")" = 6 ] ||
  fail 'other and down do not run on --model with a cap of 2 dollars' "$(cat "$tmp/stub.args")"
grep -qxF "other: success, \$1.5" <<<"$got" || fail 'the report does not give the result and the cost of a run' "$got"
grep -qxF "stopped before round 4 of 4: \$9.00 spent, and a round can cost \$4.00 more, past the cap of \$10" <<<"$got" ||
  fail 'the eval does not stop before its cap' "$got"
grep -qxF "cost: \$9.00" <<<"$got" || fail 'the eval does not print the cost of the pass' "$got"
[ "$(grep '^pass' <<<"$got")" = 'pass^4 other: FAIL, 0 of 3 runs pass
pass^4 down: FAIL, 0 of 3 runs pass' ] || fail 'pass^4 does not count three runs of four' "$got"
# A cap under the cost of one round stops the eval before its first round.
got=$(stub --runs 2 --max-cost 3 other down)
[ ! -e "$tmp/stub.args" ] || fail 'a cap under one round still runs' "$(cat "$tmp/stub.args")"
grep -qxF "stopped before round 1 of 2: \$0.00 spent, and a round can cost \$4.00 more, past the cap of \$3" <<<"$got" ||
  fail 'the eval does not stop before its first round' "$got"
[ "$(grep '^pass' <<<"$got")" = 'pass^2 other: not measured, 0 runs of 2
pass^2 down: not measured, 0 runs of 2' ] || fail 'a stop before the first round does not leave each case not measured' "$got"

# refused <argument>...: the eval exits 2 with its usage, and calls no claude.
# seq 0 prints 1 and 0 on macOS, so --runs 0 with no check would run twice.
refused() {
  local code=0 err
  rm -f "$tmp/stub.args"
  err=$(PATH="$tmp/stub:$PATH" "$eval" "$@" 2>&1 >/dev/null) || code=$?
  [ "$code" = 2 ] && [ "${err#usage:}" != "$err" ] && [ ! -e "$tmp/stub.args" ] ||
    fail "'$*' exits $code with '$err', not 2 with the usage and no run"
}
refused --runs 0 free
refused --runs
refused --max-cost 1.2.3 free
refused --model '' free
refused nocase
refused --check "$tmp/stub"


echo 'scenarios_runner_test: ok'
