#!/usr/bin/env bash
# Asks the model for a blog post from the facts and notes of
# tests/fixtures/writing/stars-notes.md, with the plugin of a given ref, and
# counts the factual claims of each post that no line of the input holds.
# The facts come from kalinichenko88/kalinichenko88.github.io#53, a public PR;
# the notes are its author's. On 2026-11-26, plain Opus 5.5 with no plugin
# wrote 3 such claims from this input (#230).
#
# A judge on Opus counts the claims. Before the posts count, it runs on two
# recorded texts: judge-positive.md, that post of 2026-11-26, must give at
# least one claim, and judge-negative.md, written from the input alone, none.
#
# It prints each run's claims and whether the session loaded craft:writing,
# and exits 1 when a post holds a claim with no input line, or the judge fails
# its check.
#
# With VOICE=1, the run's folder holds the CLAUDE.md and VOICE.md of
# tests/fixtures/writing/voice/: a voice of sentences of 25 to 40 words,
# against the short sentences of *Plain technical prose* in rules.md. It
# prints the mean words of a sentence of each post, with no judge, and exits 1
# when a mean is under 20: then rules.md wins over the voice file.
#
# It calls the model, so it costs tokens and is not part of `make check`: run
# it by hand after a change to skills/writing/. A run sees no plugin of this
# machine, only the plugin of <ref>.
#
# Usage: [VOICE=1] tests/writing_eval.sh [runs, default 3] [ref, default: this checkout]

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
runs=${1:-3}
ref=${2:-}
[ "$#" -le 2 ] && [ "$runs" -ge 1 ] 2>/dev/null || { echo "usage: $0 [runs, at least 1] [ref]" >&2; exit 2; }
fixtures=$root/tests/fixtures/writing
logs=$(mktemp -d)
plugin=$root
if [ -n "$ref" ]; then
  plugin=$logs/plugin
  mkdir -p "$plugin"
  git -C "$root" archive "$ref" | tar -x -C "$plugin"
fi
notes=$(cat "$fixtures/stars-notes.md")

# judge <text file> <out file>: one JSON object, {"invented": [...]}.
judge() {
  local prompt
  prompt="Below are the INPUT that a writer had and the TEXT written from it.
List every factual claim of the TEXT that no line of the INPUT states or
directly implies: an event, a number, a name, a property of a thing, a cause,
or an opinion or a feeling given as the author's. Do not list wording, order,
tone or a heading. Answer with one JSON object and nothing else:
{\"invented\": [\"<the claim, quoted from the TEXT>\", ...]}

<INPUT>
$notes
</INPUT>

<TEXT>
$(cat "$1")
</TEXT>"
  (cd "$logs" && claude -p --model opus --safe-mode --setting-sources project \
    --tools "" --no-session-persistence --output-format json <<<"$prompt") \
    | jq -r '.result // empty' | grep -v '^```' | sed -n '/^{/,/^}/p' >"$2" || true
}
count() { jq '.invented | length' "$1" 2>/dev/null || echo error; }

# mean <text file>: the mean words of a sentence, headings left out.
mean() {
  grep -v '^#' "$1" | awk '{ gsub(/[.!?]( |$)/, "&\n"); print }' \
    | awk 'NF { n++; w += NF } END { printf "%d", n ? w / n : 0 }'
}
voice=${VOICE:-}
if [ "$voice" != 1 ]; then
  judge "$fixtures/judge-positive.md" "$logs/positive.json"
  judge "$fixtures/judge-negative.md" "$logs/negative.json"
  pos=$(count "$logs/positive.json")
  neg=$(count "$logs/negative.json")
  echo "== judge: positive $pos, negative $neg"
  if [ "$pos" = error ] || [ "$pos" -lt 1 ] || [ "$neg" != 0 ]; then
    echo "$0: the judge failed its check; logs: $logs" >&2
    exit 1
  fi
fi

# run <n>: a session in an empty folder, with only the plugin of <ref>.
run() {
  mkdir -p "$logs/$1"
  [ "$voice" != 1 ] || cp "$fixtures/voice/CLAUDE.md" "$fixtures/voice/VOICE.md" "$logs/$1/"
  (cd "$logs/$1" && claude -p --model opus --setting-sources project \
    --plugin-dir "$plugin" --dangerously-skip-permissions --no-session-persistence \
    --disallowedTools ListAgents --output-format stream-json --verbose \
    <<<"Write an English post for my blog from these facts and notes. Put the post between <final> and </final>.

$notes") >"$logs/$1.jsonl" 2>&1 || true
  jq -r 'select(.type == "result") | .result // empty' "$logs/$1.jsonl" 2>/dev/null \
    | sed -n '/<final>/,/<\/final>/p' | sed '1s/.*<final>//; $s/<\/final>.*//' >"$logs/$1.md"
}

for i in $(seq "$runs"); do run "$i" & done
wait

failed=0
for i in $(seq "$runs"); do
  loaded=no
  grep -q '"skill":"craft:writing"' "$logs/$i.jsonl" && loaded=yes
  if [ ! -s "$logs/$i.md" ]; then
    echo "== $i: FAIL, no post; skill loaded: $loaded"
    failed=1
    continue
  fi
  if [ "$voice" = 1 ]; then
    m=$(mean "$logs/$i.md")
    if [ "$m" -ge 20 ]; then verdict=pass; else verdict=FAIL; failed=1; fi
    echo "== $i: $verdict, $m words a sentence; skill loaded: $loaded"
    continue
  fi
  judge "$logs/$i.md" "$logs/$i.json"
  n=$(count "$logs/$i.json")
  if [ "$n" = 0 ]; then verdict=pass; else verdict="FAIL, $n claims with no input line"; failed=1; fi
  echo "== $i: $verdict; skill loaded: $loaded; words: $(wc -w <"$logs/$i.md" | tr -d ' ')"
  jq -r '.invented[]? | "   - " + .' "$logs/$i.json" 2>/dev/null || true
done
echo "Logs: $logs"
exit "$failed"
