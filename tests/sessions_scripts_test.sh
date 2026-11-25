#!/usr/bin/env bash
# Runs count.sh of the sessions skill on built transcripts in the shape of
# Claude Code's records: a session with its subagent, a claude -p run and an
# old session, which it must leave out.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
count=$root/.claude/skills/sessions/scripts/count.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cp -R "$root/tests/fixtures/sessions/projects" "$tmp/"
touch -t 200001010000 "$tmp/projects/-home-u-proj/old.jsonl"

# github: two loads of 147 characters (149 bytes), one before the compaction;
# 43 + 27 + 17 characters of take-in.md, tracker.md and filing.md, the first
# by a sed with a quoted | and a head after it, the last after a cd; 74 of a
# call that reads SKILL.md and runs a script of no skill, without the line
# with the exit code; and 17 of filing.md through a variable that holds the
# skills folder. Failed: collect.sh through a variable, through
# xargs and with a $(...) argument, add-finding.sh with an .md argument and
# bash -x, which is no read, and worktree.sh, the last of two scripts.
# roadmap: a load that the person typed as a command, and four failed
# scripts: read.sh after a cat of SKILL.md, plan.sh in a for loop with a
# redirection after done, board.sh run by its path, and next.sh,
# whose whole path is in a variable. debt: clones.sh under timeout. A grep
# that quotes a run, roadmap.sh before a tail and a failed gh call, a diff and
# a cat that only name a script, a call with .mdx, the failed call of the
# checkout's copy, a call that the worktree refused before it ran and the
# superpowers load count nothing. No hook gave rules.md, and the records
# have no time, so no rule counts: each rule of rules.json has a row of 0.
none="rule	contexts	kept	share	subagents	kept	share
$(jq -r '.[] | .rule + "\t0\t0\t-\t0\t0\t-"' "$root/.claude/skills/sessions/scripts/rules.json")"
expected="14 days: 2 transcripts, 1 of them subagents
skill	contexts	loads	twice	chars	compacted	read	failed
github	1	2	1	294	1	178	5
roadmap	1	1	0	124	0	0	4
review-loop	1	1	0	122	0	0	0
debt	0	0	0	0	0	0	1
SKILL.md characters in a context that loaded one: median 122, 90th percentile 418, max 418
script	failed
github/collect.sh	3
debt/clones.sh	1
github/add-finding.sh	1
github/worktree.sh	1
roadmap/board.sh	1
roadmap/next.sh	1
roadmap/plan.sh	1
roadmap/read.sh	1
$none"
actual=$(bash "$count" 14 "$tmp/projects")
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed:"
  echo "$actual"
  exit 1
}

# macOS xargs exits 1, not 123, when one grep finds nothing. A fake runs one
# file per grep, as many batches do, with that exit code.
mkdir "$tmp/bin"
# shellcheck disable=SC2016 # the fake expands them
printf '#!/usr/bin/env bash\n%s -n 1 "$@" || { s=$?; [ $s = 123 ] && exit 1; exit $s; }\n' \
  "$(command -v xargs)" >"$tmp/bin/xargs"
chmod +x "$tmp/bin/xargs"
actual=$(PATH="$tmp/bin:$PATH" bash "$count" 14 "$tmp/projects") || true
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed with a grep that finds nothing in its batch:"
  echo "$actual"
  exit 1
}

