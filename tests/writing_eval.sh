#!/usr/bin/env bash
# Asks the model for a text from a recorded input, with the plugin of a given
# ref, and counts the factual claims of each text that no line of the input
# holds. Two cases:
#
# - post (the default): a blog post from the title and description of
#   kalinichenko88/kalinichenko88.github.io#53, a public PR, in
#   tests/fixtures/writing/blog-pr-53.md. On 2026-11-26, with the plugin of
#   049dba0, the last commit with no craft:writing, 10 of 10 posts held such
#   claims, 71 in all (#230).
# - pr: the description of PR #511 of this repository, from its title, the
#   issue that it closes and its diff, in tests/fixtures/writing/pr-511.md.
#
# A judge on Opus counts the claims. Before the texts count, it runs on two
# recorded posts for blog-pr-53.md: judge-positive.md, a post that Opus 5.5
# with no plugin wrote from it on 2026-11-26, must give at least one claim,
# and judge-negative.md, written from the input alone, none.
#
# It prints each run's claims and whether the session loaded craft:writing.
# It exits 1 when the judge fails its check on the two posts, or a run gives
# no text, a text that the judge gives no list for, or a text with a claim
# that no input line holds. tests/writing_checks_test.sh runs its guards with
# a stub claude.
#
# It calls the model, so it costs tokens and is not part of `make check`: run
# it by hand after a change to skills/writing/, with 049dba0 as the control.
# A run sees no plugin of this machine, only the plugin of <ref>.
#
# Usage: [CASE=pr] tests/writing_eval.sh [runs, default 3] [ref, default: this checkout]

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
runs=${1:-3}
ref=${2:-}
case=${CASE:-post}
[ "$#" -le 2 ] && [ "$runs" -ge 1 ] 2>/dev/null || { echo "usage: $0 [runs, at least 1] [ref]" >&2; exit 2; }
fixtures=$root/tests/fixtures/writing
case $case in
  post) input=$fixtures/blog-pr-53.md
    ask='Write a post for my blog from this pull request.' ;;
  pr) input=$fixtures/pr-511.md
    ask='Write the description of the pull request for this change.' ;;
  *) echo "usage: CASE is post or pr, not '$case'" >&2; exit 2 ;;
esac
if [ -n "$ref" ]; then
  git -C "$root" rev-parse --verify -q "$ref^{commit}" >/dev/null || { echo "usage: $0: no commit $ref" >&2; exit 2; }
fi
logs=$(mktemp -d)
plugin=$root
if [ -n "$ref" ]; then
  plugin=$logs/plugin
  mkdir -p "$plugin"
  git -C "$root" archive "$ref" | tar -x -C "$plugin"
fi

# judge <input file> <text file> <out file>: one JSON object,
# {"invented": [...]}, read from the first "{" of the judge's reply.
judge() {
  local prompt
  prompt="Below are the INPUT that a writer had and the TEXT written from it.
List every factual claim of the TEXT that no line of the INPUT states or
directly implies: an event, a number, a name, a property of a thing, a cause,
or an opinion or a feeling given as the author's. A step that the INPUT gives
as still to come and the TEXT tells as done counts too, but not a step or a
measurement that the INPUT gives as done. Do not list wording, order or tone;
a claim in a heading counts. Answer with one JSON object and nothing
else:
{\"invented\": [\"<the claim, quoted from the TEXT>\", ...]}

<INPUT>
$(cat "$1")
</INPUT>

<TEXT>
$(cat "$2")
</TEXT>"
  (cd "$logs" && claude -p --model opus --safe-mode --setting-sources project \
    --tools "" --no-session-persistence --output-format json <<<"$prompt") \
    | jq -r '.result // empty' \
    | awk 'f || /\{/ { if (!f) sub(/^[^{]*/, ""); f = 1; print }' \
    | jq -c -n input >"$3" 2>/dev/null || true
}
# count <file>: the number of claims, or "error" when the file holds no list.
count() { jq -e '.invented | arrays | length' "$1" 2>/dev/null || echo error; }

judge "$fixtures/blog-pr-53.md" "$fixtures/judge-positive.md" "$logs/positive.json"
judge "$fixtures/blog-pr-53.md" "$fixtures/judge-negative.md" "$logs/negative.json"
pos=$(count "$logs/positive.json")
neg=$(count "$logs/negative.json")
echo "== judge: positive $pos, negative $neg"
if [ "$pos" = error ] || [ "$pos" -lt 1 ] || [ "$neg" != 0 ]; then
  echo "$0: the judge failed its check; logs: $logs" >&2
  exit 1
fi

# run <n>: a session in an empty folder, with only the plugin of <ref>. The
# log holds stderr too, so each read of it takes only its JSON lines.
run() {
  mkdir -p "$logs/$1"
  (cd "$logs/$1" && claude -p --model opus --setting-sources project \
    --plugin-dir "$plugin" --dangerously-skip-permissions --no-session-persistence \
    --disallowedTools ListAgents --output-format stream-json --verbose \
    <<<"$ask Put the text between <final> and </final>.

$(cat "$input")") >"$logs/$1.jsonl" 2>&1 || true
  jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$logs/$1.jsonl" \
    | sed -n '/<final>/,/<\/final>/p' | sed '1s/.*<final>//; $s/<\/final>.*//' >"$logs/$1.md"
}

for i in $(seq "$runs"); do run "$i" & done
wait

failed=0
for i in $(seq "$runs"); do
  loaded=no
  jq -rR 'fromjson? | select(.type == "assistant") | .message.content[]?
    | select(.type == "tool_use" and .name == "Skill") | .input.skill' "$logs/$i.jsonl" \
    | grep -qE '^(craft:)?writing$' && loaded=yes
  if [ "$(wc -w <"$logs/$i.md")" -eq 0 ]; then
    echo "== $i: FAIL, no text; skill loaded: $loaded"
    failed=1
    continue
  fi
  judge "$input" "$logs/$i.md" "$logs/$i.json"
  n=$(count "$logs/$i.json")
  if [ "$n" = 0 ]; then verdict=pass
  elif [ "$n" = error ]; then verdict="FAIL, the judge gave no list"; failed=1
  else verdict="FAIL, $n claims with no input line"; failed=1; fi
  echo "== $i: $verdict; skill loaded: $loaded; words: $(wc -w <"$logs/$i.md" | tr -d ' ')"
  jq -r '.invented[]? | "   - " + .' "$logs/$i.json" 2>/dev/null || true
done
echo "Logs: $logs"
exit "$failed"
