#!/usr/bin/env bash
# Runs the checks of tests/scenarios_eval.sh on recorded runs, with no model.
# tests/fixtures/scenarios/take-in/ holds the events, the tracker, the
# branches and the workspace of one probe run of each case: other and down
# of 2026-11-03, and the other cases of 2026-11-11, which also keep the
# workspace and the branches of their Given. The twenty cases of #320 also
# keep the work on each branch, of the run and of the Given. The runs of
# free, dup, busy, assigned, inprogress, here and there were recorded again on
# 2026-11-11 for the label in progress (#285), and the events of inws again
# from its log (ADR 0008). The run of dup was recorded again on 2026-11-12,
# on the text of #296 that copies a stack trace as it is, and the run of
# dupeof, with its work, on 2026-11-13 (#354). The runs of other
# and down kept no Given: theirs is the one that setup makes now. In the runs
# of a case of more messages, a person line gives each text of the person
# after the first one. A recorded tracker keeps no path of its run: its
# origin is <work>.origin, and its workspace is null.
#
# Each item of a recorded run passes, but those that <case>_fails of its
# case file lists, with why. A copy of the files of one case, with one change,
# changes the verdicts it names and no other; a read added to a run changes
# none. The copies of a case are in its file in tests/scenarios_take_in/. Each
# heading of scenarios/github/take-in.md is a scenario that the checks name or
# that the eval lists as not run, and nothing else is.

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

table=$(bash "$root/tests/scenarios_take_in.sh" cases)
scenario() { awk -F'\t' -v c="$1" '$1 == c { print $3 }' <<<"$table"; }
# of <case>: the item lines of the case, from the report on stdin.
of() { awk -v s="$(scenario "$1"): " 'substr($0, 6, length(s)) == s'; }
for f in "$root"/tests/scenarios_take_in/*.sh; do
  # shellcheck source=/dev/null # one file for each case
  . "$f"
done

kept=$(jq -r 'select(.origin != "<work>.origin" or .workspace != null) | input_filename' "$fixtures"/*.state.json)
[ -z "$kept" ] || fail 'a recorded tracker keeps a path of its run' "$kept"
report=$("$eval" --check "$fixtures")
out=$(grep -E '^(PASS|FAIL|SKIP) ' <<<"$report")
[ "$(grep -c '^pass' <<<"$report")" = "$(grep -c . <<<"$table")" ] || fail 'the recorded runs do not give pass^1 to each case' "$report"
[ "$(grep -c '^PASS ' <<<"$out")" = 242 ] || fail 'the recorded runs do not pass 242 items' "$out"
# shellcheck disable=SC2013 # a case name is one word
for c in $(cut -f1 <<<"$table"); do
  want=$("${c}_fails" | awk -v s="$(scenario "$c")" '{ print substr($0, 1, 5) s ": " substr($0, 6) }')
  [ "$(of "$c" <<<"$out" | grep -v '^PASS ' || true)" = "$want" ] || fail "the recorded run of $c does not fail only the items of ${c}_fails" "$(of "$c" <<<"$out")"
  verdict=PASS
  [ -z "$want" ] || verdict=FAIL
  grep -q "^pass^1 $c: $verdict, " <<<"$report" || fail "the recorded run of $c does not give pass^1 $verdict" "$report"
done

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

# copy <case>: a copy of the files of the case, which the next steps change.
n=0
copy() {
  n=$((n + 1)) case_=$1
  mkdir "$tmp/$n"
  cp "$fixtures/$1".* "$tmp/$n/"
}
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
    was=$(of "$c" <<<"$out" | grep -F ": $item")
    now=$(grep -F ": $item" <<<"$got")
    [ -n "$was" ] && [ "${was%% *}" != "${now%% *}" ] || fail "copy $n does not flip: $item" "$got"
  done
  [ "$(diff <(of "$c" <<<"$out") <(echo "$got") | grep -c '^>')" = $# ] || fail "copy $n flips another item too" "$got"
}
# stays: the copy changes no verdict.
stays() { [ "$(checks "$tmp/$n")" = "$(of "$case_" <<<"$out")" ] || fail "copy $n changes a verdict" "$(checks "$tmp/$n")"; }
# notchecked <case>: the Given of the case does not hold in the copy, and the
# case is not checked.
notchecked() { grep -qxF "$1: not checked, as its check says above" <<<"$("$eval" --check "$tmp/$n" 2>/dev/null)" || fail "copy $n checks $1"; }

# The copies of each case, in its file.
# shellcheck disable=SC2013 # a case name is one word
for c in $(cut -f1 <<<"$table"); do "${c}_copies"; done

echo 'scenarios_checks_test: ok'
