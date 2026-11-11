#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linkedhere_case() { line linkedhere 4 'The work on the linked branch continues here' '#91' 'It is mine.' 'It continues here.'; }
linkedhere_given() { linked_given; }
linkedhere_check() {
  answered "$whose" "$where"
  item '#91 is assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
  labelled
  item 'the work goes on, on fix/91-typo' 'worked fix/91-typo'
  nobranch '["fix/91-typo"]'
  item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
}
linkedhere_copies() { :; }
