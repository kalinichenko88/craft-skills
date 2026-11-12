#!/usr/bin/env bash
# Reads the text of a skill against the scenario file of its flow, for #243 and
# #294: an edit of a skill's text that drops a branch of a flow fails no other
# check but a paid run of tests/scenarios_eval.sh, which has cases for take-in
# only. Each file in scenarios/*/*.md has a row in `rows` below: the scenario
# file, then the files of the skill that its flow reads. The eval runs each
# row, or the row of the scenario file that its first argument names, or with
# --changed each row with a skill file that differs between the base and the
# working tree, also an untracked one. Both sides read the scenario file of the
# working tree, so a change of it alone gives no LOST. CI runs the eval with
# --changed on each pull request (ADR 0007). A scenario file with no row stops
# the eval before a run, and so does a file of a row that is missing in the
# working tree.
#
# Each run is one haiku session of `claude -p` with no tool. It gets the
# scenario file, its Then and Never items with an id, and the files of the
# row, each line with its path and number. For each item it answers with the
# line that produces it, or none. The eval makes k runs on the text at a base
# commit and k on the working tree, both with the scenario file of the working
# tree. An item is LOST when most runs on the working tree give no line for
# it, as none or by leaving it out, and at most a fifth of the runs on the
# base do: an item that the base gives no line in more runs is too weak to
# judge, as a weak Never item that no line produces. A row with a LOST item
# gets a second set of k runs on each side, in again/ of its runs folder, and
# an item stays LOST only when the second set loses it too.
#
# The rule before #328, one set with half of the runs on the base, failed 3 of
# 8 runs of the CI job on pull requests, on items at 3 of 5 against 1 or 2 of 5
# on the base that the next run did not give again. Measured on 2026-11-11
# with k = 5, on texts equal to the base, 3 rows of filing.md and 2 of
# worth.md: that rule lost an item in 2 rows, the second set alone or the
# fifth alone in 1, and both in none. On a cut of lines 32 to 35 and 45 of
# take-in.md, this rule loses 13 of the 17 items that the cut lines produce,
# 16 in the first set, each with a line in all runs on the base.
#
# Measured before #328 on two cuts of five lines of take-in.md with k = 5: 22
# of the 26 items that the cut lines produce are LOST, and no other item. One
# run on each text finds 107 of 130, with 11 other items over 10 pairs. With no
# rule against a general step in the prompt, 2 of 16: Haiku gives the nearest
# heading or the rule for errors. A new row counts after the same measure: one
# cut of 3 to 5 lines that its scenarios need, 5 runs on the cut text against
# 5 on the base, with the result in the pull request that adds the row.
#
# Each run costs about $0.02, so the eval is not part of `make check`. A LOST
# item is a result, not an error: it exits 0. The runs folder keeps the items,
# the prompts and the answers. With --check, it runs only the checks, on the
# folder of an earlier run. `make check` runs them so on
# tests/fixtures/scenarios_text, through tests/scenarios_text_checks_test.sh.
#
# Usage: tests/scenarios_text_eval.sh [scenario file | --changed] [runs, default 5] [base, default the merge base with origin/main]
#        tests/scenarios_text_eval.sh --check <runs folder>

# shellcheck disable=SC2016 # Markdown's backticks
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
rows=(
  'scenarios/github/take-in.md skills/github/SKILL.md skills/github/take-in.md skills/github/tracker.md skills/github/scout.md'
  'scenarios/github/filing.md rules.md skills/github/SKILL.md skills/github/filing.md skills/github/tracker.md skills/github/scout.md'
  'scenarios/github/pull-request.md rules.md skills/github/SKILL.md skills/review-loop/SKILL.md skills/github/filing.md skills/github/take-in.md skills/github/tracker.md skills/github/scout.md'
  'scenarios/review-loop/review.md skills/review-loop/SKILL.md skills/github/SKILL.md skills/github/filing.md'
  'scenarios/product/worth.md rules.md skills/product/SKILL.md skills/product/reader.md skills/product/store.md skills/review-loop/SKILL.md skills/github/take-in.md'
  'scenarios/roadmap/next.md skills/roadmap/SKILL.md skills/roadmap/lanes.md skills/roadmap/planning.md'
  'scenarios/roadmap/milestone.md skills/roadmap/SKILL.md'
  'scenarios/roadmap/later.md skills/roadmap/SKILL.md'
  'scenarios/roadmap/plan.md skills/roadmap/SKILL.md skills/roadmap/planning.md skills/github/filing.md'
  'scenarios/roadmap/triage.md skills/roadmap/SKILL.md skills/roadmap/triage.md skills/github/take-in.md skills/github/filing.md skills/github/tracker.md'
)
usage() { echo "usage: $0 [scenario file | --changed] [runs] [base] | --check <runs folder>" >&2; exit 2; }
# row_of <scenario file>: the row of that file, or a status of 1.
row_of() {
  local r
  for r in "${rows[@]}"; do [ "${r%% *}" != "$1" ] || { echo "$r"; return 0; }; done
  return 1
}

