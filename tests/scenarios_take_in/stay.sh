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
stay_copies() {
  # #91 not assigned, the workspace on main, a local branch for #91, a linked
  # branch, and a worktree.
  copy stay
  state stay '.issues[0].assignees = []'
  flips stay '#91 is assigned to the person'
  copy stay
  sed -i.bak 's/^head .*/head main/' "$tmp/$n/stay.workspace"
  flips stay 'the workspace stays on fix/rows'
  copy stay
  { echo 'fix/91-readme 0000000000000000000000000000000000000000'; cat "$fixtures/stay.workspace"; } >"$tmp/$n/stay.workspace"
  flips stay 'never: a branch for #91 is created'
  copy stay
  state stay '.issues[0].linked = ["fix/91-readme"]'
  flips stay 'never: #91 gets a linked branch'
  copy stay
  sed -i.bak 's/^worktrees 1$/worktrees 2/' "$tmp/$n/stay.workspace"
  flips stay 'never: a workspace of #91 is created'
}
stay_fails() {
  # The first message about #91 is a narration with no title, before the first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
