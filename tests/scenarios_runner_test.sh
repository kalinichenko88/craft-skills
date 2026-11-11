#!/usr/bin/env bash
# Runs tests/scenarios_eval.sh with no model: the fake gh of tests/fake_gh.sh
# marks the writes that come after the work started, take-in-check.sh reads
# the Given of each case of tests/scenarios_take_in/ through the fake gh as
# the scenario of the case gives it, the pass^k lines count
# the runs of each case over the folders given, and a stub claude shows that a
# run takes --model, that the answer of a case of two messages resumes the
# session of its first message, and that the eval stops before --max-cost.

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
  [ "$(un_gh issue view 91 --json assignees)" = '{"assignees":[]}' ] && [ "$(un_gh issue list --json number)" = '[]' ]; } ||
  fail 'the fake gh gives the title or the body of a task that no read gives, or no other field of it'
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

# pass^2 over the recorded runs and a copy: a second run in which other fails
# an item and closed has no run.
cp -R "$fixtures" "$tmp/2"
jq '.issues[0].assignees += ["kim"]' "$fixtures/other.state.json" >"$tmp/2/other.state.json"
rm "$tmp/2"/closed.*
got=$("$eval" --check "$fixtures" "$tmp/2")
[ "$(grep -E '^pass\^2 (closed|dup|other):' <<<"$got")" = 'pass^2 closed: not measured, 1 run of 2
pass^2 dup: FAIL, 0 of 2 runs pass
pass^2 other: FAIL, 1 of 2 runs pass' ] && [ "$(grep -c '^pass' <<<"$got")" = "$(bash "$take_in" cases | grep -c .)" ] ||
  fail 'pass^2 does not count the runs of each case' "$got"
[ "$(grep -E '^(round |closed: no run)' <<<"$got")" = "round 1 of 2
round 2 of 2
closed: no run: $tmp/2 has no closed.events, as when its setup fails" ] || fail 'the report does not name each round and the run that is missing' "$got"
# A round folder of a run that kept no snapshot of its Given: the case is not
# checked, and not measured.
cp -R "$fixtures" "$tmp/old"
rm "$tmp/old"/other.given.*
got=$("$eval" --check "$tmp/old" 2>/dev/null)
{ grep -qxF 'other: not checked, as its check says above' <<<"$got" && grep -qxF 'pass^1 other: not measured, 0 runs of 1' <<<"$got"; } ||
  fail 'a run with no snapshot of its Given is checked' "$got"

# A stub claude records its arguments and starts session s1. A first session
# thinks, then asks whether the work runs somewhere else, in a thinking block
# that narration_block_indexes names, as Claude Code gives a message before a
# tool call (ADR 0008), and costs $1.50; a resumed one says that it stops, in
# a text block, and gives $2.50, the cost of both of its messages. A folder
# that cannot run it, or a claude function, would leave the real claude in its
# place.
mkdir "$tmp/stub"
printf '#!/usr/bin/env bash\nargs=%q\n' "$tmp/stub.args" >"$tmp/stub/claude"
cat >>"$tmp/stub/claude" <<'EOF'
echo "$*" >>"$args"
# The session of call <n> is s<n>. A session that reads its texts records the
# first one.
# It notes when it holds file descriptor 7, the pipe of its own texts.
case " $* " in *" --input-format stream-json "*) head -n 1 >"$args.stdin"; [ ! -e /dev/fd/7 ] || : >"$args.fd7" ;; esac
echo "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"s$(wc -l <"$args" | tr -d ' ')\"}"
case " $* " in
  *" --resume "*) cost=2.5
    echo '{"type":"assistant","message":{"content":[{"type":"text","text":"I stop here."}]}}' ;;
  *) cost=1.5
    echo '{"type":"assistant","thinking_display":"updates","message":{"content":[{"type":"thinking","thinking":"Where does it run?"}]}}'
    echo '{"type":"assistant","thinking_display":"updates","narration_block_indexes":[0],"message":{"content":[{"type":"thinking","thinking":"Does the work run\nsomewhere else?"}]}}' ;;
esac
# STUB_COMPANION gives the result of the other conversation, and STUB_BREAK
# breaks the workspace of a run that has one.
sub=success
case " $* " in
  *" --input-format stream-json "*) sub=${STUB_COMPANION:-success} ;;
  *) [ -z "${STUB_BREAK:-}" ] || [ ! -f "$PWD.companion" ] || rm -rf .git ;;