# check <runs folder>: a LOST line for each item that most runs on the working
# tree give no line for, and at most a fifth of the runs on the base. When the
# folder holds a second set of runs in again/, an item is LOST only when each
# set loses it, and the line gives the counts of both sets together. An item
# that a run answers none, or leaves out, has no line in that run. A run with
# no answer counts on neither side.
check() {
  local f=(s=1 "$1"/base*.txt "$1"/change*.txt) sets=1
  [ ! -d "$1/again" ] || { f+=(s=2 "$1"/again/base*.txt "$1"/again/change*.txt); sets=2; }
  awk -v sets="$sets" 'FILENAME ~ /items\.tsv$/ { split($0, a, "\t"); order[++n] = a[1]; name[a[1]] = a[2] ": " a[3]; next }
    { split($0, w, " ") }
    !(w[1] in name) { next }
    !(FILENAME in answered) { answered[FILENAME]; side = FILENAME; sub(/.*\//, "", side); sub(/[0-9]+\.txt$/, "", side); runs[s, side]++ }
    w[2] != "none" { cited[s, side, w[1]]++ }
    END {
      for (s = 1; s <= sets; s++) {
        if (!runs[s, "change"] || !runs[s, "base"]) { print "no answer on the working tree or on the base" > "/dev/stderr"; exit 2 }
        rc += runs[s, "change"]
        rb += runs[s, "base"]
      }
      for (i = 1; i <= n; i++) {
        id = order[i]
        c = b = 0
        all = 1
        for (s = 1; s <= sets; s++) {
          cs = runs[s, "change"] - cited[s, "change", id]
          bs = runs[s, "base"] - cited[s, "base", id]
          if (2 * cs <= runs[s, "change"] || 5 * bs > runs[s, "base"]) all = 0
          c += cs
          b += bs
        }
        if (all) {
          lost++
          printf "LOST %s %s (no line in %d of %d runs, on the base in %d of %d)\n", id, name[id], c, rc, b, rb
        }
      }
      printf "%d of %d items lost, %d runs on the working tree and %d on the base\n", lost, n, rc, rb
    }' "$1/items.tsv" "${f[@]}"
}

if [ "${1:-}" = --check ]; then
  [ "$#" = 2 ] || usage
  check "$2"
  exit 0
fi
selected=("${rows[@]}")
changed=
case "${1:-}" in
*.md)
  row=$(row_of "${1#./}") || { echo "$0: $1 has no row" >&2; exit 2; }
  selected=("$row")
  shift
  ;;
--changed)
  changed=1
  shift
  ;;
