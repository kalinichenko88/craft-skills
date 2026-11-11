#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
myprws_case() { line myprws 4 "The person's pull request is in the workspace" '#91'; }
# The branch of #96 holds a first commit of the work, and the README still
# has the typo.
myprws_given() {
  git -C "$w" switch -qc fix/91-typo
  printf '# Changes\n\n- Fix the install command in the README.\n' >"$w/CHANGELOG.md"
  git -C "$w" add CHANGELOG.md
  git -C "$w" commit -qm 'docs: start the fix of the install command'
  git -C "$w" push -q -u origin fix/91-typo
  git -C "$w" switch -q main
  given='.issues[0] |= (.assignees = [$me] | .labels = ["in progress"]) | .labels += ["in progress"] | .prs = [pr($me; "fix/91-typo")]'
}
myprws_check() {
  first
  item 'the person is told in one line that the work on #91 continues on fix/91-typo' \
    'grep "^text" "$d.events" | grep -F fix/91-typo | grep -qi continu'
  item 'the work goes on, on fix/91-typo' 'worked fix/91-typo'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  # The fake gh opens no pull request, so a try to open one counts.
  item 'never: a pull request other than #96 closes #91' \
    '[ "$(jq -c "[.prs[] | select(any(.closes[]; . == 91)) | .number]" "$d.state.json")" = "[96]" ] && ! grep -qE "^(sub)?Bash.*gh pr create" "$d.events"'
  nobranch '[]'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
}
myprws_copies() { :; }
