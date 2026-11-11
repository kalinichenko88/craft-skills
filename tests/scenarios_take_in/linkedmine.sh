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
linkedmine_copies() { :; }
