#!/usr/bin/env bash
# Runs the review-loop skill's report-check.sh on reports that the test
# writes: a whole report passes with its count of findings, and a report that
# the reader cut, or that read nothing, is a failed read.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/review-loop/scripts/report-check.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
# report <name> <exit> <stdout> <line>...: the script on a report of these lines.
report() {
  local name=$1 want_code=$2 want=$3 code=0 got
  shift 3
  if [ $# -gt 0 ]; then printf '%s\n' "$@" >"$tmp/report"; else : >"$tmp/report"; fi
  got=$(bash "$script" "$tmp/report" 2>&1) || code=$?
  [ "$code" = "$want_code" ] && [ "$got" = "$want" ] ||
    fail "$name" "$(printf 'want: exit %s, %s\ngot:  exit %s, %s' "$want_code" "$want" "$code" "$got")"
}

one='a.sh:2 | the check of the build is gone | a file in src/ that imports from tests/'
two='lib/b.py:14 | the retry adds the row twice | a second run after a failed comment'

report 'two finding lines and their count pass' 0 'ok: 2 findings' "$one" "$two" 'count: 2'
report 'blank lines after the count line change nothing' 0 'ok: 2 findings' "$one" "$two" 'count: 2' '' ''
report 'a report with no finding passes' 0 'ok: 0 findings' 'count: 0'
report 'a count that is not the number of finding lines is a failed read' 1 \
  'failed read: count says 3, the report has 2 finding lines' "$one" "$two" 'count: 3'
report 'a report with no count line is a failed read' 1 'failed read: no count line' "$one" "$two"
report 'a report that goes on after its count line has no count line' 1 'failed read: no count line' \
  "$one" 'count: 1' 'I also looked at the tests.'
report 'an empty report is a failed read' 1 'failed read: no count line'
report 'a reader that read no file of the range is a failed read' 1 'failed read: read: none' \
  'read: none | the range is empty' 'count: 0'
report 'a claim with a shell pipe in it is one finding' 0 'ok: 1 findings' \
  'a.sh:2 | cat x | wc -l gives 0 | an empty file' 'count: 1'
report 'a list marker before a finding is allowed' 0 'ok: 1 findings' '- a.sh:2 | claim | failure' 'count: 1'
report 'a finding whose first field is a kind has its place in the second field' 0 'ok: 2 findings' \
  'Outside | lib/y.sh:9 | claim | failure' 'Inject | src/r.js:14 | claim | evidence' 'count: 2'
report 'a line with one separator is no finding' 0 'ok: 0 findings' 'invariants.sh | did not run' 'count: 0'

code=0
bash "$script" >"$tmp/out" 2>"$tmp/err" || code=$?
[ "$code" = 2 ] || fail 'no argument is a usage error' "exit $code"
grep -qxF 'usage: report-check.sh <report file>' "$tmp/err" ||
  fail 'the usage error prints the usage line' "$(cat "$tmp/err")"
code=0
bash "$script" "$tmp/nosuch" >"$tmp/out" 2>"$tmp/err" || code=$?
[ "$code" = 2 ] || fail 'a file that does not exist is a wrong call' "exit $code"

echo 'review_loop_report_test: ok'
