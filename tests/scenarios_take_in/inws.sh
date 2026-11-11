#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
inws_case() { line inws 4 "The person's work is in the workspace" '#91'; }
# The Given of inws and moved: fix/91-typo in the workspace and on the origin.
inws_given() {
  git -C "$w" branch fix/91-typo
  git -C "$w" push -q -u origin fix/91-typo
  given='.issues[0] |= (.assignees = [$me] | .linked = ["fix/91-typo"])'
}
inws_check() {
  first
  # What the message says: the log keeps no line break of a message.
  item 'the person is told in one line that the work on #91 continues on fix/91-typo' \
    'grep "^text" "$d.events" | grep -F fix/91-typo | grep -qi continu'
  # A commit on fix/91-typo, or a changed file in its worktree.
  item 'the work goes on, on fix/91-typo' '[ -n "$(tip "$d.workspace")" ] && [ "$(tip "$d.workspace")" != "$(tip "$d.given.workspace")" ]'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
}
inws_copies() {
  # No commit and no change on fix/91-typo, and a question whether the work
  # runs somewhere else.
  copy
  cp "$fixtures/inws.given.workspace" "$tmp/$n/inws.workspace"
  flips inws 'the work goes on, on fix/91-typo'
  copy
  add inws $'text\tDoes the work on #91 run somewhere else, or here?'
  flips inws 'never: the person is asked whether the work runs somewhere else'
  copy
  sed -i.bak '/^text/s/continu/kept/g' "$tmp/$n/inws.events"
  flips inws 'the person is told in one line that the work on #91 continues on fix/91-typo'
  # A question about something else, after a sentence that names another
  # session.
  copy
  add inws $'text\tNo other session works on #91. Shall I open a draft PR?'
  stays
}
