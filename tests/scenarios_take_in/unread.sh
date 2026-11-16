#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
unread_case() { line unread 2 'The text of the task cannot be read' '#91'; }
unread_given() { given='.unreadable = [91]'; }
unread_check() {
  item 'the person is told that the text of #91 could not be read, with its error' 'told 502'
  nochange 'the run stops'
  item 'never: the person is told a gist of #91 that the run did not read' '[ -z "$titled" ]'
  keeps
  unlabelled
  nobranch '[]'
}
unread_copies() {
  # No error told, a write, and a gist told; and #91 assigned, labelled and
  # linked to a branch.
  copy unread
  sed -i.bak '/^text/s/502/5xx/g' "$tmp/$n/unread.events"
  flips unread 'the person is told that the text of #91 could not be read, with its error'
  copy unread
  first unread $'Bash\tgh issue edit 91 --add-assignee @me'
  flips unread 'the run stops: no change'
  copy unread
  add unread $'text\t#91 README: the install command says npm instal'
  flips unread 'never: the person is told a gist of #91 that the run did not read'
  copy unread
  state unread '.issues[0].assignees = ["kim"]'
  flips unread 'never: the assignees of #91 change'
  copy unread
  state unread '.issues[0].labels = ["in progress"]'
  flips unread 'never: #91 gets the label in progress'
  copy unread
  state unread '.issues[0].linked = ["fix/91-typo"]'
  flips unread 'never: a branch for #91 is created'
}
unread_fails() { :; }
