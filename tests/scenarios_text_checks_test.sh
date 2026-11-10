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
# a wrong call, a scenario file with no row, in this tree too, a file of a
# row that is missing in the working tree, also in a later row before any
# run, and runs with no answer; and it gives the base's text and the working
# tree's to the two sides, no line of a file that the base does not have, the
# recorded items for the recorded scenario file, and the scenario file of the
# row in its output. With --changed, it runs only the rows with a file that
# differs from the base, also an untracked one, and none when no file does.

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
# Every row of this tree, so a scenario file here with no row fails here.
refused 'no answer' 1 HEAD

# A copy of the eval in a repository with the recorded scenario file, and no
# skills/github/scout.md at its first commit. Each call names the take-in
# row, or runs a copy with no row of another flow, so a row of another flow
# does not need its files here.
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
take=scenarios/github/take-in.md
commit 'add scout.md'
git -C "$repo" update-ref refs/remotes/origin/main HEAD~1
# The default base is the merge base, which has no scout.md: the base side
# gets no line of it, and the working tree's side does.
refused 'no answer' "$take" 1
! grep -q '^skills/github/scout\.md:' "$tmp/logs/base.prompt" || fail 'the base side has lines of a file that the base does not have'
grep -q '^skills/github/scout\.md:' "$tmp/logs/change.prompt" || fail "the working tree's side lacks the lines of a new file"
rm "$repo/skills/github/scout.md"
refused 'skills/github/scout.md is not in the working tree' "$take" 1 HEAD
cp "$root/skills/github/scout.md" "$repo/skills/github/"
mkdir "$repo/scenarios/none"
cp "$fixtures/take-in.md" "$repo/scenarios/none/none.md"
refused 'scenarios/none/none.md has no row' "$take" 1 HEAD
# with_row <row>: the copy of the eval gets that row after the take-in row,
# in place of the other rows.
with_row() {
  awk -v rows="  'scenarios/" -v after="  'scenarios/github/take-in.md " -v row="$1" \
    'index($0, rows) == 1 && index($0, after) != 1 { next } 1; index($0, after) == 1 { print row }' "$root/tests/scenarios_text_eval.sh" >"$evalsh"
}
# With a file that is missing in a second row, the eval runs every row, and a
# fault in a later row stops it before any run.
with_row "  'scenarios/none/none.md skills/none/none.md'"
refused 'skills/none/none.md is not' 1 HEAD
cp "$root/tests/scenarios_text_eval.sh" "$repo/tests/"
rm -r "$repo/scenarios/none"
refused 'scenarios/github/none.md has no row' scenarios/github/none.md 1 HEAD
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
refused 'no answer' "./$take" 1 HEAD
grep -qx "Scenario: $take" "$tmp/out" || fail 'the output does not name the scenario file of the row' "$(cat "$tmp/out")"
diff "$fixtures/items.tsv" "$tmp/logs/items.tsv" >/dev/null || fail 'the items of the recorded scenario file are not the recorded items'
grep -q '^skills/github/take-in\.md:[0-9]*: A line of the working tree only\.$' "$tmp/logs/change.prompt" ||
  fail "the prompt of the working tree lacks the working tree's line"
! grep -q 'A line of the working tree only' "$tmp/logs/base.prompt" || fail "the prompt of the base has the working tree's line"

# --changed runs each row with a file that differs from the base, and no
# other: no row with no change, the take-in row alone for a change of its
# scenario file, each row of a shared file, so also the row of the worth
# flow, whose files are not here, and the row of an untracked file.
git -C "$repo" checkout -q -- skills/github/take-in.md
rm -f "$tmp/called"
out=$(PATH="$tmp/bin:$PATH" "$evalsh" --changed 1 HEAD) || fail "--changed with no change exited $?" "$out"
[ "$out" = 'No file of a row differs from HEAD.' ] || fail '--changed with no change does not say that no file differs' "$out"
[ ! -e "$tmp/called" ] || fail '--changed with no change called claude'
# changed_rows <scenario file>...: the rows that the last call named.
changed_rows() { grep -qx "Changed rows: $*" "$tmp/out" || fail "--changed did not run the rows of $*" "$(cat "$tmp/out")"; }
echo 'A line of the working tree only.' >>"$repo/$take"
refused 'no answer' --changed 1 HEAD
changed_rows "$take"
git -C "$repo" checkout -q -- "$take"
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
refused 'rules.md is not in the working tree: the row of scenarios/product/worth.md' --changed 1 HEAD
changed_rows "$take" scenarios/product/worth.md
git -C "$repo" checkout -q -- skills/github/take-in.md
mkdir "$repo/scenarios/none"
cp "$fixtures/take-in.md" "$repo/scenarios/none/none.md"
with_row "  'scenarios/none/none.md skills/github/SKILL.md'"
refused 'no answer' --changed 1 HEAD
changed_rows scenarios/none/none.md
echo 'scenarios_text_checks_test: ok'
