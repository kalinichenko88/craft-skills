#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
closeddup_case() { line closeddup 2 'A closed task with a free duplicate' '#91'; }
closeddup_given() { given='.issues[0] |= (.state = "CLOSED" | .stateReason = "COMPLETED") | .issues += [task(95; $title95; $body95; [])]'; }
closeddup_check() {
  first
  item 'the person is told that #91 is closed' 'told closed'
  nochange 'the run waits'
  item 'never: #95 closes' '[ "$(issue 95 .state)" = OPEN ] && at "at(\"close 95\") == null"'
  item 'never: a comment is added to #91' '[ "$(issue 91 ".comments | length")" = 0 ]'
  item 'never: the state of #91 changes' '[ "$(issue 91 "[.state, .stateReason]")" = "[\"CLOSED\",\"COMPLETED\"]" ]'
  nobranch '[]'
}
closeddup_copies() {
  # Told with no word that #91 is closed, a write, #95 closed, a comment on
  # #91, #91 reopened, and a new branch.
  copy closeddup
  sed -i.bak '/^text/{s/closed/done/g; s/Closed/Done/g;}' "$tmp/$n/closeddup.events"
  flips closeddup 'the person is told that #91 is closed'
  copy closeddup
  add closeddup $'Bash\tgh issue comment 91 --body x'
  flips closeddup 'the run waits: no change'
  copy closeddup
  state closeddup '(.issues[] | select(.number == 95) | .state) = "CLOSED"'
  flips closeddup 'never: #95 closes'
  copy closeddup
  state closeddup '.issues[0].comments += [{author: "kim", body: "Same as #95."}]'
  flips closeddup 'never: a comment is added to #91'
  copy closeddup
  state closeddup '.issues[0].state = "OPEN"'
  flips closeddup 'never: the state of #91 changes'
  copy closeddup
  echo fix/91-new >>"$tmp/$n/closeddup.branches"
  flips closeddup 'never: a branch for #91 is created'
}
closeddup_fails() { :; }
