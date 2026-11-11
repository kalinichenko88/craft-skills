#!/usr/bin/env bash
# Probes a conformance run of craft against scenarios/github/take-in.md, for
# #231. Each case builds a tracker as JSON and a workspace with a bare origin,
# puts a gh first on PATH that runs tests/fake_gh.sh over that JSON, and runs one
# session of `claude -p` on the person's message, on the model of --model,
# opus by default. In a case of two messages, the person's answer to the
# question of the first one resumes that session, with --resume and the same
# plugin and PATH. Then it checks the Then and Never items of the case's
# scenario against the end state of the JSON, the branches of the origin, and
# the session's messages and tool calls. tests/scenarios_take_in.sh holds the
# cases, their Given and their checks:
#
#   free       A free task
#   other      A task that another person is assigned to
#   down       The tracker does not answer
#   dup        A free duplicate
#   busy       A busy duplicate
#   closed     A closed task
#   otherpr    A task with another person's pull request
#   mypr       A task with the person's pull request
#   assigned   A task assigned to the person, with no branch
#   here       The work on the person's task continues here, an answer
#   there      The work on the person's task runs somewhere else, an answer
#   linked     A linked branch with no assignee
#   inws       The person's work is in the workspace
#   moved      The person's branch moved on somewhere else
#   otherrepo  A task of another repository
#
# The session loads this checkout as the plugin, with --setting-sources
# project, so no other plugin and no setting of this machine reaches it. It
# runs with no ListAgents: that tool lists every session of this machine, so
# the runs of a round see each other as open sessions on #91, and the log
# would hold the names of the person's other sessions.
#
# With --runs k, each case runs k times, one round of the cases after
# another. As tau-bench scores an agent, a case passes pass^k only when each
# of its k runs passes it. A run passes a case when no item of the case gives
# FAIL: a SKIP gives no verdict. With fewer than k runs and no failed one, the
# case is not measured.
#
# Each run costs tokens, so the eval is not part of `make check`.
# --max-budget-usd caps each message of a run, so a round can cost the sum
# of those caps, and a little more: claude -p checks its cap after each turn,
# and on the cost of that message alone. The result of a resumed session
# gives the cost of each message of the session, so the cost of a run is the
# last result in its log. With
# --max-cost, the eval stops before a round that could take the cost of the
# pass past it. The report ends with the cost of the pass. A failing check
# is a result, not an error: it exits 0. The run folder keeps a folder for
# each round, run1 and on, with each case's log, events, tracker, branches and
# workspace, and the branches and the workspace of its Given.
#
# With --check, it runs only the checks and the pass^k count, on the round
# folders of an earlier run, one folder for each run. `make check` runs them so
# on tests/fixtures/scenarios, through tests/scenarios_checks_test.sh. With
# --not-run, it prints the scenarios of take-in that no case runs yet.
#
# Usage: tests/scenarios_eval.sh [--runs k] [--model name] [--max-cost usd] [case ...]
#        tests/scenarios_eval.sh --check <round folder> ...
#        tests/scenarios_eval.sh --not-run

