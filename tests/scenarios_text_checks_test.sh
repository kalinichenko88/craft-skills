#!/usr/bin/env bash
# Runs the checks of tests/scenarios_text_eval.sh on recorded runs, with no
# model. tests/fixtures/scenarios_text/ holds the items of
# scenarios/github/take-in.md and the answers of ten haiku runs, 2026-11-09:
# five on skills/github/take-in.md at bb69ce3 (base), and five on the same
# text with its lines 32 to 35 and 43 cut (change). The cut lines tell the run
# to wait on a closed task or on another person's work, and to stop on the
# person's pull request and on a task of another repository. The checks give
# LOST for 15 items of those four scenarios, and for no other item. A copy
# with the base's answers on the working tree loses nothing; an item that 2
# of 5 runs answer none is not lost, and one that a third run leaves out is.
# The eval refuses a wrong call, a file of its list that is missing at the
# base or in the working tree, and runs with no answer.

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
cp -R "$fixtures" "$tmp/same"
for i in 1 2 3 4 5; do cp "$fixtures/base$i.txt" "$tmp/same/change$i.txt"; done
out=$(checks "$tmp/same")
[ "$out" = '0 of 83 items lost, 5 runs on the working tree and 5 on the base' ] ||
  fail "the base's answers on the working tree lose an item" "$out"
set_none "$tmp/same/change1.txt" 1.T1
set_none "$tmp/same/change2.txt" 1.T1
out=$(checks "$tmp/same")
! grep -q '^LOST' <<<"$out" || fail 'an item that 2 of 5 runs answer none is lost' "$out"
leave_out "$tmp/same/change3.txt" 1.T1
out=$(checks "$tmp/same")
[ "$(grep '^LOST' <<<"$out")" = 'LOST 1.T1 A free task: the first message about #91 tells its gist (no line in 3 of 5 runs, on the base in 0 of 5)' ] ||
  fail 'an item that 2 of 5 runs answer none and 1 leaves out is not lost' "$out"
for i in 1 2 3; do set_none "$tmp/same/base$i.txt" 1.T1; done
out=$(checks "$tmp/same")
! grep -q '^LOST' <<<"$out" || fail 'an item that most runs on the base answer none is lost' "$out"

# A stub claude first on PATH answers nothing, and records each call.
mkdir "$tmp/bin"
printf '#!/usr/bin/env bash\ntouch %q\ncat >/dev/null\necho %q\n' "$tmp/called" '{"result": ""}' >"$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
# refused <message> <argument>...: the eval exits 2 with <message> on stderr,
# and calls claude only when the refusal names no answer.
refused() {
  local message=$1 code=0 err want=no got=no
  shift
  rm -f "$tmp/called"
  err=$(PATH="$tmp/bin:$PATH" TMPDIR="$tmp" "$evalsh" "$@" 2>&1 >/dev/null) || code=$?
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

# A copy of the eval in a repository with no skills/github/scout.md at the
# base, then with none in the working tree: each stops before a paid run.
repo=$tmp/repo
mkdir -p "$repo/tests" "$repo/scenarios/github" "$repo/skills/github"
cp "$root/tests/scenarios_text_eval.sh" "$repo/tests/"
cp "$root/scenarios/github/take-in.md" "$repo/scenarios/github/"
cp "$root/skills/github/SKILL.md" "$root/skills/github/take-in.md" "$root/skills/github/tracker.md" "$repo/skills/github/"
commit() { git -C "$repo" add -A && git -C "$repo" -c user.name=test -c user.email=test@example.com commit -qm "$1"; }
git -C "$repo" init -q
commit 'no scout.md'
cp "$root/skills/github/scout.md" "$repo/skills/github/"
evalsh=$repo/tests/scenarios_text_eval.sh
refused 'skills/github/scout.md is not' 1 HEAD
commit 'add scout.md'
rm "$repo/skills/github/scout.md"
refused 'skills/github/scout.md is not' 1 HEAD
echo 'scenarios_text_checks_test: ok'
