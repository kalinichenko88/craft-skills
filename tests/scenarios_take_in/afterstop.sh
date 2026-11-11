#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
afterstop_case() { line afterstop 2 'A text after a stop that names the task again' '#91' 'It runs somewhere else.' '#91'; }
afterstop_given() { inprogress_given; }
# The outcomes of A task in progress, on the part of the run after the second
# text of the person.
afterstop_check() {
  local t f
  [ "$(grep -c '^person' "$d.events")" -ge 2 ] ||
    { echo "$0: $d has no second text of the person: the Given of its scenario does not hold" >&2; return 2; }
  answered "$where"
  waited
  t=$(mktemp -d)
  for f in state.json branches workspace work given.workspace given.branches given.work; do [ ! -f "$d.$f" ] || cp "$d.$f" "$t/run.$f"; done
  awk '/^person/ { p++; next } p >= 2' "$d.events" >"$t/run.events"
  d=$t/run
  read_run
  inprogress_check
  rm -rf "$t"
}
afterstop_copies() {
  # After the second text: no title, no word of the label, no question, a
  # write, a new branch and another assignee; and no second text.
  copy afterstop
  awk '/^person/ { p++ } p >= 2 && /^text/ { gsub(/README: the install command says npm instal/, "the README task") } 1' "$fixtures/afterstop.events" >"$tmp/$n/afterstop.events"
  flips afterstop 'the first message about #91 tells its gist'
  copy afterstop
  awk '/^person/ { p++ } p >= 2 && /^text/ { gsub(/in[ -]progress/, "started") } 1' "$fixtures/afterstop.events" >"$tmp/$n/afterstop.events"
  flips afterstop 'the person is told that #91 is in progress already'
  copy afterstop
  awk '/^person/ { p++ } p >= 2 && /^text/ { gsub(/\?/, ".") } 1' "$fixtures/afterstop.events" >"$tmp/$n/afterstop.events"
  flips afterstop 'the person is asked whether the work on #91 runs somewhere else or continues here'
  copy afterstop
  add afterstop $'Bash\tgh issue edit 91 --add-assignee @me'
  flips afterstop 'the run waits: no change'
  copy afterstop
  echo fix/91-new >>"$tmp/$n/afterstop.branches"
  flips afterstop 'never: a branch for #91 is created'
  copy afterstop
  state afterstop '.issues[0].assignees += ["rivera"]'
  flips afterstop 'never: the assignees of #91 change'
  copy afterstop
  awk '/^person/ && ++p == 2 { next } 1' "$fixtures/afterstop.events" >"$tmp/$n/afterstop.events"
  notchecked afterstop
  # A write before the second text: the run did not stop, and the Given does
  # not hold.
  copy afterstop
  awk '/^person/ && ++p == 2 { print "Bash\tgh issue comment 91 --body x" } 1' "$fixtures/afterstop.events" >"$tmp/$n/afterstop.events"
  notchecked afterstop
}
afterstop_fails() { :; }
