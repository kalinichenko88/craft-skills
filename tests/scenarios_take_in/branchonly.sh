#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
branchonly_case() { line branchonly 4 'A branch only' '#91, a branch only'; }
branchonly_given() { :; }
branchonly_check() {
  outcomes
  item 'the workspace is on the branch that is linked to #91' '[ -n "$branch" ] && grep -qxF "head $branch" "$d.workspace"'
  oneworkspace
}
branchonly_copies() {
  # The workspace back on main, and a worktree made for #91.
  copy branchonly
  sed -i.bak 's/^head .*/head main/' "$tmp/$n/branchonly.workspace"
  flips branchonly 'the workspace is on the branch that is linked to #91'
  copy branchonly
  sed -i.bak 's/^worktrees 1$/worktrees 2/' "$tmp/$n/branchonly.workspace"
  flips branchonly 'never: a workspace of #91 is created'
}
branchonly_fails() {
  # The first message about #91 is a narration with no title, before the first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
