#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
ahead_case() { line ahead 4 "The workspace's branch has a commit that the repository does not have" '#91'; }
# The workspace's fix/91-typo has a commit that the origin does not have.
ahead_given() {
  wsbranch
  git -C "$w" switch -q fix/91-typo
  printf '# Changes\n\n- Fix the install command in the README.\n' >"$w/CHANGELOG.md"
  git -C "$w" add CHANGELOG.md
  git -C "$w" commit -qm 'docs: start the fix of the install command'
  git -C "$w" switch -q main
  inprogress_given
  given+=' | .issues[0].linked = ["fix/91-typo"]'
}
ahead_check() {
  first
  continued
  item 'the work goes on, on fix/91-typo' 'worked fix/91-typo'
  item 'the commit that the repository did not have stays on fix/91-typo' \
    'commits fix/91-typo "$d.work" | grep -qxF "$(tip "$d.given.workspace" | cut -d" " -f2)"'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  nobranch '["fix/91-typo"]'
  onelinked
}
ahead_copies() {
  # No new commit, the commit of the workspace gone, a question whether the
  # work runs somewhere else, a new branch, and a second linked branch; and
  # the line that says that the work continues.
  copy ahead
  cp "$fixtures/ahead.given.work" "$tmp/$n/ahead.work"
  flips ahead 'the work goes on, on fix/91-typo'
  copy ahead
  grep -v "^commit $(grep '^fix/91-typo ' "$fixtures/ahead.given.workspace" | cut -d' ' -f2) " "$fixtures/ahead.work" >"$tmp/$n/ahead.work"
  flips ahead 'the commit that the repository did not have stays on fix/91-typo'
  copy ahead
  add ahead $'text\tDoes the work on #91 run somewhere else, or here?'
  flips ahead 'never: the person is asked whether the work runs somewhere else'
  copy ahead
  echo fix/91-new >>"$tmp/$n/ahead.branches"
  flips ahead 'never: a branch for #91 is created'
  copy ahead
  state ahead '.issues[0].linked += ["fix/91-new"]'
  flips ahead 'never: #91 gets a second linked branch' 'never: a branch for #91 is created'
  copy ahead
  add ahead $'text\tThe work on #91 continues on fix/91-typo.'
  flips ahead 'the person is told in one line that the work on #91 continues on fix/91-typo'
}
ahead_fails() {
  # The first message about #91 is a narration with no title (#317), and the
  # line that names fix/91-typo says what the run fixes there, not that the
  # work goes on (#349).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the person is told in one line that the work on #91 continues on fix/91-typo'
}
