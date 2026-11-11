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
  # A task for another finding, as one of the review, can be filed.
  item 'never: a task is created for the added finding of #91' \
    'jq -e "all(.issues[] | select(.number != 91); (.title + \" \" + .body) | test(\"splitLine\") | not)" "$d.state.json" >/dev/null'
}
also_copies() {
  # The first message with no word of the added finding, the pop of the empty
  # field kept in the work, and a task filed for the added finding.
  copy also
  awk '!done && /^text/ { gsub(/splitLine/, "the splitter"); gsub(/last field/, "end"); done = 1 } 1' "$fixtures/also.events" >"$tmp/$n/also.events"
  flips also 'the first message about #91 names its added finding'
  copy also
  echo '+    fields.pop();' >>"$tmp/$n/also.work"
  flips also 'the work on #91 fixes the defect of its added finding'
  copy also
  state also '.issues += [{number: 94, title: "parser: splitLine drops the last field", body: "", state: "OPEN", assignees: [], labels: [], comments: []}]'
  flips also 'never: a task is created for the added finding of #91'
}
also_fails() {
  # The first message about #91 is a narration with no title, before the first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
