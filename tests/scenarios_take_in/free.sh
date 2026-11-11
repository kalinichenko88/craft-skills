#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
free_case() { line free 4 'A free task' '#91'; }
free_given() { :; }
free_check() { outcomes; }
free_copies() {
  # The gist told first, before the branch.
  copy free
  first free $'text\t#91: README: the install command says npm instal. The README has a wrong command.'
  flips free 'the first message about #91 tells its gist' 'the gist comes before any change'

  # A think line before the first message about #91: the log cannot show
  # whether the person read it.
  copy free
  first free $'think\tI read #91.'
  flips free 'the first message about #91 tells its gist'

  # The narration before the branch with no word of the typo: no message about
  # #91 comes before the last one, which tells the gist after the change.
  copy free
  untypo() { awk '!done && /^text/ { gsub(/`npm instal shop`/, "a command"); done = 1 } 1' "$fixtures/free.events"; }
  untypo >"$tmp/$n/free.events"
  flips free 'the first message about #91 tells its gist'

  # Only a think line before the change, as in a log with no narration mark.
  copy free
  { printf 'think\tI read #91.\n'; untypo; } >"$tmp/$n/free.events"
  flips free 'the first message about #91 tells its gist' 'the gist comes before any change'

  # A second linked branch on the free task.
  copy free
  state free '.issues[0].linked += ["fix/91-other"]'
  flips free 'never: #91 gets a second linked branch'

  # No branch linked to the free task.
  copy free
  state free '.issues[0].linked = []'
  flips free 'that branch is made from the default branch' 'that branch is linked to #91'

  # The linked branch of the free task is not made from main.
  copy free
  sed -i.bak 's#^docs/91-fix-install-command$#&, not from main#' "$tmp/$n/free.branches"
  flips free 'that branch is made from the default branch'
}
free_fails() {
  # The first message about #91 is a narration with no title, before the first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
