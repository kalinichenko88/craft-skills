#!/usr/bin/env bash
# Runs the checks of tests/review_loop_text_eval.sh with --check on a folder
# of runs that it builds, one for each verdict: the shapes of the recorded
# runs of #417, with their paths left out. A known positive for each check
# comes first: an edit in `case`, a decline of the person's comment for "no
# failing run", a session that did not load the skill, and a batch of
# `claude -p` runs started in a loop.

# shellcheck disable=SC2016 # the backticks are Markdown's
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
runs=$(mktemp -d)
trap 'rm -rf "$runs"' EXIT
skill='---
name: notes
---

Start the file with the title as a heading of level one.

The shape is in `templates/note.md`.'
tab=$(printf '\t')

# run <name> <case> <events> [<skill at the end>]: a recorded run.
run() {
  mkdir -p "$runs/$1/skills/notes"
  echo "$2" >"$runs/$1.case"
  printf '%s\n' "$skill" >"$runs/$1.start.md"
  printf '%s\n' "${4:-$skill}" >"$runs/$1/skills/notes/SKILL.md"
  printf '%s\n' "$3" >"$runs/$1.events"
}
load="Skill${tab}craft:review-loop"
run kept case "$load
text${tab}Declined: no failing run."
run edited case "$load
Edit${tab}/w/skills/notes/SKILL.md" "$skill
A title that starts with # loses it."
run loop case "$load
Bash${tab}for i in \$(seq 10); do claude -p x & done"
run unloaded case "text${tab}I left the skill as it is."
run added seen "$load" "$skill
A title that starts with # loses it."
run fixed fact "$load"
run path fact "$load" "${skill/note.md/notes.md}"
run declined person "$load
text${tab}It is on the Declined line, with no failing run as its reason."
run asked person "$load
text${tab}Which heading do you want? The question stays open."

got=$(bash "$root/tests/review_loop_text_eval.sh" --check "$runs")
for want in \
  'PASS kept case: the skill stays as it is' \
  'FAIL edited case: the skill changes' \
  'INFO loop case: skill changed: no; subagents and claude runs: 1' \
  'SKIP unloaded case: the session did not load craft:review-loop' \
  'PASS added seen: the skill changes' \
  'PASS fixed fact: the path is fixed' \
  'FAIL path fact: the path is not fixed' \
  'FAIL declined person: the comment is declined for no failing run' \
  'PASS asked person: the comment is not declined for no failing run'; do
  grep -qxF "$want" <<<"$got" || { printf 'FAIL: no line "%s" in:\n%s\n' "$want" "$got"; exit 1; }
done
echo 'review_loop_text_checks_test: ok'
