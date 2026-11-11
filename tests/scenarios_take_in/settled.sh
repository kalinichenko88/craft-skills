#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
settled_case() { line settled 4 'A settled bug on the code of the task' '#91'; }
settled_task() { parsertask; }
settled_given() {
  parser
  extra=(--arg t12 'parser: parseRows reads a tab as a field separator'
    --arg b12 '`parseRows` in `src/parser/read.ts` splits a line at a tab too, so a field that holds a tab becomes two fields. `parseRows` must split a line only at commas.')
  given='.issues += [task(12; $t12; $b12; []) | .labels = ["bug"]]'
}
settled_check() {
  outcomes
  item '#12 is assigned to the person' '[ "$(issue 12 .assignees)" = "[\"$me\"]" ]'
  item '#12 has the label in progress' '[ "$(issue 12 "any(.labels[]; ascii_downcase == \"in progress\")")" = true ]'
  # The work: a changed file or a commit in the workspace (scenarios/TERMS.md).
  item '#12 is assigned to the person before the work starts' 'at "(.log // []) | index(\"edit 12\") != null"'
  # The fix of #12: no line of src/parser/read.ts splits at a tab in the work.
  item 'the work on #91 fixes the defect of #12' 'grep -q "^-.*split(/\[,\\\\t\]/)" "$d.work" && ! grep -qE "^\+.*split\(.*\\\\t" "$d.work"'
  item 'never: #12 closes' '[ "$(issue 12 .state)" = OPEN ]'
}
settled_copies() { :; }
