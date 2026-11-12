#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
dup_case() { line dup 4 'A free duplicate' '#91'; }
dup_given() { given='.issues += [task(95; $title95; $body95 + "\n\nThen my app failed:\n\n```\n" + $trace + "\n```"; [])]'; }
dup_check() {
  # Each line of the trace, with its indent or without.
  item 'a comment on #91 holds the stack trace of #95' 'jq -e --arg t "$trace" "(.issues[] | select(.number == 91) | .comments)
    | any(.[]; .body as \$b | all(\$t | split(\"\\n\")[] | sub(\"^ +\"; \"\"); . as \$l | \$b | contains(\$l)))" "$d.state.json" >/dev/null'
  item '#95 is closed as a duplicate of #91' '[ "$(issue 95 "[.state, .stateReason, .duplicateOf]")" = "[\"CLOSED\",\"DUPLICATE\",91]" ]'
  item 'the comment on #91 comes before #95 closes' 'at "(at(\"comment 91\") // 1e9) < (at(\"close 95\") // -1)"'
  # The work: a changed file or a commit in the workspace (scenarios/TERMS.md).
  item '#95 closes before the work starts' 'at "(.log // []) | index(\"close 95\") != null"'
  item 'the last message names #95 as closed' 'grep -qiE "clos(ed|ing)([^.]|\.[^ ])*#95|#95([^.]|\.[^ ])*clos(ed|ing)" <<<"$last"'
  item 'never: #91 closes' '[ "$(issue 91 .state)" = OPEN ]'
  outcomes
}
dup_copies() {
  # Only the first line of the stack trace of #95 in the comment on #91, as
  # in the runs before #296.
  copy dup
  state dup '(.issues[] | select(.number == 91) | .comments[].body) =
    "From #95:\n\n```\n" + (.issues[] | select(.number == 95) | .body | split("```")[1] | split("\n")[1]) + "\n```"'
  flips dup 'a comment on #91 holds the stack trace of #95'

  # The stack trace in the comment on #91, its indent lost.
  copy dup
  state dup '(.issues[] | select(.number == 91) | .comments[].body) |= gsub("\n +"; "\n")'
  stays

  # #95 closed, but not as a duplicate.
  copy dup
  state dup '(.issues[] | select(.number == 95)) |= (.stateReason = "COMPLETED" | .duplicateOf = null)'
  flips dup '#95 is closed as a duplicate of #91'

  # #95 closed before the comment on #91.
  copy dup
  state dup '.log = ["close 95"] + (.log - ["close 95"])'
  flips dup 'the comment on #91 comes before #95 closes'

  # #95 closed after the work started: the fake gh marks the close.
  copy dup
  state dup '.log |= map(if . == "close 95" then "close 95 +changes" else . end)'
  flips dup '#95 closes before the work starts'

  # A last message that names #95, and a close of something else in another
  # sentence.
  copy dup
  add dup $'text\t#95 reports the same typo. I closed the worktree.'
  flips dup 'the last message names #95 as closed'

  # #91 closed.
  copy dup
  state dup '(.issues[] | select(.number == 91) | .state) = "CLOSED"'
  flips dup 'never: #91 closes'
}
dup_fails() {
  # The first message about #91 is a narration with no title, before the
  # first change (#317).
  printf '%s\n' 'FAIL the first message about #91 tells its gist' 'FAIL the gist comes before any change'
}
