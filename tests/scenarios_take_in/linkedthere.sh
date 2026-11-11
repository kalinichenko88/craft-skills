#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linkedthere_case() { line linkedthere 2 'The work on the linked branch runs somewhere else' '#91' 'It is mine.' 'It runs somewhere else.'; }
linkedthere_given() { linked_given; }
linkedthere_check() {
  answered "$whose" "$where"
  nochange 'the run stops'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  unlabelled
  item 'never: the workspace gets fix/91-typo' '[ -z "$(tip "$d.workspace")" ]'
}
linkedthere_copies() { :; }
