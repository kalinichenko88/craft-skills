#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
inws_case() { line inws 4 "The person's work is in the workspace" '#91'; }
# wsbranch: fix/91-typo in the workspace and on the origin, for the cases
# whose workspace has the linked branch.
wsbranch() { git -C "$w" branch fix/91-typo; git -C "$w" push -q -u origin fix/91-typo; }
inws_given() { wsbranch; given='.issues[0] |= (.assignees = [$me] | .linked = ["fix/91-typo"])'; }
inws_check() {
  first
  continued
  # A commit on fix/91-typo, or a changed file in its worktree.
  item 'the work goes on, on fix/91-typo' '[ -n "$(tip "$d.workspace")" ] && [ "$(tip "$d.workspace")" != "$(tip "$d.given.workspace")" ]'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  onelinked
  keeps '["kim"]'
}
inws_copies() {
  # No commit and no change on fix/91-typo, and a question whether the work
  # runs somewhere else.
  copy inws
  cp "$fixtures/inws.given.workspace" "$tmp/$n/inws.workspace"
  flips inws 'the work goes on, on fix/91-typo'
  copy inws
  add inws $'text\tDoes the work on #91 run somewhere else, or here?'
  flips inws 'never: the person is asked whether the work runs somewhere else'
  copy inws
  sed -i.bak '/^text/s/continu/kept/g' "$tmp/$n/inws.events"
  flips inws 'the person is told in one line that the work on #91 continues on fix/91-typo'
  # A question about something else, after a sentence that names another
  # session.
  copy inws
  add inws $'text\tNo other session works on #91. Shall I open a draft PR?'
  stays
}
inws_fails() {
  # The first message about #91 is a narration with no title (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist'
}
