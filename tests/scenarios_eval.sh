#!/usr/bin/env bash
# Probes a conformance run of craft against scenarios/github/take-in.md, for
# #231. Each case builds a tracker as JSON and a workspace with a bare origin,
# puts a gh first on PATH that runs tests/fake_gh.sh over that JSON, and runs one
# session of `claude -p` on the person's message, on the model of --model,
# opus by default. In a case of more messages, each answer of the person
# resumes that session, with --resume and the same plugin and PATH. Then it
# checks the Then and Never items of the case's
# scenario against the end state of the JSON, the branches of the origin, and
# the session's messages and tool calls. tests/scenarios_take_in/ holds a
# file for each case, with its scenario, its Given and its checks, and
# tests/scenarios_take_in.sh what the cases share.
#
# The session loads this checkout as the plugin, with --setting-sources
# project, so no other plugin and no setting of this machine reaches it. It
# runs with no ListAgents: that tool lists every session of this machine, so
# the runs of a round see each other as open sessions on #91, and the log
# would hold the names of the person's other sessions. The one exception is a
# case whose Given has another open conversation, as <dir>.companion of setup
# gives: a session of Haiku with no tools starts on the first text of that
# conversation, which the file holds, before the run, and stays open until
# the run ends. The run then has ListAgents, and sees it as one of the
# sessions of this machine. Such a case runs after the other cases of its
# round end, one at a time, so that it sees no other run. When the other
# conversation gives a first result with no error, the log of the run starts
# with a companion line and its first text. Its cap of $0.10 is not in the
# cap of a round that --max-cost reads. Read the log of such a run for the
# names of the person's other sessions before it becomes a fixture.
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
# budget <case>, message <case>, answers <case>: the cap of one message, the
# message of the person, and each answer after it, one on each line, from the
# line of the case.
budget() { awk -F'\t' -v c="$1" '$1 == c { print $2 }' <<<"$table"; }
message() { awk -F'\t' -v c="$1" '$1 == c { print $4 }' <<<"$table"; }
answers() { awk -F'\t' -v c="$1" '$1 == c { for (i = 5; i <= NF; i++) print $i }' <<<"$table"; }
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
  { [ ! -f "$1.companion.jsonl" ] || [ "$(jq -Rr 'fromjson? | select(.type == "result") | .subtype' "$1.companion.jsonl" | head -n 1)" != success ] ||
    printf 'companion\t%s\n' "$(cat "$1.companion")"
  jq -r 'if .type == "person" then "person\t" + .text
    elif .type == "assistant" then (if .parent_tool_use_id then "sub" else "" end) as $sub
      | (.narration_block_indexes // []) as $said
      | .message.content | to_entries[] | .key as $i | .value
      | if $sub == "" and (.type == "text" or .type == "thinking" and any($said[]; . == $i)) then "text\t" + ((.text // .thinking) | gsub("\n"; " "))
        elif .type == "thinking" and $sub == "" and (.thinking // "" | test("[a-z]")) then "think\t" + (.thinking | gsub("\n"; " "))
        elif .type == "tool_use" then $sub + .name + "\t"
          + ((.input.command // .input.file_path // .input.skill // .input.description // "") | tostring | gsub("\n"; "; "))
        else empty end
    else empty end' "$1.jsonl"; } |
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
# A case named twice runs once: two setups of one folder would collide.
cases=$(if [ $# -gt 0 ]; then printf '%s\n' "$@"; else cut -f1 <<<"$table"; fi | awk '!seen[$0]++')
for c in $cases; do [ -n "$(budget "$c")" ] || usage; done
command -v claude >/dev/null || { echo "$0: no claude command" >&2; exit 2; }
command -v jq >/dev/null || { echo "$0: no jq command" >&2; exit 2; }

# session <workspace> <case> <argument>...: one claude -p in the workspace,
# on the message that the last argument gives. It reads no input, and does
# not hold the pipe of the open conversation.
session() {
  local w=$1 c=$2 deny=()
  shift 2
  # --disallowedTools takes a list: a flag after it ends the list.
  [ -f "$w.companion" ] || deny=(--disallowedTools ListAgents)
  (cd "$w" && PATH="$w.bin:$PATH" claude -p --model "$model" --setting-sources project \
    --settings '{"language":"English"}' --plugin-dir "$root" --output-format stream-json --verbose \
    --max-budget-usd "$(budget "$c")" ${deny[@]+"${deny[@]}"} --dangerously-skip-permissions "$@" </dev/null 7>&-) 2>&1 || true
}
# companion <workspace>: the open conversation of the Given, which reads its
# texts from the pipe <workspace>.in. The run alone writes to the pipe, on
# file descriptor 7, so the conversation reads the end of its texts when the
# run closes it, or ends. It has the first one when its first result comes,
# or after a minute.
companion() {
  local w=$1 i
  mkfifo "$w.in"
  (cd "$w" && PATH="$w.bin:$PATH" exec claude -p --model haiku --setting-sources project --settings '{"language":"English"}' \
    --plugin-dir "$root" --input-format stream-json --output-format stream-json --verbose --tools "" --max-budget-usd 0.1 \
    >"$w.companion.jsonl" 2>&1) <"$w.in" &
  pid=$!
  exec 7>"$w.in"
  jq -nc --arg t "$(cat "$w.companion")" '{type: "user", message: {role: "user", content: $t}}' >&7
  for i in $(seq 60); do ! grep -qs '"type":"result"' "$w.companion.jsonl" || break; sleep 1; done
}

# run <round folder> <case>: the session on the message of the case, set up
# before, and on each of its answers, which a person line in the log comes
# before; each answer resumes the session of the message before it.
run() {
  local w=$1/$2 id a i pid=
  [ -f "$w.state.json" ] || return 0
  [ ! -f "$w.companion" ] || companion "$w"
  session "$w" "$2" "$(message "$2")" >"$w.jsonl"
  answers "$2" | while IFS= read -r a; do
    id=$(jq -Rr 'fromjson? | select(.type == "system" and .subtype == "init") | .session_id' "$w.jsonl" | tail -n 1)
    [ -n "$id" ] || break
    { jq -nc --arg t "$a" '{type: "person", text: $t}'; session "$w" "$2" --resume "$id" "$a"; } >>"$w.jsonl"
  done
  # The end of its texts ends the other conversation; one that does not end in
  # ten seconds is stopped.
  if [ -n "$pid" ]; then
    exec 7>&-
    for i in $(seq 10); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  record "$w"
}

# spent: the cost of the runs so far, from the last result line of each log.
spent() {
  jq -Rr 'fromjson? | select(.type == "result") | "\(input_filename) \(.total_cost_usd)"' "$runs"/run*/*.jsonl 2>/dev/null |
    awk '{ last[$1] = $2 } END { for (f in last) s += last[f]; printf "%.2f\n", s }'
}
# messages <case>: the number of messages of the person in a run of the case.
messages() { echo $((1 + $(answers "$1" | grep -c .))); }

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
  # A case whose setup fails gets no run. A run that fails ends alone, as a
  # job of its own.
  for c in $cases; do { take_in setup "$runs/run$i/$c" "$c" || rm -f "$runs/run$i/$c.state.json"; } & done
  wait
  for c in $cases; do [ -f "$runs/run$i/$c.companion" ] || run "$runs/run$i" "$c" & done
  wait
  for c in $cases; do [ ! -f "$runs/run$i/$c.companion" ] || { run "$runs/run$i" "$c" & wait "$!" || true; }; done
done
score "$k" ${rounds[@]+"${rounds[@]}"}
[ -z "$stop" ] || echo "$stop"
echo "cost: \$$(spent)"
echo "runs: $runs"
