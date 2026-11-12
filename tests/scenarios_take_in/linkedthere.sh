#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linkedthere_case() { line linkedthere 2 'The work on the linked branch runs somewhere else' '#91' 'It is mine.' 'It runs somewhere else.'; }
linkedthere_given() { linked_given; }
linkedthere_check() {
  answered "$whose" "$where"
  nochange 'the run stops'
  keeps
  unlabelled
  item 'never: the workspace gets fix/91-typo' '[ -z "$(tip "$d.workspace")" ]'
}
linkedthere_copies() {
  # A write, #91 assigned and labelled, and fix/91-typo in the workspace.
  copy linkedthere
  add linkedthere $'Bash\tgh issue edit 91 --add-assignee @me'
  flips linkedthere 'the run stops: no change'
  copy linkedthere
  state linkedthere '.issues[0].assignees = ["kim"]'
  flips linkedthere 'never: the assignees of #91 change'
  copy linkedthere
  state linkedthere '.issues[0].labels = ["in progress"]'
  flips linkedthere 'never: #91 gets the label in progress'
  copy linkedthere
  { echo 'fix/91-typo 0000000000000000000000000000000000000000'; cat "$fixtures/linkedthere.workspace"; } >"$tmp/$n/linkedthere.workspace"
  flips linkedthere 'never: the workspace gets fix/91-typo' 'the run stops: no change'
}
linkedthere_fails() { :; }
