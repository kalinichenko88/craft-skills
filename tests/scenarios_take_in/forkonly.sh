#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
forkonly_case() { line forkonly 2 'A linked branch of another repository only' '#91' 'It continues here.'; }
forkonly_given() {
  given='.issues[0] |= (.assignees = [$me] | .labels = ["in progress"] | .linked = [{name: "fix/91-typo", repo: "lee/shop"}]) | .labels += ["in progress"]'
}
forkonly_check() {
  answered "$where"
  item 'the person is told the link of fix/91-typo' 'told github.com/lee/shop/tree/fix/91-typo'
  nowrite 'the run waits'
  nobranch '[{"name":"fix/91-typo","repo":"lee/shop"}]'
  item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
}
forkonly_copies() { :; }
