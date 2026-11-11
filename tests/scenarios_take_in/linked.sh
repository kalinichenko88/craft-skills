#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linked_case() { line linked 2 'A linked branch with no assignee' '#91'; }
linked_given() { git -C "$w.origin" branch fix/91-typo main; given='.issues[0].linked = ["fix/91-typo"]'; }
linked_check() {
  first
  item 'the person is told that fix/91-typo is linked to #91' 'told fix/91-typo'
  item 'the person is asked whose branch fix/91-typo is' 'asked "whose|yours|your (own )?branch|someone else|another person"'
  nochange 'the run waits'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  nobranch '["fix/91-typo"]'
}
linked_copies() {
  # Asked nothing, and a second branch linked.
  copy
  sed -i.bak '/^text/s/?/./g' "$tmp/$n/linked.events"
  flips linked 'the person is asked whose branch fix/91-typo is'
  copy
  state linked '.issues[0].linked += ["fix/91-other"]'
  flips linked 'never: a branch for #91 is created'
  # Told with no name of the linked branch.
  copy
  sed -i.bak '/^text/s#fix/91-typo#the branch#g' "$tmp/$n/linked.events"
  flips linked 'the person is told that fix/91-typo is linked to #91'
}
