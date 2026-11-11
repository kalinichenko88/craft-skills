#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
ahead_case() { line ahead 4 "The workspace's branch has a commit that the repository does not have" '#91'; }
# The workspace's fix/91-typo has a commit that the origin does not have.
ahead_given() {
  inws_given
  git -C "$w" switch -q fix/91-typo
  printf '# Changes\n\n- Fix the install command in the README.\n' >"$w/CHANGELOG.md"
  git -C "$w" add CHANGELOG.md
  git -C "$w" commit -qm 'docs: start the fix of the install command'
  git -C "$w" switch -q main
  given='.issues[0] |= (.assignees = [$me] | .labels = ["in progress"] | .linked = ["fix/91-typo"]) | .labels += ["in progress"]'
}
ahead_check() {
  first
  item 'the person is told in one line that the work on #91 continues on fix/91-typo' \
    'grep "^text" "$d.events" | grep -F fix/91-typo | grep -qi continu'
  item 'the work goes on, on fix/91-typo' 'worked fix/91-typo'
  item 'the commit that the repository did not have stays on fix/91-typo' \
    'commits fix/91-typo "$d.work" | grep -qxF "$(tip "$d.given.workspace" | cut -d" " -f2)"'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  nobranch '["fix/91-typo"]'
  item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
}
ahead_copies() { :; }
