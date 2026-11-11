#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
otherpr_case() { line otherpr 2 "A task with another person's pull request" '#91'; }
otherpr_given() { elsewhere fix/91-install "$other"; given='.prs = [pr($other)]'; }
otherpr_check() {
  first
  item 'the person is told that #96 of another person closes #91' 'grep "^text" "$d.events" | grep -F "#96" | grep -qiF "$other"'
  nochange 'the run waits'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  nobranch '[]'
}
otherpr_copies() {
  # #96 named with no word of whose it is.
  copy otherpr
  sed -i.bak '/^text/s/rivera/someone/g' "$tmp/$n/otherpr.events"
  flips otherpr 'the person is told that #96 of another person closes #91'
}
otherpr_fails() { :; }
