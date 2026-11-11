#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
also_case() { line also 4 'A task that holds an added finding' '#91'; }
also_task() {
  parsertask
  body=$body'

## Also: `splitLine` drops the last field of a line that ends with a comma

Where: `src/parser/split.ts`, in `splitLine`. How it shows up: `a,b,` gives two fields, not three.'
}
also_given() { parser; }
also_check() {
  outcomes
  item 'the first message about #91 names its added finding' 'grep -qiE "splitLine|last field" <<<"$named"'
  # The fix of the added finding: the work takes out the pop of the empty last field.
  item 'the work on #91 fixes the defect of its added finding' 'grep -qE "^-[[:space:]]*fields\.pop\(\);" "$d.work" && ! grep -qE "^\+[[:space:]]*fields\.pop\(\);" "$d.work"'
  item 'never: a task is created for the added finding of #91' '[ "$(jq ".issues | length" "$d.state.json")" = 1 ]'
}
also_copies() { :; }
