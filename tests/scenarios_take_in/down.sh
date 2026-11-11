#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
down_case() { line down 2 'The tracker does not answer' '#91'; }
down_given() { given='.down = true'; }
down_check() {
  item 'the person is told the error of the tracker' 'told 502'
  nochange 'the run stops'
  item 'never: a gist of #91 that the run did not read' '[ -z "$titled" ]'
  keeps '[]'
  nobranch '[]'
}
down_copies() {
  # A title that the run could not read, told when the tracker is down.
  copy down
  add down $'text\tREADME: the install command says npm instal'
  flips down 'never: a gist of #91 that the run did not read'

  # No error of the tracker told.
  copy down
  sed -i.bak 's/502/5xx/g' "$tmp/$n/down.events"
  flips down 'the person is told the error of the tracker'
}
down_fails() { :; }
