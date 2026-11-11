#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
busy_case() { line busy 4 'A busy duplicate' '#91'; }
busy_given() { given='.issues += [task(95; $title95; $body95; [$other])]'; }
busy_check() {
  item '#95 stays open' '[ "$(issue 95 .state)" = OPEN ]'
  item 'the person is told that #95 stays open because it is busy' 'grep "^text" "$d.events" | grep -F "#95" | grep -qiE "busy|$other"'
  outcomes
  item 'never: #95 closes' 'at "at(\"close 95\") == null"'
  item 'never: the assignees of #95 change' '[ "$(issue 95 .assignees)" = "[\"$other\"]" ]'
}
busy_copies() {
  # #95 closed in the tracker, closed in the log, given a second assignee, and
  # named with no word of why it stays open.
  copy
  state busy '(.issues[] | select(.number == 95) | .state) = "CLOSED"'
  flips busy '#95 stays open'
  copy
  state busy '.log += ["close 95"]'
  flips busy 'never: #95 closes'
  copy
  state busy '(.issues[] | select(.number == 95) | .assignees) += ["kim"]'
  flips busy 'never: the assignees of #95 change'
  copy
  sed -i.bak '/^text.*#95/{s/busy/taken/g; s/rivera/someone/g;}' "$tmp/$n/busy.events"
  flips busy 'the person is told that #95 stays open because it is busy'
}
