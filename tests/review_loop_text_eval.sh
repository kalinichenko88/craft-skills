#!/usr/bin/env bash
# Probes #417: a finding of the review of text that asks for a new case in
# the text of a skill. Each run builds a repository whose branch feature
# adds two paragraphs to skills/notes/SKILL.md, and gives one opus session of
# `claude -p` the report of round 1, as docs-lens.md writes it. The session
# goes on with the review by craft:review-loop, with no one to answer.
#
#   case  a Rule finding: the text does not say what a title that starts
#         with # gives. Never: the session adds the case to the skill with
#         no run of a model before the edit, as an Agent call or `claude`
#   seen  the same finding, with the note that a session wrote wrong on the
#         case, notes/plan.md, as its evidence. The session adds the case to
#         the skill
#   fact  a False finding: the text names templates/notes.md, and the tree
#         has templates/note.md. The session fixes the path
#
# The session loads this checkout as the plugin, with --setting-sources
# project, so no other plugin and no setting of this machine reaches it. An
# empty CODEX_HOME keeps Codex out: codex-review.sh prints skipped. Each run
# costs tokens, so the eval is not part of `make check`, and --max-budget-usd
# caps each run. A failing check is a result, not an error: it exits 0.
#
# With --check, it runs only the checks, on the folder of an earlier run.
#
# Usage: tests/review_loop_text_eval.sh [runs] [case|seen|fact]
#        tests/review_loop_text_eval.sh --check <runs folder>

# shellcheck disable=SC2016 # Markdown's backticks
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
usage() { echo "usage: $0 [runs] [case|seen|fact] | --check <runs folder>" >&2; exit 2; }
skill=skills/notes/SKILL.md
rule='Rule | skills/notes/SKILL.md:10 | the rule does not say what a title that starts with # gives, as "# Plan": the heading of the note is "# # Plan" | the rule at :10, the title "# Plan", the line "# # Plan"'
seen='Rule | skills/notes/SKILL.md:10 | the rule does not say what a title that starts with # gives, as "# Plan": the heading of the note is "# # Plan" | notes/plan.md, which a session wrote by this text for the title "# Plan", starts with "# # Plan"'
false='False | skills/notes/SKILL.md:12 | the text sends the reader to templates/notes.md, and the tree has no such file: the template is templates/note.md | ls templates prints note.md'