esac
echo "{\"type\":\"result\",\"subtype\":\"$sub\",\"total_cost_usd\":$cost}"
EOF
chmod +x "$tmp/stub/claude"
[ "$(PATH="$tmp/stub:$PATH" command -v claude || true)" = "$tmp/stub/claude" ] || fail 'claude is not the stub'
# stub <argument>...: the report of the eval with the stub claude.
# $tmp/stub.events keeps the events of its first round.
stub() {
  local r d
  rm -f "$tmp/stub.args"
  r=$(PATH="$tmp/stub:$PATH" "$eval" "$@") || fail "the eval with a stub claude exits with an error: $*" "$r"
  d=$(sed -n 's/^runs: //p' <<<"$r")
  cat "$d"/run1/*.events >"$tmp/stub.events" 2>/dev/null || true
  rm -rf "$d"
  printf '%s\n' "$r"
}
# By default, a run of free is on opus with a cap of $4.
got=$(stub free)
{ grep -qe '--model opus .*--max-budget-usd 4 ' "$tmp/stub.args" && grep -qe '--disallowedTools ListAgents --' "$tmp/stub.args"; } ||
  fail 'free does not run on opus with a cap of 4 dollars and no ListAgents' "$(cat "$tmp/stub.args")"
# The message of a case is the last argument.
got=$(stub otherrepo)
grep -qe ' https://github.com/acme/lib/issues/91$' "$tmp/stub.args" || fail 'otherrepo does not run on the link of #91' "$(cat "$tmp/stub.args")"
# The answer of there resumes session s1 of its first message, as the last
# argument. The cost of the run is its last result. The log gives the
# narrated question as a text line, its other thinking as a think line, and
# the answer after the question, so the Given of there holds, and the stub
# changes nothing: the case passes.
got=$(stub there)
{ [ "$(wc -l <"$tmp/stub.args")" -eq 2 ] && sed -n 1p "$tmp/stub.args" | grep -qe ' #91$' &&
  sed -n 2p "$tmp/stub.args" | grep -qe '--max-budget-usd 2 .*--resume s1 It runs somewhere else\.$'; } ||
  fail 'the answer of there does not resume the session of its first message' "$(cat "$tmp/stub.args")"
[ "$(cat "$tmp/stub.events")" = "$(printf 'think\tWhere does it run?\ntext\tDoes the work run somewhere else?\nperson\tIt runs somewhere else.\ntext\tI stop here.')" ] ||
  fail 'the log of there does not give the answer after the question of the first message' "$(cat "$tmp/stub.events")"
{ grep -qxF "there: success, \$2.5" <<<"$got" && grep -qxF "cost: \$2.50" <<<"$got"; } ||
  fail 'the cost of a run of two messages is not its last result' "$got"
grep -qxF 'pass^1 there: PASS, 1 of 1 runs pass' <<<"$got" || fail 'the Given of there does not hold on a question and its answer' "$got"
# Each answer of a case of three messages resumes the session of the message
# before it.
got=$(stub linkedhere)
{ [ "$(wc -l <"$tmp/stub.args")" -eq 3 ] && sed -n 2p "$tmp/stub.args" | grep -qe '--resume s1 It is mine\.$' &&
  sed -n 3p "$tmp/stub.args" | grep -qe '--resume s2 It continues here\.$'; } ||
  fail 'the answers of linkedhere do not resume the session of the message before each' "$(cat "$tmp/stub.args")"
# The other conversation of conv starts first, on Haiku with no tools, and
# reads "#91"; the run then has ListAgents, and the cases with no such
# conversation do not.
# It runs after the other cases of the round end, so that it sees no other run,
# and holds no copy of the pipe of its texts, so that the end of the run ends
# them.
rm -f "$tmp/stub.args.stdin" "$tmp/stub.args.fd7"
got=$(stub free conv)
{ sed -n 1p "$tmp/stub.args" | grep -qe '--disallowedTools ListAgents .* #91$' &&
  sed -n 2p "$tmp/stub.args" | grep -qe '--model haiku .*--input-format stream-json .*--tools ' &&
  [ "$(jq -r .message.content "$tmp/stub.args.stdin")" = '#91' ] && sed -n 3p "$tmp/stub.args" | grep -qe ' #91$' &&
  ! sed -n 3p "$tmp/stub.args" | grep -qe ListAgents && grep -qxF "$(printf 'companion\t#91')" "$tmp/stub.events" &&
  [ ! -e "$tmp/stub.args.fd7" ]; } ||
  fail 'conv does not start its other conversation on #91, after the other runs, before a run with ListAgents' "$(cat "$tmp/stub.args")"
# An other conversation that ends with an error gives no companion line, and
# conv is not checked. A run of conv that fails does not stop the eval.
got=$(STUB_COMPANION=error_max_budget_usd stub conv)
{ ! grep -q '^companion' "$tmp/stub.events" && grep -qxF 'conv: not checked, as its check says above' <<<"$got"; } ||
  fail 'an other conversation that ends with an error holds the Given of conv' "$got"
got=$(STUB_BREAK=1 stub free conv)
{ grep -q '^pass^1 free: ' <<<"$got" && grep -q '^runs: ' <<<"$got"; } || fail 'a run of conv that fails stops the eval' "$got"
# A round of here can cost $8, a cap of $4 for each of its two messages.
got=$(stub --max-cost 7 here)
{ [ ! -e "$tmp/stub.args" ] && grep -qxF "stopped before round 1 of 1: \$0.00 spent, and a round can cost \$8.00 more, past the cap of \$7" <<<"$got"; } ||
  fail 'the cap of a round does not count both messages of here' "$got"
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
