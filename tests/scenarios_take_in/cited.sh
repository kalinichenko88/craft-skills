#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
cited_case() { line cited 4 'A task that names a line that moved' '#91'; }
cited_task() {
  parsertask
  body='`parseRows` at `src/parser/read.ts:42` turns an empty line into a row with one empty field, so a text that ends with a line break gets an empty last row. Done when `parseRows` gives no row for an empty line.'
}
cited_given() { parser; }
cited_check() {
  item 'the text of #91 names src/parser/read.ts:57 as the line of parseRows' 'issue 91 .body | grep -qF src/parser/read.ts:57'
  # The rest: the text with the new line number, or a range from it, put back.
  item 'the rest of the text of #91 stays as it was' \
    'issue 91 ".body | gsub(\"read\\\\.ts:57(-[0-9]+)?\"; \"read.ts:42\") | sub(\"\\\\s+$\"; \"\")" | grep -qxF "$body"'
  item 'the text of #91 changes before the work starts' 'at "(.log // []) | index(\"edit 91 body\") != null"'
  outcomes
  item 'never: the text of #91 names src/parser/read.ts:42' '! issue 91 .body | grep -qF read.ts:42'
}
cited_copies() { :; }
