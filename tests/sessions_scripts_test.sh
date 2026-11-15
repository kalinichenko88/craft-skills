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
# superpowers load count nothing. No hook gave rules.md, so no rule counts.
none="rule	contexts	kept	share	subagents	kept	share
github before a gh write	0	0	-	0	0	-
github before a gh call	0	0	-	0	0	-
typescript-conventions before a TypeScript edit	0	0	-	0	0	-
react-conventions before a React edit	0	0	-	0	0	-
review-loop before a review	0	0	-	0	0	-
take-in.md before take-in-check.sh	0	0	-	0	0	-
merge.md before gh pr merge	0	0	-	0	0	-
filing.md before a new issue or add-finding.sh	0	0	-	0	0	-"
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

# The rules. r1 has each rule's text before its first moment: the github
# load, take-in.md by Read, filing.md through a variable that holds the
# skills folder before add-finding.sh, merge.md from a checkout under another
# skills folder before a gh --repo=<repo> merge, the
# conventions loaded or read as the architecture lens does, and review-loop.
# Its first gh write is older than the days, so the next one counts; a gh
# read before the load is a moment of the gh call only. r2 has each first
# moment before the text, or another file than the rule's: a code-reviewer
# subagent, gh pr create after a read of another github skill, take-in.md
# after the check in the same call, tracker.md for filing.md, c.ts before
# the load and useCart.ts with no react-conventions. Its github SKILL.md
# names no merge.md, so its merge is no moment. Its subagent has a
# TypeScript edit after the load and a gh write with none; a review and a gh
# call in a subagent are no moment. r3 reads with gh after the load, then
# merges with -R before merge.md and runs add-finding.sh before filing.md.
# n1 has moments but no rules.md.
cp -R "$root/tests/fixtures/sessions/rules" "$tmp/"
expected="rule	contexts	kept	share	subagents	kept	share
github before a gh write	3	2	67%	1	0	0%
github before a gh call	3	1	33%	0	0	-
typescript-conventions before a TypeScript edit	2	1	50%	1	1	100%
react-conventions before a React edit	2	1	50%	0	0	-
review-loop before a review	2	1	50%	0	0	-
take-in.md before take-in-check.sh	2	1	50%	0	0	-
merge.md before gh pr merge	2	1	50%	0	0	-
filing.md before a new issue or add-finding.sh	3	1	33%	0	0	-"
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