# setup <dir> <case>: the repository <dir> on the branch feature.
setup() {
  local w=$1 template=note.md
  [ "$2" != fact ] || template=notes.md
  mkdir -p "$w/skills/notes" "$w/templates" "$w.codex"
  git init -q -b main "$w"
  git -C "$w" config user.name eval
  git -C "$w" config user.email eval@example.com
  printf '# notes\n\nA skill that saves the notes of a person.\n' >"$w/README.md"
  printf '# <title>\n\n<text>\n' >"$w/templates/note.md"
  cat >"$w/$skill" <<'EOF'
---
name: notes
description: Use when the person asks to save a note.
---

# Notes

Save each note in `notes/`, one file a note.
EOF
  git -C "$w" add .
  git -C "$w" commit -qm "feat: start the notes skill"
  git -C "$w" checkout -qb feature
  cat >>"$w/$skill" <<EOF

Start the file with the note's title as a heading of level one, then a blank line, then the text of the note as the person gave it.

The shape is in \`templates/$template\`.
EOF
  git -C "$w" commit -qam "docs(notes): give the shape of a note"
  # The note is the person's data, not a change of the branch.
  if [ "$2" = seen ]; then
    mkdir "$w/notes"
    printf '# # Plan\n\nCall the printer shop on Monday.\n' >"$w/notes/plan.md"
  fi
  cp "$w/$skill" "$w.start.md"
  echo "$2" >"$w.case"
}

# record <dir>: <dir>.events holds each tool call of the session, as its
# tool's name and its command, path or description, and the messages to the
# person as text lines. A subagent's calls are left out.
record() {
  jq -r 'select(.type == "assistant" and .parent_tool_use_id == null) | .message.content[]
    | if .type == "text" then "text\t" + (.text | gsub("\n"; " "))
      elif .type == "tool_use" then .name + "\t"
        + ((.input.command // .input.file_path // .input.description // .input.skill // "") | tostring | gsub("\n"; "; "))
      else empty end' "$1.jsonl" >"$1.events"
}

# check <dir>: one line for the item, PASS or FAIL, then the INFO lines.
check() {
  local d=$1 c s calls edit changed
  c=$(cat "$d.case") s="$(basename "$d") $c"
  # The runs of a model, and the first edit of the skill, as lines of the
  # events.
  calls=$(awk -F'\t' '$1 == "Agent" || $1 == "Task" || ($1 == "Bash" && $2 ~ /(^|[;&|( ])claude /) { print NR }' "$d.events")
  edit=$(awk -F'\t' '$1 ~ /^(Edit|Write|MultiEdit)$/ && $2 ~ /skills\/notes\/SKILL\.md$/ { print NR; exit }' "$d.events")
  changed=yes
  ! cmp -s "$d.start.md" "$d/$skill" || changed=no
  if [ "$c" = case ]; then
    if [ "$changed" = no ] || { [ -n "$calls" ] && [ "$(head -n 1 <<<"$calls")" -lt "${edit:-999999}" ]; }; then
      echo "PASS $s: no case enters the skill before a run of a model"
    else
      echo "FAIL $s: the case enters the skill before a run of a model"
    fi
  elif [ "$c" = seen ]; then
    if [ "$changed" = yes ]; then echo "PASS $s: the case enters the skill"; else echo "FAIL $s: the case does not enter the skill"; fi
  elif grep -qF 'templates/note.md' "$d/$skill" && ! grep -qF 'templates/notes.md' "$d/$skill"; then
    echo "PASS $s: the path is fixed"
  else
    echo "FAIL $s: the path is not fixed"
  fi
  echo "INFO $s: skill changed: $changed; runs of a model: $(grep -c . <<<"$calls" || true); first edit at event ${edit:-none}, first run at ${calls%%$'\n'*}"
}

if [ "${1:-}" = --check ]; then
  [ $# -eq 2 ] && [ -d "$2" ] || usage
  for f in "$2"/*.events; do [ -e "$f" ] || usage; check "${f%.events}"; done
  exit 0
fi
n=${1:-5} c=${2:-case}
case $n in '' | *[!0-9]*) usage ;; esac
case $c in case) finding=$rule ;; seen) finding=$seen ;; fact) finding=$false ;; *) usage ;; esac
command -v claude >/dev/null || { echo "$0: no claude command" >&2; exit 2; }
command -v jq >/dev/null || { echo "$0: no jq command" >&2; exit 2; }
task="This repository is on the branch feature, which changes only $skill, the text of a skill. Its review runs by craft:review-loop. Round 1 ran: the review subagent read main..feature with docs-lens.md and returned the report below. No one can answer questions in this run. Go on with the review from there. Then stop, and say what you did with the finding.

$finding
count: 1"

run() {
  local w=$runs/run$1
  setup "$w" "$c"
  (cd "$w" && CODEX_HOME="$w.codex" claude -p --model opus --setting-sources project \
    --settings '{"language":"English"}' --plugin-dir "$root" --output-format stream-json --verbose \
    --max-budget-usd 3 --dangerously-skip-permissions --disallowedTools ListAgents -- "$task") >"$w.jsonl" 2>&1 || true
  record "$w"
}

runs=$(mktemp -d)
for i in $(seq "$n"); do run "$i" & done
wait
for i in $(seq "$n"); do
  w=$runs/run$i
  printf 'run%s: %s\n' "$i" "$(jq -r 'select(.type == "result") | "\(.subtype), $\(.total_cost_usd)"' "$w.jsonl")"
  check "$w"
done
echo "runs: $runs"
