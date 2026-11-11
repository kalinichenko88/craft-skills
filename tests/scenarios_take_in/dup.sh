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
  # The stack trace of #95 in a comment on #91, its indent lost.
  copy
  state dup '(.issues[] | select(.number == 91) | .comments) +=
    [{author: "kim", body: (.issues[] | select(.number == 95) | .body | split("```")[1] | gsub("\n +"; "\n"))}]'
  flips dup 'a comment on #91 holds the stack trace of #95'

  # #95 closed, but not as a duplicate.
  copy
  state dup '(.issues[] | select(.number == 95)) |= (.stateReason = "COMPLETED" | .duplicateOf = null)'
  flips dup '#95 is closed as a duplicate of #91'

  # #95 closed before the comment on #91.
  copy
  state dup '.log = ["close 95"] + (.log - ["close 95"])'
  flips dup 'the comment on #91 comes before #95 closes'

  # #95 closed after the work started: the fake gh marks the close.
  copy
  state dup '.log |= map(if . == "close 95" then "close 95 +changes" else . end)'
  flips dup '#95 closes before the work starts'

  # A last message that names #95, and a close of something else in another
  # sentence.
  copy
  add dup $'text\t#95 reports the same typo. I closed the worktree.'
  flips dup 'the last message names #95 as closed'

  # #91 closed.
  copy
  state dup '(.issues[] | select(.number == 91) | .state) = "CLOSED"'
  flips dup 'never: #91 closes'
}
