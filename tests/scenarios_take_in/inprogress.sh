#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
inprogress_case() { line inprogress 2 'A task in progress for the person, with no branch' '#91'; }
# The Given of inprogress, and with more of the cases whose task is in progress
# for the person.
inprogress_given() { given='.issues[0] |= (.assignees = [$me] | .labels = ["in progress"]) | .labels += ["in progress"]'; }
inprogress_check() {
  first
  item 'the person is told that #91 is in progress already' 'says "in[ -]progress"'
  item 'the person is asked whether the work on #91 runs somewhere else or continues here' 'asked "$where"'
  nochange 'the run waits'
  nobranch '[]'
  keeps '["kim"]'
}
inprogress_copies() {
  # The person's task in progress: told with no word of it, and asked nothing.
  copy inprogress
  sed -i.bak '/^text/s/in[ -]progress/started/g' "$tmp/$n/inprogress.events"
  flips inprogress 'the person is told that #91 is in progress already'
  copy inprogress
  sed -i.bak '/^text/s/?/./g' "$tmp/$n/inprogress.events"
  flips inprogress 'the person is asked whether the work on #91 runs somewhere else or continues here'
}
inprogress_fails() { :; }
