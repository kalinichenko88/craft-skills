#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
unread_case() { line unread 4 'The text of the task cannot be read' '#91'; }
unread_given() { given='.unreadable = [91]'; }
unread_check() {
  item 'the person is told that the text of #91 could not be read, with its error' 'told 502'
  item 'that message comes before any change' 'before "$(grep -n "^text" "$d.events" | grep -F 502 | head -n 1 | cut -d: -f1)"'
  item '#91 is assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
  labelled
  item 'a branch for #91 is made from the default branch' '[ -n "$branch" ] && grep -qxF "$branch" "$d.branches"'
  item 'that branch is linked to #91' '[ -n "$branch" ] && cut -d, -f1 "$d.branches" | grep -qxF "$branch"'
  item 'never: the person is told a gist of #91 that the run did not read' '[ -z "$titled" ]'
}
unread_copies() {
  # No error told, a write before it, and a gist told; and #91 assigned.
  copy unread
  sed -i.bak '/^text/s/502/5xx/g' "$tmp/$n/unread.events"
  flips unread 'the person is told that the text of #91 could not be read, with its error' 'that message comes before any change'
  copy unread
  first unread $'Bash\tgh issue edit 91 --add-assignee @me'
  flips unread 'that message comes before any change'
  copy unread
  add unread $'text\t#91 README: the install command says npm instal'
  flips unread 'never: the person is told a gist of #91 that the run did not read'
  copy unread
  state unread '.issues[0].assignees = ["kim"]'
  flips unread '#91 is assigned to the person'
}
unread_fails() {
  # The run stops after it tells the error of the read (#348).
  printf '%s\n' 'FAIL #91 is assigned to the person' 'FAIL #91 has the label in progress' \
    'FAIL a branch for #91 is made from the default branch' 'FAIL that branch is linked to #91'
}
