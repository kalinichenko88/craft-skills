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
unread_copies() { :; }
