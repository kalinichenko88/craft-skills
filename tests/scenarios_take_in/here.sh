#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
here_case() { line here 4 "The work on the person's task continues here" '#91' 'It continues here.'; }
here_given() { inprogress_given; }
here_check() {
  answered "$where"
  item '#91 stays assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
  branched
}
here_copies() {
  # #91 given another assignee.
  copy here
  state here '.issues[0].assignees += ["rivera"]'
  flips here '#91 stays assigned to the person'
  # The person gives no answer: the Given does not hold, and the case is not
  # checked.
  copy here
  grep -v '^person' "$fixtures/here.events" >"$tmp/$n/here.events"
  notchecked here
  # A change before the answer: the run did not wait, and the Given does not
  # hold.
  copy here
  awk '/^person/ { print "Edit\t<work>/README.md" } 1' "$fixtures/here.events" >"$tmp/$n/here.events"
  notchecked here
}
here_fails() { :; }
