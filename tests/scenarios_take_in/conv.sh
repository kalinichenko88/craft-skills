#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
conv_case() { line conv 2 'An earlier run works on the task in another conversation' '#91'; }
# The other conversation: the eval starts it on the text that <dir>.companion
# holds, and the session title names it "#91" and the short title.
conv_given() {
  wsbranch
  inprogress_given
  given+=' | .issues[0].linked = ["fix/91-typo"]'
  echo '#91' >"$w.companion"
}
conv_check() {
  grep -q '^companion' "$d.events" ||
    { echo "$0: $d has no other conversation that gave a result: the Given of its scenario does not hold" >&2; return 2; }
  first
  item 'the person is told which other conversation holds the work on #91' 'told "#91 the install command says npm instal"'
  nochange 'the run stops'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  kept "never: the workspace's fix/91-typo changes"
  oneworkspace
}
conv_copies() {
  # No name of the other conversation, and a question whether the work runs
  # somewhere else.
  copy conv
  sed -i.bak '/^text/s/#91 the install command says npm instal/#91 another one/g' "$tmp/$n/conv.events"
  flips conv 'the person is told which other conversation holds the work on #91'
  copy conv
  add conv $'text\tDoes the work on #91 run somewhere else, or here?'
  flips conv 'never: the person is asked whether the work runs somewhere else'
  # The other conversation gave no result: the Given does not hold.
  copy conv
  grep -v '^companion' "$fixtures/conv.events" >"$tmp/$n/conv.events"
  notchecked conv
}
conv_fails() {
  # The first message about #91 is a narration with no title (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist'
}
