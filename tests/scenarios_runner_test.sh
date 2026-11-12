#!/usr/bin/env bash
# Runs tests/scenarios_eval.sh with no model: the pass^k lines count the runs
# of each case over the folders given, and a stub claude shows that a run
# takes --model, that each answer of a case of more messages resumes the
# session of the message before it, that the case of another conversation
# starts it and runs alone, and that the eval stops before --max-cost.
# tests/scenarios_given_test.sh checks the Given of each case.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
eval=$root/tests/scenarios_eval.sh
fixtures=$root/tests/fixtures/scenarios/take-in
take_in=$root/tests/scenarios_take_in.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_runner_test: $1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
  exit 1
}

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
case " $* " in *" --input-format stream-json "*) head -n 1 >"$args.stdin" ;; esac
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
# A session that reads its texts reads them to their end, and notes the end;
# with STUB_HANG, it does not end there.
case " $* " in *" --input-format stream-json "*) cat >/dev/null; : >"$args.end"; [ -z "${STUB_HANG:-}" ] || exec sleep 60 ;; esac
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
# and the end of the run is the end of its texts.
rm -f "$tmp/stub.args.stdin" "$tmp/stub.args.end"
got=$(stub free conv)
{ sed -n 1p "$tmp/stub.args" | grep -qe '--disallowedTools ListAgents .* #91$' &&
  sed -n 2p "$tmp/stub.args" | grep -qe '--model haiku .*--input-format stream-json .*--tools ' &&
  [ "$(jq -r .message.content "$tmp/stub.args.stdin")" = '#91' ] && sed -n 3p "$tmp/stub.args" | grep -qe ' #91$' &&
  ! sed -n 3p "$tmp/stub.args" | grep -qe ListAgents && grep -qxF "$(printf 'companion\t#91')" "$tmp/stub.events" &&
  [ -e "$tmp/stub.args.end" ]; } ||
  fail 'conv does not start its other conversation on #91, after the other runs, before a run with ListAgents' "$(cat "$tmp/stub.args")"
# An other conversation that ends with an error gives no companion line, and
# conv is not checked. A run of conv that fails does not stop the eval.
got=$(STUB_COMPANION=error_max_budget_usd stub conv)
{ ! grep -q '^companion' "$tmp/stub.events" && grep -qxF 'conv: not checked, as its check says above' <<<"$got"; } ||
  fail 'an other conversation that ends with an error holds the Given of conv' "$got"
# An other conversation that does not end at the end of its texts is stopped.
SECONDS=0
got=$(STUB_HANG=1 stub conv)
{ [ "$SECONDS" -lt 30 ] && ! pgrep -f 'exec sleep 60|^sleep 60$' >/dev/null; } || fail 'an other conversation that does not end is not stopped' "$got"
got=$(STUB_BREAK=1 stub free conv)
{ grep -q '^pass^1 free: ' <<<"$got" && grep -q '^runs: ' <<<"$got"; } || fail 'a run of conv that fails stops the eval' "$got"
# A case named twice runs once.
got=$(stub free free)
{ [ "$(wc -l <"$tmp/stub.args")" -eq 1 ] && [ "$(grep -c '^pass^1 free:' <<<"$got")" = 1 ]; } || fail 'a case named twice runs twice' "$got"
# A case whose setup fails gets no run: its session would have no fake gh.
mkdir "$tmp/badgit"
# shellcheck disable=SC2016 # the script is data
printf '#!/usr/bin/env bash\n[ "$1" != clone ] || exit 1\nexec %q "$@"\n' "$(command -v git)" >"$tmp/badgit/git"
chmod +x "$tmp/badgit/git"
got=$(PATH="$tmp/badgit:$PATH" stub otherpr 2>/dev/null)
{ [ ! -e "$tmp/stub.args" ] && grep -q '^otherpr: no run' <<<"$got"; } || fail 'a case whose setup fails runs' "$got"
# A round of linkedhere can cost $12, a cap of $4 for each of its three messages.
got=$(stub --max-cost 11 linkedhere)
grep -qxF "stopped before round 1 of 1: \$0.00 spent, and a round can cost \$12.00 more, past the cap of \$11" <<<"$got" ||
  fail 'the cap of a round does not count the three messages of linkedhere' "$got"
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
