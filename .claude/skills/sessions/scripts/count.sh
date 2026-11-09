#!/usr/bin/env bash
# Counts what the text of the craft skills costs in the local Claude Code
# sessions, and which of their scripts failed: one row per skill.
#
#   count.sh [days] [projects]
#
# days is 14 by default, and projects is ~/.claude/projects. A transcript
# counts when it changed in the last <days> days and is a person's session:
# its entrypoint is cli or claude-desktop, not sdk-cli, as claude -p gives. A
# subagent has a transcript, and a context, of its own. A skill of craft is
# one that loads from the plugin cache, under its name craft or its old name
# kalinichenko; a copy run from a checkout of this repository does not count.
#
# Needs bash, jq and awk.

set -euo pipefail

[ $# -le 2 ] && [[ ${1:-14} =~ ^[0-9]+$ ]] || {
  sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2
  exit 2
}
days=${1:-14} projects=${2:-$HOME/.claude/projects}
[ -d "$projects" ] || {
  echo "count.sh: $projects is not a folder" >&2
  exit 2
}

list=$(mktemp)
finished=
clean() {
  code=$?
  rm -f "$list"
  [ "$code" != 0 ] || [ -n "$finished" ] || code=1
  exit "$code"
}
trap clean EXIT

# grep exits 1 when no file matches: that is an empty list, not an error.
find "$projects" -name '*.jsonl' -mtime -"$days" -print0 |
  xargs -0 grep -lE '"entrypoint":"(cli|claude-desktop)"' >"$list" || [ $? = 123 ]
transcripts=$(wc -l <"$list" | tr -d ' ')
subagents=$(grep -c '/subagents/' "$list" || true)

# One row per event, in the order of the records: a load of a SKILL.md, a
# compaction, a run of a script, a read of a .md file of a skill, and the
# result of a tool call.
# shellcheck disable=SC2016 # the $ are jq's
program='
def text: if type == "string" then . else [.[]? | .text? // empty] | join("") end;
def skill: "/plugins/cache/[^/]+/(craft|kalinichenko)/[^/]+/skills/(?<skill>[a-z-]+)";
input_filename as $f
| if .type == "system" and .subtype == "compact_boundary" then [$f, "compact"]
  elif .type == "user" and .isMeta == true and .sourceToolUseID != null then
    (.message.content | text) as $t
    | ($t | capture("^Base directory for this skill: [^\n]*" + skill + "\n")) | [$f, "load", .skill, ($t | length)]
  elif .type == "assistant" then
    .message.content[]? | select(.type == "tool_use") | .id as $id
    | ((if .name == "Bash" then .input.command elif .name == "Read" then .input.file_path else null end) // "") as $c
    | ($c | capture(skill)) as $s
    | ($c | [capture("scripts/(?<script>[a-z-]+[.]sh)")][0]) as $run
    | if .name == "Bash" and $run then [$f, "run", $id, $s.skill, $run.script]
      elif ($c | test(skill + "/[^/ ]+[.]md")) then [$f, "read", $id, $s.skill]
      else empty end
  elif .type == "user" then
    .message.content | arrays | .[] | select(.type == "tool_result")
    | [$f, "result", .tool_use_id, (.content | text | length), (.is_error == true)]
  else empty end
| @tsv'

# The files go to jq in the order of the list, so the rows of one transcript
# come together. ponytail: a Bash call that names a .md file of a skill counts
# all its output as that skill's read; parse the command when that misleads.
tr '\n' '\0' <"$list" | xargs -0 jq -r "$program" | awk -F '\t' \
  -v days="$days" -v transcripts="$transcripts" -v subagents="$subagents" '
  $1 != file { file = $1; loaded = "" }
  $2 == "load" {
    k = file SUBSEP $3
    if (!(k in loads)) { contexts[$3]++; loaded = loaded " " $3 }
    else if (loads[k] == 1) twice[$3]++
    loads[k]++; total[$3]++; chars[$3] += $4; context[file] += $4; seen[$3] = 1
  }
  $2 == "compact" {
    n = split(loaded, in_context, " ")
    for (i = 1; i <= n; i++) if (!((file, in_context[i]) in compacted)) { compacted[file, in_context[i]] = 1; compactions[in_context[i]]++ }
  }
  $2 == "run" { run[$3] = $4 "/" $5; runskill[$3] = $4 }
  $2 == "read" { read[$3] = $4 }
  $2 == "result" {
    if ($3 in read) { reads[read[$3]] += $4; seen[read[$3]] = 1 }
    if (($3 in run) && $5 == "true") { failed[runskill[$3]]++; fails[run[$3]]++; seen[runskill[$3]] = 1 }
  }
  # ponytail: an insertion sort, O(n^2) on a few thousand contexts at most.
  function sort(a, n, by,   i, j, t) {
    for (i = 2; i <= n; i++) for (j = i; j > 1 && by[a[j - 1]] + 0 < by[a[j]] + 0; j--) { t = a[j]; a[j] = a[j - 1]; a[j - 1] = t }
  }
  END {
    printf "%s days: %d transcripts, %d of them subagents\n", days, transcripts, subagents
    print "skill\tcontexts\tloads\ttwice\tchars\tcompacted\tread\tfailed"
    n = 0; for (s in seen) names[++n] = s
    # The names first, so that a tie in characters keeps them in order.
    for (i = 2; i <= n; i++) for (j = i; j > 1 && names[j - 1] > names[j]; j--) { t = names[j]; names[j] = names[j - 1]; names[j - 1] = t }
    sort(names, n, chars)
    for (i = 1; i <= n; i++) {
      s = names[i]
      printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", s, contexts[s], total[s], twice[s], chars[s], compactions[s], reads[s], failed[s]
    }
    m = 0; for (c in context) { ids[++m] = c; size[c] = -context[c] }
    sort(ids, m, size)
    if (m == 0) print "SKILL.md characters in a context that loaded one: none"
    else printf "SKILL.md characters in a context that loaded one: median %d, 90th percentile %d, max %d\n",
      context[ids[int((m + 1) / 2)]], context[ids[int((9 * m + 9) / 10)]], context[ids[m]]
    print "script\tfailed"
    k = 0; for (r in fails) scripts[++k] = r
    for (i = 2; i <= k; i++) for (j = i; j > 1 && scripts[j - 1] > scripts[j]; j--) { t = scripts[j]; scripts[j] = scripts[j - 1]; scripts[j - 1] = t }
    sort(scripts, k, fails)
    for (i = 1; i <= k; i++) printf "%s\t%d\n", scripts[i], fails[scripts[i]]
  }'
finished=1
