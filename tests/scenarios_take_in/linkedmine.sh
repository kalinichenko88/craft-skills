#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linkedmine_case() { line linkedmine 2 "The linked branch is the person's" '#91' 'It is mine.'; }
linkedmine_given() { linked_given; }
linkedmine_check() {
  answered "$whose"
  item 'the person is asked whether the work on #91 runs somewhere else or continues here' 'part 2 | grep -qiE "($where)[^.?!]*\?"'
  nochange 'the run waits'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  unlabelled
  nobranch '["fix/91-typo"]'
}
linkedmine_copies() {
  # No question after the answer, a write, #91 assigned and labelled, and a
  # new branch.
  copy linkedmine
  awk '/^person/ { p++ } p >= 1 && /^text/ { gsub(/\?/, ".") } 1' "$fixtures/linkedmine.events" >"$tmp/$n/linkedmine.events"
  flips linkedmine 'the person is asked whether the work on #91 runs somewhere else or continues here'
  copy linkedmine
  add linkedmine $'Bash\tgh issue edit 91 --add-assignee @me'
  flips linkedmine 'the run waits: no change'
  copy linkedmine
  state linkedmine '.issues[0].assignees = ["kim"]'
  flips linkedmine 'never: the assignees of #91 change'
  copy linkedmine
  state linkedmine '.issues[0].labels = ["in progress"]'
  flips linkedmine 'never: #91 gets the label in progress'
  copy linkedmine
  echo fix/91-new >>"$tmp/$n/linkedmine.branches"
  flips linkedmine 'never: a branch for #91 is created'
}
linkedmine_fails() { :; }
