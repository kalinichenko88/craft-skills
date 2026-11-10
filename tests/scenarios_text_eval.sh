#!/usr/bin/env bash
# Reads the text of a skill against the scenario file of its flow, for #243 and
# #294: an edit of a skill's text that drops a branch of a flow fails no other
# check but a paid run of tests/scenarios_eval.sh, which has cases for take-in
# only. Each file in scenarios/*/*.md has a row in `rows` below: the scenario
# file, then the files of the skill that its flow reads. The eval runs each
# row, or the row of the scenario file that its first argument names. A
# scenario file with no row stops the eval before a run, and so does a file of
# a row that is missing on either side.
#
# Each run is one haiku session of `claude -p` with no tool. It gets the
# scenario file, its Then and Never items with an id, and the files of the
# row, each line with its path and number. For each item it answers with the
# line that produces it, or none. The eval makes k runs on the text at a base
# commit and k on the working tree, both with the scenario file of the working
# tree. An item is LOST when most runs on the working tree give no line for
# it, as none or by leaving it out, and at most half of the runs on the base
# do: a weak Never item that no line produces gets none on both texts.
#
# Measured on two cuts of five lines of take-in.md with k = 5: 22 of the 26
# items that the cut lines produce are LOST, and no other item. One run on each
# text finds 107 of 130, with 11 other items over 10 pairs. With no rule
# against a general step in the prompt, 2 of 16: Haiku gives the nearest
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
# Usage: tests/scenarios_text_eval.sh [scenario file] [runs, default 5] [base, default the merge base with origin/main]
#        tests/scenarios_text_eval.sh --check <runs folder>

# shellcheck disable=SC2016 # Markdown's backticks
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
rows=(
  'scenarios/github/take-in.md skills/github/SKILL.md skills/github/take-in.md skills/github/tracker.md skills/github/scout.md'
)
usage() { echo "usage: $0 [scenario file] [runs] [base] | --check <runs folder>" >&2; exit 2; }
# row_of <scenario file>: the row of that file, or a status of 1.
row_of() {
  local r
  for r in "${rows[@]}"; do [ "${r%% *}" != "$1" ] || { echo "$r"; return 0; }; done
  return 1
}

# check <runs folder>: a LOST line for each item that most runs on the working
# tree give no line for, and at most half of the runs on the base. An item
# that a run answers none, or leaves out, has no line in that run. A run with
# no answer counts on neither side.
check() {
  awk 'FILENAME ~ /items\.tsv$/ { split($0, a, "\t"); order[++n] = a[1]; name[a[1]] = a[2] ": " a[3]; next }
    { split($0, w, " ") }
    !(w[1] in name) { next }
    !(FILENAME in answered) { answered[FILENAME]; side = FILENAME; sub(/.*\//, "", side); sub(/[0-9]+\.txt$/, "", side); runs[side]++ }
    w[2] != "none" { cited[side, w[1]]++ }
    END {
      if (!runs["change"] || !runs["base"]) { print "no answer on the working tree or on the base" > "/dev/stderr"; exit 2 }
      for (i = 1; i <= n; i++) {
        id = order[i]
        c = runs["change"] - cited["change", id]
        b = runs["base"] - cited["base", id]
        if (2 * c > runs["change"] && 2 * b <= runs["base"]) {
          lost++
          printf "LOST %s %s (no line in %d of %d runs, on the base in %d of %d)\n", id, name[id], c, runs["change"], b, runs["base"]
        }
      }
      printf "%d of %d items lost, %d runs on the working tree and %d on the base\n", lost, n, runs["change"], runs["base"]
    }' "$1/items.tsv" "$1"/base*.txt "$1"/change*.txt
}

if [ "${1:-}" = --check ]; then
  [ "$#" = 2 ] || usage
  check "$2"
  exit 0
fi
selected=("${rows[@]}")
case "${1:-}" in
*.md)
  row=$(row_of "${1#./}") || { echo "$0: $1 has no row" >&2; exit 2; }
  selected=("$row")
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
# number.
lines() {
  local f
  for f in "${files[@]}"; do
    if [ "$1" = base ]; then git -C "$root" show "$base:$f"; else cat "$root/$f"; fi |
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
# run <side> <i>: one session in an empty folder, so that no file of a project
# reaches it; its answer goes to <side><i>.txt. The text of a session that ends
# in an error is no answer.
run() {
  local dir
  dir=$(mktemp -d)
  (cd "$dir" && claude -p --model haiku --tools '' --setting-sources project \
    --settings '{"language":"English"}' --no-session-persistence \
    --output-format json --max-budget-usd 1 <"$logs/$1.prompt") >"$logs/$1$2.json" 2>&1 || true
  jq -r 'select(.is_error != true) | .result // empty' "$logs/$1$2.json" >"$logs/$1$2.txt" 2>/dev/null || true
  rm -rf "$dir"
}

# The items and the prompts of every row come first, so that a fault in any
# row stops the eval before a run.
folders=()
for row in "${selected[@]}"; do
  read -r -a files <<<"$row"
  scenario=${files[0]}
  files=("${files[@]:1}")
  for f in "${files[@]}"; do
    if [ ! -f "$root/$f" ] || ! git -C "$root" cat-file -e "$base:$f" 2>/dev/null; then
      echo "$0: $f is not in the working tree or at $base: the row of $scenario needs a change" >&2
      exit 2
    fi
  done
  logs=$(mktemp -d)
  items >"$logs/items.tsv"
  for side in base change; do prompt "$side" >"$logs/$side.prompt"; done
  folders+=("$logs")
done
for i in "${!folders[@]}"; do
  logs=${folders[$i]}
  for j in $(seq "$runs"); do
    run base "$j" &
    run change "$j" &
  done
  wait
  echo "Scenario: ${selected[$i]%% *}"
  echo "Runs: $logs"
  check "$logs"
done
