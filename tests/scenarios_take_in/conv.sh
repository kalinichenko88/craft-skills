#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
conv_case() { line conv 2 'An earlier run works on the task in another conversation' '#91'; }
# The other conversation: the eval starts it on the text that <dir>.companion
# holds, and the session title names it "#91" and the short title.
conv_given() {
  inws_given
  given='.issues[0] |= (.assignees = [$me] | .labels = ["in progress"] | .linked = ["fix/91-typo"]) | .labels += ["in progress"]'
  echo '#91' >"$w.companion"
}
conv_check() {
  first
  item 'the person is told which other conversation holds the work on #91' 'told "#91 the install command says npm instal"'
  nochange 'the run stops'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  kept "never: the workspace's fix/91-typo changes"
  oneworkspace
}
conv_copies() { :; }
