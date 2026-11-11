#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
assigned_case() { line assigned 4 'A task assigned to the person, with no branch' '#91'; }
assigned_given() { given='.issues[0].assignees = [$me]'; }
assigned_check() {
  first
  item '#91 stays assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
  labelled
  branched
  item 'never: the person is asked whether the work on #91 runs somewhere else' '! asked "$where"'
}
assigned_copies() {
  # The person's task with no work on it: no label, and a question whether the
  # work runs somewhere else.
  copy assigned
  state assigned '.issues[0].labels = []'
  flips assigned '#91 has the label in progress'
  copy assigned
  add assigned $'text\tDoes the work on #91 run somewhere else, or here?'
  flips assigned 'never: the person is asked whether the work on #91 runs somewhere else'
}
assigned_fails() {
  # The first message about #91 is a narration with no title (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist'
}
