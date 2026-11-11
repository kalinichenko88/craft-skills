#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
stay_case() { line stay 4 'Stay on the branch of the workspace' '#91, stay on this branch'; }
stay_given() { git -C "$w" switch -qc fix/rows; git -C "$w" push -q -u origin fix/rows; }
stay_check() {
  local locals='awk "length(\$2) == 40 || \$0 == \"main\" { print \$1 }"'
  first
  gisted
  item '#91 is assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
  labelled
  item 'the workspace stays on fix/rows' 'grep -qx "head fix/rows" "$d.workspace"'
  # No branch on the origin, and no local one.
  item 'never: a branch for #91 is created' 'cmp -s "$d.given.branches" "$d.branches" && [ "$(eval "$locals" <"$d.workspace")" = "$(eval "$locals" <"$d.given.workspace")" ]'
  item 'never: #91 gets a linked branch' '[ "$linked" = "[]" ]'
  oneworkspace
}
stay_copies() { :; }
