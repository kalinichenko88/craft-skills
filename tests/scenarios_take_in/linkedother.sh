#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
linkedother_case() { line linkedother 2 "The linked branch is another person's" '#91' "It is another person's."; }
linkedother_given() { linked_given; }
linkedother_check() {
  answered "$whose"
  item "the person is told that the work on #91 is another person's" 'part 2 | grep -qiE "another person|someone else|not yours|their (work|branch)|theirs"'
  nochange 'the run waits'
  item 'never: the person is asked whether the work on #91 runs somewhere else' '! asked "$where"'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  unlabelled
  nobranch '["fix/91-typo"]'
}
linkedother_copies() {
  # No word of whose the work is, a write, a question whether it runs
  # somewhere else, #91 assigned and labelled, a new branch, and no answer.
  copy linkedother
  awk '/^person/ { p++ } p >= 1 && /^text/ { gsub(/another person|someone else|not yours|their|theirs/, "the owner") } 1' "$fixtures/linkedother.events" >"$tmp/$n/linkedother.events"
  flips linkedother "the person is told that the work on #91 is another person's"
  copy linkedother
  add linkedother $'Bash\tgh issue edit 91 --add-assignee @me'
  flips linkedother 'the run waits: no change'
  copy linkedother
  add linkedother $'text\tDoes the work on #91 run somewhere else, or here?'
  flips linkedother 'never: the person is asked whether the work on #91 runs somewhere else'
  copy linkedother
  state linkedother '.issues[0].assignees = ["kim"]'
  flips linkedother 'never: the assignees of #91 change'
  copy linkedother
  state linkedother '.issues[0].labels = ["in progress"]'
  flips linkedother 'never: #91 gets the label in progress'
  copy linkedother
  echo fix/91-new >>"$tmp/$n/linkedother.branches"
  flips linkedother 'never: a branch for #91 is created'
  copy linkedother
  grep -v '^person' "$fixtures/linkedother.events" >"$tmp/$n/linkedother.events"
  notchecked linkedother
}
linkedother_fails() { :; }
