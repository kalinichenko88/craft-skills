#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
there_case() { line there 2 "The work on the person's task runs somewhere else" '#91' 'It runs somewhere else.'; }
there_given() { inprogress_given; }
there_check() {
  answered "$where"
  nochange 'the run stops'
  nobranch '[]'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
}
there_copies() {
  # #91 left with no assignee.
  copy there
  state there '.issues[0].assignees = []'
  flips there 'never: the assignees of #91 change'
  # The answer comes before the question: the Given does not hold, and the
  # case is not checked.
  copy there
  { grep '^person' "$fixtures/there.events"; grep -v '^person' "$fixtures/there.events"; } >"$tmp/$n/there.events"
  notchecked there
  # A write before the answer: the Given holds, and the run did not stop with
  # no change.
  copy there
  awk '/^person/ { print "Bash\tgh issue edit 91 --add-assignee @me" } 1' "$fixtures/there.events" >"$tmp/$n/there.events"
  flips there 'the run stops: no change'
}
there_fails() { :; }
