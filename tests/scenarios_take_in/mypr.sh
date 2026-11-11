#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
mypr_case() { line mypr 2 "A task with the person's pull request" '#91'; }
mypr_given() { elsewhere fix/91-install "$me"; given='.prs = [pr($me)]'; }
mypr_check() {
  first
  item 'the person is told that the work on #91 has pull request #96' 'told "#96"'
  nochange 'the run stops'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  nobranch '[]'
}
mypr_copies() {
  # A new branch on the origin.
  copy mypr
  echo fix/91-new >>"$tmp/$n/mypr.branches"
  flips mypr 'never: a branch for #91 is created'

  # Told with no number of the pull request.
  copy mypr
  sed -i.bak '/^text/s/#96/the pull request/g' "$tmp/$n/mypr.events"
  flips mypr 'the person is told that the work on #91 has pull request #96'
}
mypr_fails() { :; }
