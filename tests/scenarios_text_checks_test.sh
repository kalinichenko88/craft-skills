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
# five runs on each side and with four: most runs on the working tree, and at
# most a fifth on the base. A second set of runs in again/ keeps an item LOST
# only when it loses the item too, on both sides. With a stub claude, the eval
# gives a second set only to a row with a LOST item, and a second set with no
# answer stops it with the reason of that set. It refuses a wrong call, a
# scenario file with no row, in this tree too, a file of a
# row that is missing in the working tree, also in a later row before any
# run, and runs with no answer; and it gives the base's text and the working
# tree's to the two sides, no line of a file that the base does not have, the
# recorded items for the recorded scenario file, and the scenario file of the
# row in its output. With --changed, it runs only the rows with a skill file
# that differs from the base, committed, changed or untracked, and none when
# no skill file does; with no answer, it prints the reason of the first run.
# It runs the rows side by side, and gives their reports in the order of the
# rows.

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
expect five "$gist (no line in 3 of 5 runs, on the base in 1 of 5)" 'an item with no line in 1 of 5 runs on the base is not lost'
leave_out "$tmp/five/base2.txt" 1.T1
expect five '' 'an item with no line in 2 of 5 runs on the base is lost'
leave_out "$tmp/four/change3.txt" 1.T1
expect four "$gist (no line in 3 of 4 runs, on the base in 0 of 4)" 'an item with no line in 3 of 4 runs is not lost'
set_none "$tmp/four/base1.txt" 1.T1
expect four '' 'an item with no line in 1 of 4 runs on the base is lost'
# Each side counts its own runs: 5 on the working tree and 4 on the base.
cp -R "$fixtures" "$tmp/uneven"
for i in 1 2 3 4 5; do cp "$fixtures/base$i.txt" "$tmp/uneven/change$i.txt"; done
: >"$tmp/uneven/base5.txt"
for i in 1 2 3; do set_none "$tmp/uneven/change$i.txt" 1.T1; done
expect uneven "$gist (no line in 3 of 5 runs, on the base in 0 of 4)" 'an item with no line in 3 of 5 runs, and in 0 of 4 on the base, is not lost'
set_none "$tmp/uneven/base1.txt" 1.T1
expect uneven '' 'an item with no line in 1 of 4 runs on the base, and 3 of 5 on the working tree, is lost'

# A second set of runs in again/ (#328): an item is LOST only when each set
# loses it, on both sides, with the counts of both. The recorded runs as the
# second set lose the items of the cut lines, but not one that its base gives
# no line for in 2 of 5 runs, and the base's answers on the working tree lose
# none. An item that only the second set loses is not LOST, and each set
# counts its own runs.
cp -R "$fixtures" "$tmp/twice"
cp -R "$fixtures" "$tmp/twice/again"
set_none "$tmp/twice/again/base1.txt" 2.T2
set_none "$tmp/twice/again/base2.txt" 2.T2
out=$(checks "$tmp/twice")
[ "$(sed -n 's/^LOST \([^ ]*\) .*/\1/p' <<<"$out" | tr '\n' ' ')" = '2.T3 2.N1 2.N2 2.N3 4.T3 4.N1 4.N2 5.T2 5.T3 5.N1 12.T2 12.T3 12.N1 12.N2 ' ] ||
  fail 'an item with no line in 2 of 5 runs on the base of the second set is lost' "$out"
for i in 1 2 3 4 5; do cp "$fixtures/base$i.txt" "$tmp/twice/again/change$i.txt"; done
expect twice '' 'an item that the second set does not lose is lost'
mkdir -p "$tmp/later/again"
cp "$fixtures/items.tsv" "$tmp/later/"
for i in 1 2 3 4 5; do
  for d in later later/again; do
    cp "$fixtures/base$i.txt" "$tmp/$d/base$i.txt"
    cp "$fixtures/base$i.txt" "$tmp/$d/change$i.txt"
  done
  set_none "$tmp/later/again/change$i.txt" 1.T1
done
expect later '' 'an item that only the second set loses is lost'
for i in 1 2 3; do set_none "$tmp/later/change$i.txt" 1.T1; done
expect later "$gist (no line in 8 of 10 runs, on the base in 0 of 10)" 'an item that both sets lose is not lost, or its counts are not the sums'
cp "$fixtures/base3.txt" "$tmp/later/again/change3.txt"
cp "$fixtures/base4.txt" "$tmp/later/again/change4.txt"
: >"$tmp/later/again/change5.txt"
expect later '' 'an item with no line in 2 of the 4 runs of the second set is lost'

