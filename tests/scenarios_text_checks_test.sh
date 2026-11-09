#!/usr/bin/env bash
# Runs the checks of tests/scenarios_text_eval.sh on recorded runs, with no
# model. tests/fixtures/scenarios_text/ holds scenarios/github/take-in.md,
# its items, and the answers of ten haiku runs, 2026-11-09: five on
# skills/github/take-in.md at bb69ce3 (base), and five on the same text with
# its lines 32 to 35 and 43 cut (change). The cut lines tell the run to wait
# on a closed task or on another person's work, and to stop on the person's
# pull request and on a task of another repository. The checks give LOST for
# 15 items of those four scenarios, and for no other item. Copies with the
# base's answers on the working tree walk the limits one run at a time, with
# five runs on each side and with four. With a stub claude, the eval refuses
# a wrong call, a file of its list that is missing at the base or in the
# working tree, and runs with no answer; and it gives the base's text and the
# working tree's to the two sides, and the recorded items for the recorded
# scenario file.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fixtures=$root/tests/fixtures/scenarios_text
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "scenarios_text_checks_test: $1" >&2
  [ -z "${2:-}" ] || printf '%s\n' "$2" >&2
  exit 1
}
checks() { "$root/tests/scenarios_text_eval.sh" --check "$1"; }

out=$(checks "$fixtures")
[ "$(sed -n 's/^LOST \([^ ]*\) .*/\1/p' <<<"$out" | tr '\n' ' ')" = '2.T2 2.T3 2.N1 2.N2 2.N3 4.T3 4.N1 4.N2 5.T2 5.T3 5.N1 12.T2 12.T3 12.N1 12.N2 ' ] ||
  fail 'the recorded runs do not lose the 15 items of the cut lines' "$out"
[ "$(tail -n 1 <<<"$out")" = '15 of 83 items lost, 5 runs on the working tree and 5 on the base' ] ||
  fail 'the last line does not count 15 of 83 items in 5 and 5 runs' "$out"

# set_none <file> <id>: the answer of that run on that item becomes none.
set_none() { awk -v id="$2" '$1 == id { $0 = id " none" } 1' "$1" >"$1.new" && mv "$1.new" "$1"; }
# leave_out <file> <id>: that run gives no line for that item.
leave_out() { awk -v id="$2" '$1 != id' "$1" >"$1.new" && mv "$1.new" "$1"; }
# expect <copy> <LOST lines> <why>: the checks on that copy give those LOST
# lines, and no other.
expect() {
  out=$(checks "$tmp/$1")
  [ "$(grep '^LOST' <<<"$out" || true)" = "$2" ] || fail "$3" "$out"
}
gist='LOST 1.T1 A free task: the first message about #91 tells its gist'
for c in five four; do
  cp -R "$fixtures" "$tmp/$c"
  for i in 1 2 3 4 5; do cp "$fixtures/base$i.txt" "$tmp/$c/change$i.txt"; done
done
: >"$tmp/four/change5.txt"
: >"$tmp/four/base5.txt"
# Each step adds to the one before it.
for c in five four; do
  set_none "$tmp/$c/change1.txt" 1.T1
  set_none "$tmp/$c/change2.txt" 1.T1
done
expect five '' 'an item with no line in 2 of 5 runs is lost'
expect four '' 'an item with no line in 2 of 4 runs is lost'
leave_out "$tmp/five/change3.txt" 1.T1
expect five "$gist (no line in 3 of 5 runs, on the base in 0 of 5)" 'an item with no line in 3 of 5 runs, one left out, is not lost'
set_none "$tmp/five/base1.txt" 1.T1
set_none "$tmp/five/base2.txt" 1.T1
expect five "$gist (no line in 3 of 5 runs, on the base in 2 of 5)" 'an item with no line in 2 of 5 runs on the base is not lost'
leave_out "$tmp/five/base3.txt" 1.T1
expect five '' 'an item with no line in 3 of 5 runs on the base is lost'
leave_out "$tmp/four/change3.txt" 1.T1
set_none "$tmp/four/base1.txt" 1.T1
set_none "$tmp/four/base2.txt" 1.T1
expect four "$gist (no line in 3 of 4 runs, on the base in 2 of 4)" 'an item with no line in 3 of 4 runs, and in 2 of 4 on the base, is not lost'

# A stub claude first on PATH answers nothing, and records each call.
mkdir "$tmp/bin"
printf '#!/usr/bin/env bash\ntouch %q\ncat >/dev/null\necho %q\n' "$tmp/called" '{"result": ""}' >"$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
# refused <message> <argument>...: the eval exits 2 with <message> on stderr,
# and calls claude only when the refusal names no answer. The runs folder that
# it names moves to $tmp/logs.
refused() {
  local message=$1 code=0 err want=no got=no logs
  shift
  rm -f "$tmp/called"
  err=$(PATH="$tmp/bin:$PATH" "$evalsh" "$@" 2>&1 >"$tmp/out") || code=$?
  logs=$(sed -n 's/^Runs: //p' "$tmp/out")
  [ -z "$logs" ] || { rm -rf "$tmp/logs" && mv "$logs" "$tmp/logs"; }
  [ "$code" = 2 ] && [ "${err#*"$message"}" != "$err" ] || fail "'$*' exited $code with '$err', not 2 with '$message'"
  [ "$message" != 'no answer' ] || want=yes
  [ ! -e "$tmp/called" ] || got=yes
  [ "$got" = "$want" ] || fail "'$*' called claude: $got, not $want"
}
evalsh=$root/tests/scenarios_text_eval.sh
refused usage: 0
refused usage: 1 HEAD 3
refused 'no commit' 1 no-such-ref
refused 'no answer' 1 HEAD

# A copy of the eval in a repository with the recorded scenario file, and no
# skills/github/scout.md at its first commit.
repo=$tmp/repo
mkdir -p "$repo/tests" "$repo/scenarios/github" "$repo/skills/github"
cp "$root/tests/scenarios_text_eval.sh" "$repo/tests/"
cp "$fixtures/take-in.md" "$repo/scenarios/github/"
cp "$root/skills/github/SKILL.md" "$root/skills/github/take-in.md" "$root/skills/github/tracker.md" "$repo/skills/github/"
# -f, so that a global gitignore cannot drop a file that the test needs.
commit() { git -C "$repo" add -A -f && git -C "$repo" -c user.name=test -c user.email=test@example.com commit -qm "$1"; }
git -C "$repo" init -q
commit 'no scout.md'
cp "$root/skills/github/scout.md" "$repo/skills/github/"
evalsh=$repo/tests/scenarios_text_eval.sh
refused 'skills/github/scout.md is not' 1 HEAD
commit 'add scout.md'
git -C "$repo" update-ref refs/remotes/origin/main HEAD~1
refused 'skills/github/scout.md is not' 1
rm "$repo/skills/github/scout.md"
refused 'skills/github/scout.md is not' 1 HEAD
cp "$root/skills/github/scout.md" "$repo/skills/github/"
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
refused 'no answer' 1 HEAD
diff "$fixtures/items.tsv" "$tmp/logs/items.tsv" >/dev/null || fail 'the items of the recorded scenario file are not the recorded items'
grep -q '^skills/github/take-in\.md:[0-9]*: A line of the working tree only\.$' "$tmp/logs/change.prompt" ||
  fail "the prompt of the working tree lacks the working tree's line"
! grep -q 'A line of the working tree only' "$tmp/logs/base.prompt" || fail "the prompt of the base has the working tree's line"
echo 'scenarios_text_checks_test: ok'