# Each moment of rules.json on its samples in moments.tsv: the rule, its key,
# a command or a path as count.jq gives it, and 1 for a moment. A sample of
# no rule or no key, and a rule with no sample, fail too.
bad=$(jq -nrR --slurpfile rules "$root/.claude/skills/sessions/scripts/rules.json" '
  [inputs | split("\t")] as $rows
  | ($rows[] as [$r, $k, $s, $want]
      | ([$rules[0][] | select(.rule == $r) | .[$k] // empty] | first) as $e
      | if $e == null then "\($r): no rule with the key \($k)"
        else (if $s | test($e) then "1" else "0" end) as $got | select($got != $want) | "\($r): \($s) gives \($got)" end),
    ($rules[0][].rule | select(. as $r | any($rows[]; .[0] == $r) | not) | "\(.): no sample")' \
  "$root/tests/fixtures/sessions/moments.tsv")
[ -z "$bad" ] || {
  echo "FAIL: a moment of rules.json on its samples:"
  echo "$bad"
  exit 1
}

# Each read form of count.jq on its samples in reads.tsv: a Bash command, and
# the rule texts that it shows, or none.
scripts=$root/.claude/skills/sessions/scripts
jq -cR 'split("\t")[0] as $c | {type: "assistant", timestamp: "2999-01-01T00:00:00Z",
  message: {id: ($c | @base64), content: [{type: "tool_use", id: ($c | @base64), name: "Bash", input: {command: $c}}]}}' \
  "$root/tests/fixtures/sessions/reads.tsv" >"$tmp/reads.jsonl"
bad=$(jq -r --slurpfile rules "$scripts/rules.json" -f "$scripts/count.jq" "$tmp/reads.jsonl" |
  awk -F '\t' '$2 == "trace" { print $4 "\t" $3 }' |
  jq -nrR --slurpfile rules "$scripts/rules.json" --rawfile want "$root/tests/fixtures/sessions/reads.tsv" '
    ([inputs | split("\t")] | group_by(.[0])
      | map({key: .[0][0], value: ([.[][1] | tonumber | $rules[0][. - 1].text] | unique | join(","))}) | from_entries) as $got
    | $want | split("\n")[] | select(. != "") | split("\t") as [$c, $w]
    | ($got[$c | @base64] // "") as $g | select($g != ($w // "")) | "\($c) shows \($g), not \($w // "")"')
[ -z "$bad" ] || {
  echo "FAIL: a read form of count.jq on its samples:"
  echo "$bad"
  exit 1
}

# The rules. r1 has each rule's text before its first moment, in the result
# of a call of an earlier message: the github load, take-in.md by Read,
# filing.md through a variable that holds the skills folder before
# add-finding.sh, merge.md by an awk with > in its program, from a checkout
# under another skills folder, before a gh --repo=<repo> merge,
# typescript-conventions loaded, react-conventions by a sed into grep -i,
# and review-loop.
# Its first gh write is older than the days, and its first take-in-check.sh
# comes before the github SKILL.md that states its rule, so the next ones
# count. r2 has each first moment before the text, or the text in another
# file or in the same call: a code-reviewer subagent, gh pr create after a
# read of another github skill, take-in.md read in the call of the check,
# tracker.md for filing.md, c.ts before the load and use-cart.ts with no
# react-conventions. Its github SKILL.md names no merge.md, so its merge is
# no moment. Its subagent has a TypeScript edit after the load, and a gh api
# write with a field before the github load; a review and a gh call in a
# subagent are no moment. r3 loads github in the message of a gh read, a
# moment of the gh call only, then reads merge.md in the message of a gh -R
# merge: each result comes before the next call, as in Claude Code. r4 reads
# with gh api --hostname <host> graphql, no write, before the github load
# and a gh write, and sends a reader with security-lens.md with no load of
# review-loop. n1 has moments but no rules.md.
cp -R "$root/tests/fixtures/sessions/rules" "$tmp/"
expected="rule	contexts	kept	share	subagents	kept	share
github before a gh write	4	3	75%	1	0	0%
github before a gh call	4	1	25%	0	0	-
typescript-conventions before a TypeScript edit	2	1	50%	1	1	100%
react-conventions before a React edit	2	1	50%	0	0	-
review-loop before a review	3	1	33%	0	0	-
take-in.md before take-in-check.sh	2	1	50%	0	0	-
merge.md before gh pr merge	2	1	50%	0	0	-
filing.md before a new issue or add-finding.sh	2	1	50%	0	0	-"
actual=$(bash "$count" 14 "$tmp/rules" | sed -n '/^rule	/,$p')
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed for the rules:"
  echo "$actual"
  exit 1
}

mkdir "$tmp/empty"
expected="14 days: 0 transcripts, 0 of them subagents
skill	contexts	loads	twice	chars	compacted	read	failed
SKILL.md characters in a context that loaded one: none
script	failed
$none"
actual=$(bash "$count" 14 "$tmp/empty")
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed for no transcript:"
  echo "$actual"
  exit 1
}

echo "sessions_scripts_test: ok"
