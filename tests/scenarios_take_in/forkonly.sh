#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
forkonly_case() { line forkonly 2 'A linked branch of another repository only' '#91' 'It continues here.'; }
forkonly_given() {
  inprogress_given
  given+=' | .issues[0].linked = [{name: "fix/91-typo", repo: "lee/shop"}]'
}
forkonly_check() {
  answered "$where"
  item 'the person is told the link of fix/91-typo' 'told github.com/lee/shop/tree/fix/91-typo'
  nowrite 'the run waits'
  nobranch '[{"name":"fix/91-typo","repo":"lee/shop"}]'
  onelinked
  keeps '["kim"]'
}
forkonly_copies() {
  # No link told, a write to #91, a second linked branch, another assignee,
  # and no answer of the person.
  copy forkonly
  sed -i.bak '/^text/s#https://github.com/lee/shop/tree/fix/91-typo#the fork#g' "$tmp/$n/forkonly.events"
  flips forkonly 'the person is told the link of fix/91-typo'
  copy forkonly
  state forkonly '.log = ["edit 91"]'
  flips forkonly 'the run waits: no change'
  copy forkonly
  state forkonly '.issues[0].linked += ["fix/91-typo"]'
  flips forkonly 'never: a branch for #91 is created' 'never: #91 gets a second linked branch'
  copy forkonly
  state forkonly '.issues[0].assignees += ["rivera"]'
  flips forkonly 'never: the assignees of #91 change'
  copy forkonly
  grep -v '^person' "$fixtures/forkonly.events" >"$tmp/$n/forkonly.events"
  notchecked forkonly
}
forkonly_fails() { :; }
