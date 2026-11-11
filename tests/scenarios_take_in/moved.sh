#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
moved_case() { line moved 2 "The person's branch moved on somewhere else" '#91'; }
moved_given() { inws_given; elsewhere fix/91-typo "$me"; }
moved_check() {
  first
  item 'the person is told that #91 is assigned to the person' 'says "$yours"'
  item 'the person is told that fix/91-typo is linked to #91' 'told fix/91-typo'
  item 'the person is asked whether the work on #91 runs somewhere else or continues here' 'asked "$where"'
  nochange 'the run waits'
  nobranch '["fix/91-typo"]'
  kept "never: the workspace's fix/91-typo changes"
}
moved_copies() {
  # Told with no name of the linked branch.
  copy moved
  sed -i.bak '/^text/s#fix/91-typo#the branch#g' "$tmp/$n/moved.events"
  flips moved 'the person is told that fix/91-typo is linked to #91'
  # The workspace's fix/91-typo pulled.
  copy moved
  sed -i.bak 's/^fix\/91-typo .*/fix\/91-typo 0000000000000000000000000000000000000000/' "$tmp/$n/moved.workspace"
  flips moved "never: the workspace's fix/91-typo changes" 'the run waits: no change'
}
moved_fails() { :; }
