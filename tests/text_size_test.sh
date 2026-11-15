#!/usr/bin/env bash
# Each text that an agent reads in a run has a recorded size in
# tests/text_size.txt, in characters as jq counts them: rules.md, each
# SKILL.md, each side file (a .md file under skills/, but not a SKILL.md or
# a README.md), and each flow, the sum of the files that its line names. A text
# whose size is not its recorded size fails, so a pull request that changes
# one changes its line, and the review sees each growth (ADR 0009). A text
# below its record fails too: else it can grow back with no line in a diff.
# First checks the counter on small trees, then the repository.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() { printf 'FAIL: %s\n%s\n' "$1" "$2"; exit 1; }
check() { [ "$2" = "$3" ] || fail "$1" "want: $2
got:  $3"; }

# sizes <tree>: each fault of <tree>/tests/text_size.txt against the texts of
# <tree>, one per line. A line of the record is "<characters> <path>" or
# "<characters> flow <name> <path>...".
sizes() {
  local tree=$1 record=$1/tests/text_size.txt size kind rest name sum f path
  [ -f "$record" ] || { echo 'tests/text_size.txt does not exist'; return; }
  while read -r size kind rest || [ -n "$size" ]; do
    case $size in '' | '#'*) continue ;; esac
    if [ "$kind" = flow ]; then
      name=${rest%% *}
      sum=0
      for f in ${rest#* }; do
        [ -f "$tree/$f" ] || {
          echo "the flow $name names $f, which does not exist"
          continue 2
        }
        sum=$((sum + $(jq -Rs length "$tree/$f")))
      done
      [ "$sum" -eq "$size" ] ||
        echo "the flow $name has $sum characters, and its line says $size"
    elif [ ! -f "$tree/$kind" ]; then
      echo "$kind has a line, but does not exist"
    else
      sum=$(jq -Rs length "$tree/$kind")
      [ "$sum" -eq "$size" ] ||
        echo "$kind has $sum characters, and its line says $size"
    fi
  done <"$record"
  { echo "$tree/rules.md"; find "$tree/skills" -name '*.md' ! -name README.md | sort; } |
    while read -r f; do
      path=${f#"$tree/"}
      awk -v p="$path" '$1 !~ /^#/ && $2 == p { found = 1 } END { exit !found }' "$record" ||
        echo "$path has no line"
    done
}

# tree <record line>...: a small tree with these lines as its record.
tree() {
  rm -rf "$tmp/t"
  mkdir -p "$tmp/t/tests" "$tmp/t/skills/a"
  printf '12345\n' >"$tmp/t/rules.md"
  printf '1234567\n' >"$tmp/t/skills/a/SKILL.md"
  printf 'ééé\n' >"$tmp/t/skills/a/side.md"
  printf 'for a person\n' >"$tmp/t/skills/a/README.md"
  printf '%s\n' '# characters, then a path or a flow' "$@" >"$tmp/t/tests/text_size.txt"
}

# side.md has 4 characters in 7 bytes, and README.md needs no line.
tree '6 rules.md' '8 skills/a/SKILL.md' '4 skills/a/side.md' '18 flow all rules.md skills/a/SKILL.md skills/a/side.md'
check 'each text at its recorded size' '' "$(sizes "$tmp/t")"

tree '6 rules.md' '80 skills/a/SKILL.md' '4 skills/a/side.md' '15 flow all rules.md skills/a/SKILL.md'
check 'a text and a flow below their recorded sizes' 'skills/a/SKILL.md has 8 characters, and its line says 80
the flow all has 14 characters, and its line says 15' "$(sizes "$tmp/t")"

tree '6 rules.md' '7 skills/a/SKILL.md' '4 skills/a/side.md'
check 'a SKILL.md that grew' 'skills/a/SKILL.md has 8 characters, and its line says 7' "$(sizes "$tmp/t")"

tree '5 rules.md' '8 skills/a/SKILL.md' '3 skills/a/side.md'
check 'rules.md and a side file that grew' 'rules.md has 6 characters, and its line says 5
skills/a/side.md has 4 characters, and its line says 3' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md' '4 skills/a/side.md' '13 flow all rules.md skills/a/SKILL.md'
check 'a flow that grew' 'the flow all has 14 characters, and its line says 13' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md'
check 'a side file with no line' 'skills/a/side.md has no line' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md' '4 skills/a/side.md' '9 skills/a/gone.md' '20 flow all rules.md skills/a/gone.md'
check 'a line for a file that is gone' 'skills/a/gone.md has a line, but does not exist
the flow all names skills/a/gone.md, which does not exist' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md' '# 4 skills/a/side.md'
check 'a side file whose line is a comment' 'skills/a/side.md has no line' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md' '4 skills/a/side.md'
mkdir "$tmp/t/skills/a/deep"
echo 'text' >"$tmp/t/skills/a/deep/more.md"
check 'a text in a folder of a skill' 'skills/a/deep/more.md has no line' "$(sizes "$tmp/t")"

tree '6 rules.md' '8 skills/a/SKILL.md'
printf '3 skills/a/side.md' >>"$tmp/t/tests/text_size.txt"
check 'a last line with no newline' 'skills/a/side.md has 4 characters, and its line says 3' "$(sizes "$tmp/t")"

faults=$(sizes "$root")
[ -z "$faults" ] || fail 'tests/text_size.txt does not hold the texts' "$faults
A text that changes gets its new number on its line, in the same pull request (ADR 0009)."

echo 'text_size_test: ok'
