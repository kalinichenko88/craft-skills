#!/usr/bin/env bash
# Runs the checks of tests/scenarios_eval.sh on recorded runs, with no model.
# tests/fixtures/scenarios/take-in/ holds the events, the tracker, the
# branches and the workspace of one probe run of each case: other and down
# of 2026-11-03, and the other fourteen of 2026-11-11, which also keep the
# workspace and the branches of their Given. The runs of free, dup, busy,
# assigned, inprogress, here and there were recorded again on 2026-11-11 for
# the label in progress (#285).
# In the runs of here and there, a person line gives the answer of the
# person, after the question of the first message.
# The runs of other and down kept none: theirs is the one that setup makes
# now. The events of inws were recorded again from its log (ADR 0008). In the
# runs of free, dup, busy, assigned and inws, the first message about #91 is
# a narration with no title, before the first change, so the gist items
# fail (#317). The
# run of dup carries one line of the stack trace of #95 to #91, not the trace,
# and fails that item. Every other item passes. A copy with one change to a
# recorded run changes the verdicts it names and no other; a read added to a
# run changes none. The copies of a case are in its file in
# tests/scenarios_take_in/. Each heading of
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
[ "$(grep '^pass' <<<"$report" | grep -v ': PASS, 1 of 1 runs pass$')" = 'pass^1 assigned: FAIL, 0 of 1 runs pass
pass^1 busy: FAIL, 0 of 1 runs pass
pass^1 dup: FAIL, 0 of 1 runs pass
pass^1 free: FAIL, 0 of 1 runs pass
pass^1 inws: FAIL, 0 of 1 runs pass' ] &&
  [ "$(grep -c '^pass' <<<"$report")" = 16 ] || fail 'the recorded runs do not give pass^1 to each of the 16 cases but five' "$report"
[ "$(grep -c '^PASS ' <<<"$out")" = 97 ] || fail 'the recorded runs do not pass 97 items' "$out"
[ "$(grep -v '^PASS ' <<<"$out")" = 'FAIL A task assigned to the person, with no branch: the first message about #91 tells its gist
FAIL A busy duplicate: the first message about #91 tells its gist
FAIL A busy duplicate: the gist comes before any change
FAIL A free duplicate: a comment on #91 holds the stack trace of #95
FAIL A free duplicate: the first message about #91 tells its gist
FAIL A free duplicate: the gist comes before any change
FAIL A free task: the first message about #91 tells its gist
FAIL A free task: the gist comes before any change
FAIL The person'"'"'s work is in the workspace: the first message about #91 tells its gist' ] ||
  fail 'the recorded runs do not give only the eight gist FAILs and the FAIL of the trace' "$out"

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
  fail 'a case whose scenario has no heading passes' "$(coverage "$tmp/gone.md")"

n=0
copy() {
  n=$((n + 1))
  cp -R "$fixtures" "$tmp/$n"
}
table=$(bash "$root/tests/scenarios_take_in.sh" cases)
scenario() { awk -F'\t' -v c="$1" '$1 == c { print $3 }' <<<"$table"; }
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
# notchecked <case>: the Given of the case does not hold in the copy, and the
# case is not checked.
notchecked() { grep -qxF "$1: not checked, as its check says above" <<<"$("$eval" --check "$tmp/$n" 2>/dev/null)" || fail "copy $n checks $1"; }

# The copies of each case, in its file.
for f in "$root"/tests/scenarios_take_in/*.sh; do
  # shellcheck source=/dev/null # one file for each case
  . "$f"
done
# shellcheck disable=SC2013 # a case name is one word
for c in $(cut -f1 <<<"$table"); do "${c}_copies"; done

echo 'scenarios_checks_test: ok'
