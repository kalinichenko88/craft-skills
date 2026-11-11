#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
seen_case() { line seen 4 'A duplicate that tells only what was seen' '#91'; }
seen_task() {
  title='parser: splitLine drops the last field of a line that ends with a comma'
  body='`splitLine` in `src/parser/split.ts` drops the last field of a line that ends with a comma: `a,b,` gives two fields, not three. Done when `splitLine` keeps that empty last field.'
  typo='last field'
}
# #95 tells only the failure: no cause, no file of the code and no function.
seen_given() {
  parser
  extra=(--arg t95 'An imported table has one column less than its file'
    --arg b95 'I imported a CSV file, and the table has one column less than the file has.')
  given='.issues += [task(95; $t95; $b95; [])]'
}
seen_check() {
  local repro close
  # The reproduction: a run of the code, in the worktree of the branch, or
  # after the run moved into it.
  repro=$(awk -F'\t' '$1 ~ /EnterWorktree$/ { in_tree = 1 } $1 ~ /^(sub)?Bash$/ && (in_tree || $2 ~ /\.claude\/worktrees\//) &&
    $2 ~ /(^|[;&|( ])(node|npx|tsx|bun|deno|vitest|jest)( |$)|npm (run )?test/ { print NR; exit }' "$d.events")
  close=$(awk -F'\t' '$1 ~ /^(sub)?Bash$/ && $2 ~ /gh issue close 95/ { print NR; exit }' "$d.events")
  item '#95 is closed as a duplicate of #91' '[ "$(issue 95 "[.state, .stateReason, .duplicateOf]")" = "[\"CLOSED\",\"DUPLICATE\",91]" ]'
  item 'a reproduction of the failure of #95 runs on the branch that is linked to #91' '[ -n "$repro" ]'
  item '#95 closes after that reproduction' '[ -n "$repro" ] && [ -n "$close" ] && [ "$repro" -lt "$close" ]'
  item 'the last message names #95 as closed' 'grep -qiE "clos(ed|ing)([^.]|\.[^ ])*#95|#95([^.]|\.[^ ])*clos(ed|ing)" <<<"$last"'
  outcomes
  item 'never: #91 closes' '[ "$(issue 91 .state)" = OPEN ]'
}
seen_copies() { :; }