# A stub claude first on PATH answers with an error, as the CLI with no login
# does, and records each call.
mkdir "$tmp/bin"
printf '#!/usr/bin/env bash\ntouch %q\ncat >/dev/null\necho %q\n' "$tmp/called" '{"is_error": true, "usage": {}, "result": "Not logged in"}' >"$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
# refused <message> <argument>...: the eval exits 2 with <message> on stderr,
# and calls claude only when the refusal names no answer. The runs folder that
# it names moves to $tmp/logs.
refused() {
  local message=$1 code=0 err want=no got=no logs
  shift
  rm -f "$tmp/called"
  err=$(PATH="$tmp/bin:$PATH" "$evalsh" "$@" 2>&1 >"$tmp/out") || code=$?
  printf '%s\n' "$err" >"$tmp/err"
  # A group of rows gives a runs folder for each row: the first one stays.
  sed -n 's/^Runs: //p' "$tmp/out" >"$tmp/runs"
  logs=$(head -n 1 "$tmp/runs")
  [ -z "$logs" ] || { rm -rf "$tmp/logs" && mv "$logs" "$tmp/logs"; }
  tail -n +2 "$tmp/runs" | while read -r d; do rm -rf "$d"; done
  [ "$code" = 2 ] && [ "${err#*"$message"}" != "$err" ] || fail "'$*' exited $code with '$err', not 2 with '$message'"
  [ "$message" != 'no answer' ] || want=yes
  [ ! -e "$tmp/called" ] || got=yes
  [ "$got" = "$want" ] || fail "'$*' called claude: $got, not $want"
}
evalsh=$root/tests/scenarios_text_eval.sh
refused usage: 0
refused usage: 1 HEAD 3
refused 'no commit' 1 no-such-ref
# Every row of this tree, so a scenario file here with no row fails here. The
# rows run five at a time, and a group with no answer stops the eval after
# its five reports.
refused 'no answer' 1 HEAD
[ "$(grep -c '' "$tmp/runs")" = 5 ] || fail 'the first group with no answer does not stop the eval after its five rows' "$(cat "$tmp/out")"

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

# --changed, on copies whose second row shares a skill file with the take-in
# row, runs each row with a skill file that differs from the base, and no
# other: no row with no change, nor with a change of a scenario file alone,
# which both sides read from the working tree; the take-in row alone for a
# committed change against the default base, as in CI; both rows for a change
# of the shared file; and the row of an untracked skill file. A run with no
# answer prints the reason of the first run: .result of the CLI's JSON, or
# else the start of its output.
git -C "$repo" checkout -q -- skills/github/take-in.md
mkdir "$repo/scenarios/none"
cp "$fixtures/take-in.md" "$repo/scenarios/none/none.md"
with_row "  'scenarios/none/none.md skills/github/take-in.md'"
# no_row <state>: in that state, --changed runs no row and calls no claude.
no_row() {
  rm -f "$tmp/called"
  out=$(PATH="$tmp/bin:$PATH" "$evalsh" --changed 1 HEAD) || fail "--changed with $1 exited $?" "$out"
  [ "$out" = 'No skill file of a row differs from HEAD.' ] || fail "--changed with $1 does not say that no skill file differs" "$out"
  [ ! -e "$tmp/called" ] || fail "--changed with $1 called claude"
}
# changed_rows <scenario file>...: the rows that the last call named.
changed_rows() { grep -qxF "Changed rows: $*" "$tmp/out" || fail "--changed did not run the rows of $*" "$(cat "$tmp/out")"; }
no_row 'no change'
echo 'A line of the working tree only.' >>"$repo/$take"
no_row 'a change of a scenario file alone'
git -C "$repo" checkout -q -- "$take"
# The default base is the first commit, and HEAD adds scout.md.
refused 'no answer' --changed 1
changed_rows "$take"
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
refused 'no answer' --changed 1 HEAD
changed_rows "$take" scenarios/none/none.md
grep -qxF "$evalsh: the first run printed: Not logged in" "$tmp/err" || fail 'a run with no answer does not print .result of the first run' "$(cat "$tmp/err")"
git -C "$repo" checkout -q -- skills/github/take-in.md
echo 'A line of an untracked file.' >"$repo/skills/github/new.md"
with_row "  'scenarios/none/none.md skills/github/new.md'"
# A CLI that prints no JSON, as for an option that it does not know.
printf '#!/usr/bin/env bash\ntouch %q\ncat >/dev/null\necho %q\n' "$tmp/called" 'error: unknown option' >"$tmp/bin/claude"
refused 'no answer' --changed 1 HEAD
changed_rows scenarios/none/none.md
grep -qxF "$evalsh: the first run printed: error: unknown option" "$tmp/err" || fail 'a run with no answer does not print the output of a CLI that prints no JSON' "$(cat "$tmp/err")"