# shellcheck disable=SC2016 # jq's $
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
usage() { echo "usage: $0 [--runs k] [--model name] [--max-cost usd] [case ...] | --check <round folder> ... | --not-run" >&2; exit 2; }
take_in() { bash "$root/tests/scenarios_take_in.sh" "$@"; }
table=$(take_in cases)
# budget <case>, message <case>, answer <case>: the cap of one message, the
# message of the person, and the answer after it or nothing, from the line of
# the case.
budget() { awk -v c="$1" '$1 == c { print $2 }' <<<"$table"; }
message() { awk -v c="$1" '$1 == c { print $3 }' <<<"$table"; }
answer() { awk -v c="$1" '$1 == c { $1 = $2 = $3 = ""; sub(/^ +/, ""); print }' <<<"$table"; }
# record <dir>: <dir>.events holds the messages to the person, as text lines,
# the answer of the person, as a person line,
# the session's other thinking that has words, as think lines, and each tool
# call of the session and its subagents, as its tool's name, or sub and the
# name, and its command, path or skill. A message before a tool call can
# reach the log as a thinking block that narration_block_indexes names: the
# API gives it in other words, and the person reads those words (ADR 0008).
# Paths of this machine become <craft>,
# <work> and <tmp>. Each line of a command becomes one part of a line, after
# "; ". Then snapshot writes <dir>.branches and <dir>.workspace.
record() {
  jq -r 'if .type == "person" then "person\t" + .text
    elif .type == "assistant" then (if .parent_tool_use_id then "sub" else "" end) as $sub
      | (.narration_block_indexes // []) as $said
      | .message.content | to_entries[] | .key as $i | .value
      | if $sub == "" and (.type == "text" or .type == "thinking" and any($said[]; . == $i)) then "text\t" + ((.text // .thinking) | gsub("\n"; " "))
        elif .type == "thinking" and $sub == "" and (.thinking // "" | test("[a-z]")) then "think\t" + (.thinking | gsub("\n"; " "))
        elif .type == "tool_use" then $sub + .name + "\t"
          + ((.input.command // .input.file_path // .input.skill // .input.description // "") | tostring | gsub("\n"; "; "))
        else empty end
    else empty end' "$1.jsonl" |
    awk -v r="$root" -v w="$1" -v t="${TMPDIR:-/tmp}" '{ gsub(r, "<craft>"); gsub("(/private)?" w, "<work>")
      gsub("(/private)?" t, "<tmp>/"); gsub("<tmp>//", "<tmp>/"); print }' >"$1.events"
  take_in snapshot "$1" "$1"
}

# score <k> <round folder>...: for each round, the result and the cost of
# each case's run when its log is there, and the lines of check; then the
# pass^k line of each case in $cases.
score() {
  local k=$1 i=0 d c lines tally=
  shift
  for d; do
    i=$((i + 1))
    echo "round $i of $k"
    for c in $cases; do
      [ -f "$d/$c.events" ] || { echo "$c: no run: $d has no $c.events, as when its setup fails"; continue; }
      [ ! -f "$d/$c.jsonl" ] || printf '%s: %s\n' "$c" \
        "$(jq -Rr 'fromjson? | select(.type == "result") | "\(.subtype), $\(.total_cost_usd)"' "$d/$c.jsonl" | tail -n 1)"
      lines=$(take_in check "$d/$c" "$c") || { echo "$c: not checked, as its check says above"; continue; }
      printf '%s\n' "$lines"
      if grep -q '^FAIL ' <<<"$lines"; then tally="$tally$c 0"$'\n'; else tally="$tally$c 1"$'\n'; fi
    done
  done
  for c in $cases; do
    printf '%s' "$tally" | awk -v c="$c" -v k="$k" '$1 == c { n++; p += $2 } END {
      if (p < n) printf "pass^%d %s: FAIL, %d of %d runs pass\n", k, c, p, n
      else if (n < k) printf "pass^%d %s: not measured, %d run%s of %d\n", k, c, n, (n == 1 ? "" : "s"), k
      else printf "pass^%d %s: PASS, %d of %d runs pass\n", k, c, p, n }'
  done
}

[ "${1:-}" != --not-run ] || { take_in not_run; exit 0; }
if [ "${1:-}" = --check ]; then
  shift
  [ $# -ge 1 ] || usage
  for d; do [ -d "$d" ] || usage; done
  cases=$(for d; do for f in "$d"/*.events; do [ ! -e "$f" ] || basename "$f" .events; done; done | sort -u)
  [ -n "$cases" ] || usage
  score $# "$@"
  exit 0
fi
k=1 model=opus cap=
while [ $# -ge 2 ]; do
  case $1 in
    --runs) k=$2 ;;
    --model) model=$2 ;;
    --max-cost) cap=$2 ;;
    *) break ;;
  esac
  shift 2
done
case $k in '' | *[!0-9]* | 0*) usage ;; esac
case $cap in *[!0-9.]* | *.*.* | .) usage ;; esac
[ -n "$model" ] || usage
cases=${*:-$(cut -d' ' -f1 <<<"$table")}
for c in $cases; do [ -n "$(budget "$c")" ] || usage; done
command -v claude >/dev/null || { echo "$0: no claude command" >&2; exit 2; }
command -v jq >/dev/null || { echo "$0: no jq command" >&2; exit 2; }

# session <workspace> <case> <argument>...: one claude -p in the workspace,
# on the message that the last argument gives.
session() {
  local w=$1 c=$2
  shift 2
  (cd "$w" && PATH="$w.bin:$PATH" claude -p --model "$model" --setting-sources project \
    --settings '{"language":"English"}' --plugin-dir "$root" --output-format stream-json --verbose \
    --max-budget-usd "$(budget "$c")" --disallowedTools ListAgents --dangerously-skip-permissions "$@") 2>&1 || true
}

# run <round folder> <case>: the session on the message of the case, and on
# its answer, which a person line in the log comes before.
run() {
  local w=$1/$2 id
  take_in setup "$w" "$2"
  session "$w" "$2" "$(message "$2")" >"$w.jsonl"
  if [ -n "$(answer "$2")" ]; then
    id=$(jq -Rr 'fromjson? | select(.type == "system" and .subtype == "init") | .session_id' "$w.jsonl" | head -n 1)
    [ -z "$id" ] || { jq -nc --arg t "$(answer "$2")" '{type: "person", text: $t}'
      session "$w" "$2" --resume "$id" "$(answer "$2")"; } >>"$w.jsonl"
  fi
  record "$w"
}

# spent: the cost of the runs so far, from the last result line of each log.
spent() {
  jq -Rr 'fromjson? | select(.type == "result") | "\(input_filename) \(.total_cost_usd)"' "$runs"/run*/*.jsonl 2>/dev/null |
    awk '{ last[$1] = $2 } END { for (f in last) s += last[f]; printf "%.2f\n", s }'
}
# messages <case>: the number of messages of the person in a run of the case.
messages() { if [ -n "$(answer "$1")" ]; then echo 2; else echo 1; fi; }

need=0
for c in $cases; do need=$((need + $(budget "$c") * $(messages "$c"))); done
runs=$(mktemp -d)
rounds=() stop=
for i in $(seq "$k"); do
  if [ -n "$cap" ] && awk -v s="$(spent)" -v n="$need" -v c="$cap" 'BEGIN { exit !(s + n > c) }'; then
    stop=$(printf 'stopped before round %s of %s: $%s spent, and a round can cost $%.2f more, past the cap of $%s' \
      "$i" "$k" "$(spent)" "$need" "$cap")
    break
  fi
  mkdir "$runs/run$i"
  rounds+=("$runs/run$i")
  for c in $cases; do run "$runs/run$i" "$c" & done
  wait
done
score "$k" ${rounds[@]+"${rounds[@]}"}
[ -z "$stop" ] || echo "$stop"
echo "cost: \$$(spent)"
echo "runs: $runs"
