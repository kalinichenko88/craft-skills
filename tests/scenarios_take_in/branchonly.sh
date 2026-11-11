#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
branchonly_case() { line branchonly 4 'A branch only' '#91, a branch only'; }
branchonly_given() { :; }
branchonly_check() {
  outcomes
  item 'the workspace is on the branch that is linked to #91' '[ -n "$branch" ] && grep -qxF "head $branch" "$d.workspace"'
  oneworkspace
}
branchonly_copies() { :; }