# A stub claude that gives each item a line, and none when the prompt has the
# line of the working tree only. A row with no LOST item gets one set of runs;
# a row with one gets a second set in again/, and both sets count. With a
# file limit beside it, each call after the first two ends in an error.
cat >"$tmp/bin/claude" <<'EOF'
#!/usr/bin/env bash
d=$(dirname "$0")
echo >>"$d/calls"
if [ -e "$d/limit" ] && [ "$(grep -c '' "$d/calls")" -gt 2 ]; then
  echo '{"is_error": true, "result": "Limit reached"}'
  exit 1
fi
p=$(cat)
a='x:1 "y"'
case $p in *'A line of the working tree only.'*) a=none ;; esac
awk -v a="$a" '/^=== The items/ { f = 1; next } /^=== / { f = 0 } f && NF { print $1, a }' <<<"$p" | jq -Rs '{result: .}'
EOF
# sets <calls> <last line> <why>: the take-in row makes that many calls, in
# one set or in two, and its output ends with that line.
sets() {
  rm -f "$tmp/bin/calls"
  out=$(PATH="$tmp/bin:$PATH" "$evalsh" "$take" 1 HEAD) || fail "the eval with a stub that answers exited $?" "$out"
  logs=$(sed -n 's/^Runs: //p' <<<"$out")
  [ "$(grep -c '' "$tmp/bin/calls")" = "$1" ] && [ "$(tail -n 1 <<<"$out")" = "$2" ] || fail "$3" "$out"
  [ "$1" = 2 ] || [ -s "$logs/again/change1.txt" ] || fail 'the second set is not in again/' "$out"
  rm -rf "$logs"
}
sets 2 '0 of 83 items lost, 1 runs on the working tree and 1 on the base' 'a row with no LOST item gets a second set'
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
sets 4 '83 of 83 items lost, 2 runs on the working tree and 2 on the base' 'a row with a LOST item gets no second set'
touch "$tmp/bin/limit"
rm -f "$tmp/bin/calls"
code=0
PATH="$tmp/bin:$PATH" "$evalsh" "$take" 1 HEAD >"$tmp/out" 2>"$tmp/err" || code=$?
rm -rf "$(sed -n 's/^Runs: //p' "$tmp/out")"
[ "$code" = 2 ] || fail "a second set with no answer exited $code, not 2" "$(cat "$tmp/err")"
grep -qxF "$evalsh: the first run printed: Limit reached" "$tmp/err" ||
  fail 'a second set with no answer does not print the reason of its first run' "$(cat "$tmp/err")"

# --changed runs the rows side by side (#392): a stub run of one row waits for
# a run of the other row, so rows one after another get no answer. The
# reports come in the order of the rows.
rm -f "$tmp/bin/limit" "$tmp/bin/calls"
# The line of the row of none is on both sides, so each run of a row knows
# its row; then a line of each row's file is new on the working tree.
echo 'A line of the row of none.' >>"$repo/skills/github/new.md"
commit 'the row of none'
echo 'A line of the working tree only.' >>"$repo/skills/github/take-in.md"
echo 'A line of the working tree only.' >>"$repo/skills/github/new.md"
cat >"$tmp/bin/claude" <<'EOF'
#!/usr/bin/env bash
d=$(dirname "$0")
p=$(cat)
case $p in *'A line of the row of none.'*) mine=none other=take ;; *) mine=take other=none ;; esac
touch "$d/$mine"
for _ in $(seq 150); do [ ! -e "$d/$other" ] || break; sleep 0.2; done
[ -e "$d/$other" ] || { echo '{"is_error": true, "result": "the other row did not run"}'; exit 1; }
awk '/^=== The items/ { f = 1; next } /^=== / { f = 0 } f && NF { print $1, "x:1 \"y\"" }' <<<"$p" | jq -Rs '{result: .}'
EOF
out=$(PATH="$tmp/bin:$PATH" "$evalsh" --changed 1 HEAD 2>&1) || fail "--changed with two rows exited $?" "$out"
[ "$(sed -n 's/^Scenario: //p' <<<"$out" | tr '\n' ' ')" = "$take scenarios/none/none.md " ] ||
  fail 'the rows do not run side by side, or their reports are not in the order of the rows' "$out"
sed -n 's/^Runs: //p' <<<"$out" | while read -r d; do rm -rf "$d"; done
echo 'scenarios_text_checks_test: ok'
