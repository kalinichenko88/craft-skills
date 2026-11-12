#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
closed_case() { line closed 2 'A closed task' '#91'; }
closed_given() { given='.issues[0] |= (.state = "CLOSED" | .stateReason = "COMPLETED")'; }
closed_check() {
  first
  item 'the person is told that #91 is closed' 'told closed'
  nochange 'the run waits'
  item 'never: the state of #91 changes' '[ "$(issue 91 "[.state, .stateReason]")" = "[\"CLOSED\",\"COMPLETED\"]" ]'
  keeps
  nobranch '[]'
}
closed_copies() {
  # A closed task reopened, and told with no word that it is closed.
  copy closed
  state closed '.issues[0].state = "OPEN"'
  flips closed 'never: the state of #91 changes'
  copy closed
  sed -i.bak '/^text/{s/closed/done/g; s/Closed/Done/g;}' "$tmp/$n/closed.events"
  flips closed 'the person is told that #91 is closed'
}
closed_fails() { :; }
