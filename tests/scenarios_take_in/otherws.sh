#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
otherws_case() { line otherws 2 "Another person's task whose linked branch the workspace has" '#91'; }
otherws_given() { inws_given; given='.issues[0] |= (.assignees = [$other] | .linked = ["fix/91-typo"])'; }
otherws_check() {
  first
  item 'the person is told that #91 is assigned to another person' 'told "$other"'
  nochange 'the run waits'
  item 'never: the person is told that the work on #91 continues' '! says "continues on fix/91-typo|work (on #91 )?continues"'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  kept "never: the workspace's fix/91-typo changes"
  item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$other\"]" ]'
}
otherws_copies() { :; }
