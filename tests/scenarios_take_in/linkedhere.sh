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
linkedhere_copies() {
  # #91 not assigned, without the label, no work on fix/91-typo, a new branch,
  # a second linked branch, and no second answer.
  copy linkedhere
  state linkedhere '.issues[0].assignees = []'
  flips linkedhere '#91 is assigned to the person'
  copy linkedhere
  state linkedhere '.issues[0].labels = []'
  flips linkedhere '#91 has the label in progress'
  copy linkedhere
  cp "$fixtures/linkedhere.given.workspace" "$tmp/$n/linkedhere.workspace"
  cp "$fixtures/linkedhere.given.work" "$tmp/$n/linkedhere.work"
  flips linkedhere 'the work goes on, on fix/91-typo'
  copy linkedhere
  echo fix/91-new >>"$tmp/$n/linkedhere.branches"
  flips linkedhere 'never: a branch for #91 is created'
  copy linkedhere
  state linkedhere '.issues[0].linked += ["fix/91-new"]'
  flips linkedhere 'never: #91 gets a second linked branch' 'never: a branch for #91 is created'
  copy linkedhere
  awk '/^person/ && ++p == 2 { next } 1' "$fixtures/linkedhere.events" >"$tmp/$n/linkedhere.events"
  notchecked linkedhere
}
linkedhere_fails() { :; }
