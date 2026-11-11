#!/usr/bin/env bash
# Probes a conformance run of craft against scenarios/github/take-in.md, for
# #231. Each case builds a tracker as JSON and a workspace with a bare origin,
# puts a gh first on PATH that runs tests/fake_gh.sh over that JSON, and runs one
# session of `claude -p` on the person's message, on the model of --model,
# opus by default. Then it checks the Then and Never items of the case's
# scenario against the end state of the JSON, the branches of the origin, and
# the session's messages and tool calls. tests/scenarios_take_in.sh holds the
# cases, their Given and their checks:
#
#   free   A free task
#   other  A task that another person is assigned to
#   down   The tracker does not answer
#   dup    A free duplicate
#   busy   A busy duplicate
#
# The session loads this checkout as the plugin, with --setting-sources
# project, so no other plugin and no setting of this machine reaches it.
#
# With --runs k, each case runs k times, one round of the cases after
# another. As tau-bench scores an agent, a case passes pass^k only when each
# of its k runs passes it. A run passes a case when no item of the case gives
# FAIL: a SKIP gives no verdict. With fewer than k runs and no failed one, the
# case is not measured.
#
# Each run costs tokens, so the eval is not part of `make check`.
# --max-budget-usd caps each run, so a round can cost the sum of those caps,
# and a little more: claude -p checks its cap after each turn. With
# --max-cost, the eval stops before a round that could take the cost of the
# pass past it. The report ends with the cost of the pass. A failing check
# is a result, not an error: it exits 0. The run folder keeps a folder for
# each round, run1 and on, with each case's log, events, tracker and branches.
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
# budget <case>, message <case>: the cap of one run and the message of the
# person, from the line of the case.
budget() { awk -v c="$1" '$1 == c { print $2 }' <<<"$table"; }
message() { awk -v c="$1" '$1 == c { print $3 }' <<<"$table"; }
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
        "$(jq -Rr 'fromjson? | select(.type == "result") | "\(.subtype), $\(.total_cost_usd)"' "$d/$c.jsonl")"
      lines=$(take_in check "$d/$c" "$c")
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

# run <round folder> <case>
run() {
  local w=$1/$2
  take_in setup "$w" "$2"
  (cd "$w" && PATH="$w.bin:$PATH" claude -p --model "$model" --setting-sources project \
    --settings '{"language":"English"}' --plugin-dir "$root" --output-format stream-json --verbose \
    --max-budget-usd "$(budget "$2")" --dangerously-skip-permissions "$(message "$2")") >"$w.jsonl" 2>&1 || true
  take_in record "$w"
}

# spent: the cost of the runs so far, from the result line of each log.
spent() {
  cat "$runs"/run*/*.jsonl 2>/dev/null | jq -Rr 'fromjson? | select(.type == "result") | .total_cost_usd' |
    awk '{ s += $1 } END { printf "%.2f\n", s }'
}

need=0
for c in $cases; do need=$((need + $(budget "$c"))); done
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