esac
[ "$#" -le 2 ] || usage
runs=${1:-5}
[ "$runs" -ge 1 ] 2>/dev/null || usage
base=${2:-$(git -C "$root" merge-base origin/main HEAD)}
git -C "$root" rev-parse -q --verify "$base^{commit}" >/dev/null || { echo "$0: no commit $base" >&2; exit 2; }
for f in "$root"/scenarios/*/*.md; do
  f=${f#"$root/"}
  row_of "$f" >/dev/null || { echo "$0: $f has no row: add one, measured as the header says" >&2; exit 2; }
done
if [ -n "$changed" ]; then
  selected=()
  for row in "${rows[@]}"; do
    read -r -a files <<<"$row"
    files=("${files[@]:1}")
    if ! git -C "$root" diff --quiet "$base" -- "${files[@]}" ||
      [ -n "$(git -C "$root" ls-files --others --exclude-standard -- "${files[@]}")" ]; then
      selected+=("$row")
    fi
  done
  [ "${#selected[@]}" -gt 0 ] || { echo "No skill file of a row differs from $base."; exit 0; }
  echo "Changed rows: ${selected[*]%% *}"
fi

# items: each Then and Never item of $scenario: <scenario number>.<T or N><item
# number>, the scenario, and the item's text with its continuation lines.
items() {
  awk 'function flush() { if (id != "") printf "%s\t%s\t%s\n", id, s, t; id = "" }
    /^## / { flush(); n++; s = substr($0, 4); sec = ""; next }
    /^Then:/ { flush(); sec = "T"; k = 0; next }
    /^Never:/ { flush(); sec = "N"; k = 0; next }
    /^(Given|When):/ { flush(); sec = ""; next }
    sec != "" && /^- / { flush(); id = n "." sec (++k); t = substr($0, 3); next }
    id != "" && /^  / { sub(/^ +/, ""); t = t " " $0; next }
    { flush() }
    END { flush() }' "$root/$scenario"
}

# lines <side>: the skill's files on that side, each line with its path and
# number. A file that the base does not have, as a new one, gives the base no
# line.
lines() {
  local f
  for f in "${files[@]}"; do
    if [ "$1" = base ]; then git -C "$root" show "$base:$f" 2>/dev/null; else cat "$root/$f"; fi |
      awk -v f="$f" '{ print f ":" FNR ": " $0 }'
  done
}
prompt() {
  cat <<'EOF'
You check the text of a skill against the scenarios of its flow. The scenario
file says what the flow does, as seen from outside. The skill's files are the
text that an agent follows to run the flow; each of their lines starts with
its path and line number.

For each Then and Never item in the list, find the line of the skill's files
that produces it in the state of its scenario's Given:
- for a Then item, the line that makes the run reach that outcome;
- for a Never item, the line that keeps the run from doing it: a stop or a
  wait before it, or a rule against it.
The line must name the state of the Given, or the outcome itself. A line about
another case does not count, nor a line that names only a general step: a
heading, a rule for errors, or "act on what was printed". When no line
produces the item in that state, the answer is none.

Answer with one line per item, in the order of the list, and nothing else:
`<id> <path>:<line> "<the words of that line that name it>"` or `<id> none`.

=== The scenario file
EOF
  cat "$root/$scenario"
  printf '\n=== The items: <id> | <scenario> | <item>\n'
  awk -F'\t' '{ print $1 " | " $2 " | " $3 }' "$logs/items.tsv"
  printf "\n=== The skill's files\n"
  lines "$1"
}
# run <folder> <side> <i>: one session in an empty folder, so that no file of a
# project reaches it; its answer goes to <side><i>.txt in <folder>. The text of
# a session that ends in an error is no answer.
run() {
  local dir
  dir=$(mktemp -d)
  (cd "$dir" && claude -p --model haiku --tools '' --setting-sources project \
    --settings '{"language":"English"}' --no-session-persistence \
    --output-format json --max-budget-usd 1 <"$logs/$2.prompt") >"$1/$2$3.json" 2>&1 || true
  jq -r 'select(.is_error != true) | .result // empty' "$1/$2$3.json" >"$1/$2$3.txt" 2>/dev/null || true
  rm -rf "$dir"
}
# run_set <folder>: $runs runs on each side, all at once, into <folder>.
run_set() {
  local j
  for j in $(seq "$runs"); do
    run "$1" base "$j" &
    run "$1" change "$j" &
  done
  wait
}

# The files of every row are checked first, so that a fault in any row stops
# the eval before a run. A row gets its runs folder only when its runs start.
for row in "${selected[@]}"; do
  read -r -a files <<<"$row"
  for f in "${files[@]:1}"; do
    [ -f "$root/$f" ] || { echo "$0: $f is not in the working tree: the row of ${files[0]} needs a change" >&2; exit 2; }
  done
done
for row in "${selected[@]}"; do
  read -r -a files <<<"$row"
  scenario=${files[0]}
  files=("${files[@]:1}")
  logs=$(mktemp -d)
  items >"$logs/items.tsv"
  for side in base change; do prompt "$side" >"$logs/$side.prompt"; done
  run_set "$logs"
  echo "Scenario: $scenario"
  echo "Runs: $logs"
  # A LOST item can be noise of the model (#328): a row with one gets a second
  # set of runs, and the check keeps only the items that both sets lose.
  last=$logs
  if first=$(check "$logs" 2>/dev/null) && grep -q '^LOST' <<<"$first"; then
    echo "The first set loses $(grep -c '^LOST' <<<"$first") items, so a second set of $runs runs on each side checks them:"
    sed -n 's/^LOST /  /p' <<<"$first"
    last=$logs/again
    mkdir "$last"
    run_set "$last"
  fi
  # With no answer, the first run of the last set tells why, as a token that
  # expired: the CLI puts the reason in .result.
  check "$logs" || { echo "$0: the first run printed: $(jq -r '.result // empty' "$last/change1.json" 2>/dev/null || head -c 300 "$last/change1.json")" >&2; exit 2; }
done
