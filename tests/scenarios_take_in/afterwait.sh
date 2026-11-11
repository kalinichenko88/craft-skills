#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
afterwait_case() { line afterwait 4 'A text after a wait that names no task' '#91' 'It is mine now, take it'; }
afterwait_given() { other_given; }
afterwait_check() {
  { grep -q '^person' "$d.events" && part 1 | grep -qiF "$other"; } ||
    { echo "$0: $d has no answer of the person after a message that #91 is assigned to $other: the Given of its scenario does not hold" >&2; return 2; }
  item '#91 is assigned to the person' 'jq -e --arg me "$me" "index(\$me) != null" <<<"$assignees" >/dev/null'
  labelled
  branched
  item 'never: the person is asked whose the work on #91 is' '! part 2 | grep -qiE "($whose)[^.?!]*\?"'
}
afterwait_copies() { :; }
