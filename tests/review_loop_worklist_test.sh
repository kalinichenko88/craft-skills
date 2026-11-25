#!/usr/bin/env bash
# Runs the review-loop skill's worklist.sh on ranges that the test builds.
# Each place that a range removes or replaces is one item of the list. A place
# that only adds lines is none, and neither is a file of data.

# shellcheck disable=SC2016 # the backticks are Markdown's
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/review-loop/scripts/worklist.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
check() { [ "$2" = "$3" ] || fail "$1" "$(printf 'want: %s\ngot:  %s' "$2" "$3")"; }
# ci <repo> <message>: commits the whole tree and prints the commit.
ci() {
  git -C "$1" add -A
  git -C "$1" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "$2"
  git -C "$1" rev-parse HEAD
}
# list <repo> <arg>...: the list, as a reader runs it from the tree.
list() { (cd "$1" && shift && bash "$script" "$@"); }

repo=$tmp/repo
git init -q -b main "$repo"
empty=$(ci "$repo" empty)
mkdir -p "$repo/vendor" "$repo/sub/fixtures"
printf 'one\nold line\nthree\n' >"$repo/a.sh"
printf 'x = 1\ny = 2\nz = 3\n' >"$repo/b.py"
{
  echo top
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do echo "o$i"; done
  echo end
} >"$repo/long.sh"
echo '# doc' >"$repo/c.md"
echo '{"v": 1}' >"$repo/package-lock.json"
echo v1 >"$repo/vendor/lib.sh"
echo f1 >"$repo/sub/fixtures/f.sh"
printf -- '-- old note\nselect 1;\n' >"$repo/q.sql"
echo 'echo old' >"$repo/é.sh"
printf 'r1\nr2\nr3\nr4\nr5\nr6\nr7\nr8\nr9\nr10\n' >"$repo/r.sh"
base=$(ci "$repo" base)

printf 'one\nnew line\nthree\n' >"$repo/a.sh"
rm "$repo/b.py"
{
  echo top
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do echo "n$i"; done
  echo end
} >"$repo/long.sh"
echo '# doc, changed' >"$repo/c.md"
echo '{"v": 2}' >"$repo/package-lock.json"
echo v2 >"$repo/vendor/lib.sh"
echo f2 >"$repo/sub/fixtures/f.sh"
echo 'echo added' >"$repo/d.sh"
head=$(ci "$repo" head)

printf -- '-- new note\nselect 1;\n' >"$repo/q.sql"
echo 'echo new' >"$repo/é.sh"
git -C "$repo" mv r.sh moved.sh
printf 'r1\nr2\nr3\nr4\nfive\nr6\nr7\nr8\nr9\nr10\n' >"$repo/moved.sh"
head2=$(ci "$repo" head2)

out=$(list "$repo" "$base" "$head")
check 'a replaced line, a deleted file and a long replaced block are three items' 3 \
  "$(printf '%s\n' "$out" | grep -c '^[0-9][0-9]*\. ')"
check 'an item is its place, the old lines and the new lines' \
  "$(printf '1. `a.sh:2`\n   old:\n       old line\n   new:\n       new line')" \
  "$(printf '%s\n' "$out" | sed -n 1,5p)"
check 'a deleted file is one item with its count of lines' \
  "$(printf '2. `b.py:1`\n   The whole file is deleted (3 lines).')" \
  "$(printf '%s\n' "$out" | sed -n 6,7p)"
check 'the third item is the block of long.sh' '3. `long.sh:2`' "$(printf '%s\n' "$out" | sed -n 8p)"
check 'an item shows 12 lines of each side, and says how many more there are' 2 \
  "$(printf '%s\n' "$out" | grep -c '^       \.\.\. 2 more lines$')"
check 'the lines past the twelfth are not shown' 'n12 o12' \
  "$(printf '%s\n' "$out" | sed -n 's/^       \([on]1[234]\)$/\1/p' | sort | tr '\n' ' ' | sed 's/ $//')"
check 'a document, a lock file, a vendored file, a fixture and a file that the range adds are on no item' '' \
  "$(printf '%s\n' "$out" | grep -E 'c\.md|package-lock|vendor|fixtures|d\.sh' || true)"

# The person's git config must not change the list: a prefix setting changes
# the header lines, a colour puts an escape before each @@, and an external
# diff tool prints its own format.
for conf in diff.noprefix=true diff.mnemonicPrefix=true color.ui=always diff.external=false; do
  git -C "$repo" config "${conf%%=*}" "${conf#*=}"
  check "the list is the same with $conf in the git config" "$out" "$(list "$repo" "$base" "$head" 2>&1)"
  git -C "$repo" config --unset "${conf%%=*}"
done

# A moved file is its changed line, not a deleted file. A removed line that
# starts with "-- " is a line, and no header of a file. A name with a letter
# outside ASCII shows as it is. Both hold against the git config too.
git -C "$repo" config core.quotePath true
git -C "$repo" config diff.renames false
check 'a moved file, a removed line that starts with "-- ", and a name with a letter outside ASCII' \
  "$(printf '1. `moved.sh:5`\n   old:\n       r5\n   new:\n       five\n2. `q.sql:1`\n   old:\n       -- old note\n   new:\n       -- new note\n3. `é.sh:1`\n   old:\n       echo old\n   new:\n       echo new')" \
  "$(list "$repo" "$head" "$head2")"
git -C "$repo" config --unset core.quotePath
git -C "$repo" config --unset diff.renames

code=0
out=$(list "$repo" "$empty" "$base" 2>&1) || code=$?
check 'a range that only adds files exits 0' 0 "$code"
check 'a range that only adds files gives an empty list' '' "$out"

# 400 replaced places are more than the list holds.
big=$tmp/big
git init -q -b main "$big"
i=1
while [ "$i" -le 400 ]; do
  echo "the old line of file $i, which is long enough to fill the list of the reader" >"$big/f$i.sh"
  i=$((i + 1))
done
b1=$(ci "$big" old)
i=1
while [ "$i" -le 400 ]; do
  echo "the new line of file $i, which is long enough to fill the list of the reader" >"$big/f$i.sh"
  i=$((i + 1))
done
b2=$(ci "$big" new)
out=$(list "$big" "$b1" "$b2")
[ "${#out}" -le 24000 ] || fail 'a list of 400 places has at most 24,000 characters' "it has ${#out}"
last=$(printf '%s\n' "$out" | tail -1)
printf '%s\n' "$last" | grep -qE '^\.\.\. [0-9][0-9]* more places, not listed$' ||
  fail 'the last line of a cut list says how many places it left out' "$last"
check 'the items and the places left out are the 400 places' 400 \
  "$(($(printf '%s\n' "$out" | grep -c '^[0-9][0-9]*\. ') + $(printf '%s' "$last" | tr -cd 0-9)))"

code=0
list "$repo" "$base" >"$tmp/out" 2>"$tmp/err" || code=$?
check 'one argument is a usage error' 2 "$code"
grep -qxF 'usage: worklist.sh <base> <head>' "$tmp/err" ||
  fail 'the usage error prints the usage line' "$(cat "$tmp/err")"
code=0
list "$repo" nosuch "$head" >"$tmp/out" 2>"$tmp/err" || code=$?
check 'a base that is no commit is a wrong call' 2 "$code"
check 'a wrong call prints no list' '' "$(cat "$tmp/out")"

echo 'review_loop_worklist_test: ok'
