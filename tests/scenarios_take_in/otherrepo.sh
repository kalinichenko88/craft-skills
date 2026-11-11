#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
otherrepo_case() { line otherrepo 2 'A task of another repository' 'https://github.com/acme/lib/issues/91'; }
otherrepo_given() { given='.issues[0].repo = "acme/lib"'; }
otherrepo_check() {
  first
  item 'the person is told that #91 is in another repository' 'told acme/lib'
  nochange 'the run stops'
  keeps '[]'
  nobranch '[]'
}
otherrepo_copies() {
  # Told with no name of the other repository, and assigned.
  copy otherrepo
  sed -i.bak '/^text/s#acme/lib#there#g' "$tmp/$n/otherrepo.events"
  flips otherrepo 'the person is told that #91 is in another repository'
  copy otherrepo
  state otherrepo '.issues[0].assignees += ["kim"]'
  flips otherrepo 'never: the assignees of #91 change'
}
otherrepo_fails() { :; }
