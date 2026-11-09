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
# 43 + 27 + 17 characters of take-in.md, tracker.md and filing.md, the last
# after a cd, 11 of a call that reads SKILL.md and runs a roadmap script, and
# 13 of one that reads SKILL.md and runs a script of no skill. Failed: collect.sh
# through a variable and through xargs, add-finding.sh with an .md argument
# and bash -x, which is no read, and worktree.sh, the last of two scripts.
# roadmap: a load that the person typed as a command, 11 characters of a grep
# that quotes a run, and four failed scripts: read.sh in that call, plan.sh,
# board.sh run by its path, and next.sh, whose whole path is in a variable.
# debt: clones.sh under timeout. A diff that only names a script, a call with
# .mdx, the failed call of the checkout's copy and the superpowers load count
# nothing.
expected="14 days: 2 transcripts, 1 of them subagents
skill	contexts	loads	twice	chars	compacted	read	failed
github	1	2	1	294	1	111	4
roadmap	1	1	0	124	0	11	4
review-loop	1	1	0	122	0	0	0
debt	0	0	0	0	0	0	1
SKILL.md characters in a context that loaded one: median 122, 90th percentile 418, max 418
script	failed
github/collect.sh	2
debt/clones.sh	1
github/add-finding.sh	1
github/worktree.sh	1
roadmap/board.sh	1
roadmap/next.sh	1
roadmap/plan.sh	1
roadmap/read.sh	1"
actual=$(bash "$count" 14 "$tmp/projects")
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed:"
  echo "$actual"
  exit 1
}

mkdir "$tmp/empty"
expected="14 days: 0 transcripts, 0 of them subagents
skill	contexts	loads	twice	chars	compacted	read	failed
SKILL.md characters in a context that loaded one: none
script	failed"
actual=$(bash "$count" 14 "$tmp/empty")
[ "$actual" = "$expected" ] || {
  echo "FAIL: count.sh printed for no transcript:"
  echo "$actual"
  exit 1
}

echo "sessions_scripts_test: ok"
