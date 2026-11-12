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
cited_copies() {
  # The line of parseRows gone from the text of #91, a sentence added to it,
  # the text changed after the work started, and the old line put back.
  copy cited
  state cited '.issues[0].body |= sub("read\\.ts:57"; "read.ts")'
  flips cited 'the text of #91 names src/parser/read.ts:57 as the line of parseRows' 'the rest of the text of #91 stays as it was'
  copy cited
  state cited '.issues[0].body += " See also the README."'
  flips cited 'the rest of the text of #91 stays as it was'
  copy cited
  state cited '.log |= map(if . == "edit 91 body" then "edit 91 body +changes" else . end)'
  flips cited 'the text of #91 changes before the work starts'
  copy cited
  state cited '.issues[0].body += " It was src/parser/read.ts:42."'
  flips cited 'never: the text of #91 names src/parser/read.ts:42' 'the rest of the text of #91 stays as it was'
}
cited_fails() {
  # The first message about #91 is a narration with no title, before the first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
