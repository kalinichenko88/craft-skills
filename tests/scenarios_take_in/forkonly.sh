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
  keeps "$me"
}
forkonly_copies() {
  # No link told, and a write to #91.
  copy forkonly
  sed -i.bak '/^text/s#https://github.com/lee/shop/tree/fix/91-typo#the fork#g' "$tmp/$n/forkonly.events"
  flips forkonly 'the person is told the link of fix/91-typo'
  copy forkonly
  state forkonly '.log = ["edit 91"]'
  flips forkonly 'the run waits: no change'
}
forkonly_fails() { :; }
