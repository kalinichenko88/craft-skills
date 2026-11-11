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
  inprogress_given
  given+=' | .prs = [pr($me; "fix/91-typo")]'
}
myprws_check() {
  first
  continued
  item 'the work goes on, on fix/91-typo' 'worked fix/91-typo'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  # The fake gh opens no pull request, so a try to open one counts.
  item 'never: a pull request other than #96 closes #91' \
    '[ "$(jq -c "[.prs[] | select(any(.closes[]; . == 91)) | .number]" "$d.state.json")" = "[96]" ] && ! grep -qE "^(sub)?Bash.*gh pr create" "$d.events"'
  nobranch '[]'
  keeps '["kim"]'
}
myprws_copies() {
  # No new commit on fix/91-typo, a question whether the work runs somewhere
  # else, a try to open another pull request, a new branch, and another
  # assignee; and the line that says that the work continues.
  copy myprws
  cp "$fixtures/myprws.given.workspace" "$tmp/$n/myprws.workspace"
  cp "$fixtures/myprws.given.work" "$tmp/$n/myprws.work"
  flips myprws 'the work goes on, on fix/91-typo'
  copy myprws
  add myprws $'text\tDoes the work on #91 run somewhere else, or here?'
  flips myprws 'never: the person is asked whether the work runs somewhere else'
  copy myprws
  add myprws $'Bash\tgh pr create --title "docs: fix the install command" --body "Closes #91"'
  flips myprws 'never: a pull request other than #96 closes #91'
  copy myprws
  echo fix/91-new >>"$tmp/$n/myprws.branches"
  flips myprws 'never: a branch for #91 is created'
  copy myprws
  state myprws '.issues[0].assignees += ["rivera"]'
  flips myprws 'never: the assignees of #91 change'
  copy myprws
  add myprws $'text\tThe work on #91 continues on fix/91-typo.'
  flips myprws 'the person is told in one line that the work on #91 continues on fix/91-typo'
}
myprws_fails() {
  # The first message about #91 is a narration with no title (#317), and the
  # line that names fix/91-typo says what the run fixes there, not that the
  # work goes on (#349).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the person is told in one line that the work on #91 continues on fix/91-typo'
}
