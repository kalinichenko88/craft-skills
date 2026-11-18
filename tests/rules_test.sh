#!/usr/bin/env bash
# The hook hand-escapes rules.md into JSON. Both Claude Code and Codex drop
# context that does not parse, so the real file must come back byte for byte.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1"; exit 1; }

# Git for Windows checks out with core.autocrlf=true by default. bash reads a CR
# as part of the command, so that checkout must keep LF too: the hook, and every
# script the skills run.
crlf=$(mktemp -d)
trap 'rm -rf "$crlf"' EXIT
git -C "$root" -c core.autocrlf=true checkout-index -a --prefix="$crlf/"
if grep -rIl $'\r' "$crlf"; then
  fail "a core.autocrlf=true checkout has CRLF in the files above"
fi
# A clone made before .gitattributes keeps rules.md in CRLF: an update rewrites
# only the files it changes. The hook must still give the rules.
cp "$root/hooks/rules.sh" "$crlf/hooks/"
sed 's/$/\r/' "$root/rules.md" >"$crlf/rules.md"
for part in 1 2; do
  [ "$("$crlf/hooks/rules.sh" SessionStart $part)" = "$("$root/hooks/rules.sh" SessionStart $part)" ] || fail "the hook does not give part $part of the rules from a CRLF rules.md"
done
# NixOS has no /bin/bash: every script must find bash on PATH.
for script in $(git -C "$root" ls-files '*.sh'); do
  [ "$(head -1 "$root/$script")" = '#!/usr/bin/env bash' ] || fail "$script: the shebang must be #!/usr/bin/env bash"
done
# Each script prints its usage from the call lines of its header (ADR 0001).
# shellcheck disable=SC2016 # the line as the scripts hold it
usage='sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2'
for script in $(git -C "$root" ls-files 'skills/*/scripts/*.sh' '.claude/skills/*/scripts/*.sh'); do
  if ! grep -qF "$usage" "$root/$script" || ! grep -q "^#   ${script##*/}" "$root/$script"; then
    fail "$script: usage must print the '#   ${script##*/}' lines of its header"
  fi
done

# hooks.json runs the hook once per part, and each part is one context. The
# two parts and the marker line between them rebuild rules.md (ADR 0004).
marker=$(grep '^<!-- rules.sh splits' "$root/rules.md") || fail "rules.md has no marker line where rules.sh splits it"
if "$root/hooks/rules.sh" SessionStart >/dev/null 2>&1; then
  fail "the hook with no part gives output, not an error"
fi
for event in SessionStart SubagentStart; do
  for part in 1 2; do
    output=$("$root/hooks/rules.sh" "$event" $part </dev/null)
    [ "$(jq -r .hookSpecificOutput.hookEventName <<<"$output")" = "$event" ] || fail "$event $part: wrong hookEventName"
    # Claude Code moves additionalContext over 10,000 characters to a file and
    # shows only a 2,000-character preview.
    chars=$(jq -r '.hookSpecificOutput.additionalContext | length' <<<"$output")
    [ "$chars" -le 10000 ] || fail "$event $part: context is $chars characters, the cap is 10000"
    jq -r .hookSpecificOutput.additionalContext <<<"$output" >"$crlf/part$part"
    # Each part is read on its own, after another plugin's context too.
    [ "$(head -1 "$crlf/part$part")" = "# Global instructions, part $part of 2" ] || fail "$event $part: the part does not start with its own heading"
  done
  diff <(printf '%s\n\n%s\n\n%s\n' "$(<"$crlf/part1")" "$marker" "$(<"$crlf/part2")") \
    "$root/rules.md" || fail "$event: the two parts and the marker line differ from rules.md"
  # hooks.json runs both parts under each event, from one group, so one
  # matcher gives both. The path is quoted: the plugin root can hold a space.
  cmds=$(jq -r --arg e "$event" '[.hooks[$e][] | [.hooks[].command |
    select(test("rules\\.sh"))] | select(length > 0)] |
    if length == 1 then .[0][] else "rules.sh in \(length) groups" end' \
    "$root/hooks/hooks.json" | sort | tr '\n' ',')
  # shellcheck disable=SC2016 # the variable as hooks.json holds it
  want=$(printf '"${CLAUDE_PLUGIN_ROOT}/hooks/rules.sh" %s %s,' "$event" 1 "$event" 2)
  [ "$cmds" = "$want" ] || fail "hooks.json: $event runs '$cmds', not '$want'"
done
# A fix outside the task goes into its PR or into an issue by one scope: the
# task's module. Each place that draws that line names the module, and none
# keeps the three tests without it (#103).
for f in rules.md skills/github/filing.md skills/github/take-in.md \
  skills/github/SKILL.md skills/github/README.md; do
  text=$(tr -s '[:space:]' ' ' <"$root/$f")
  grep -qE "(same|task's) module" <<<"$text" || fail "$f: a fix goes into the task's PR with no module scope"
  if grep -qi 'small, safe' <<<"$text"; then
    fail "$f: a fix goes into the PR by size and safety alone, with no module"
  fi
done
# Sentences that must stay, word for word: tests/rules_pins.txt lists each
# one with its reason. bash 3.2 reads no line from a missing file, and goes on.
[ -f "$root/tests/rules_pins.txt" ] || fail "tests/rules_pins.txt does not exist"
while IFS='|' read -r f phrase || [ -n "$f" ]; do
  case $f in '' | '#'*) continue ;; esac
  [ -n "$phrase" ] || fail "tests/rules_pins.txt: the line '$f' has no '|<phrase>'"
  sed 's/^#//' "$root/$f" | tr -s '[:space:]' ' ' | grep -qF "$phrase" || fail "$f: no \"$phrase\""
done <"$root/tests/rules_pins.txt"
# After a compaction Claude Code attaches each skill again, but counts 4
# characters a token against 5,000 tokens: it cuts the text past 20,000
# characters (ADR 0006). A file on the debt list waits for its split, and
# must not grow past its size there. A path that is gone leaves the list.
# A line of the list is '<path> <characters> <issue>'.
debt=''
for f in "$root"/skills/*/SKILL.md; do
  path=${f#"$root/"}
  chars=$(jq -Rs length "$f")
  cap=$(awk -v p="$path" '$1 == p { print $2 }' <<<"$debt")
  if [ -z "$cap" ]; then
    [ "$chars" -le 20000 ] || fail "$path has $chars characters, past the cap of 20000 (ADR 0006)"
  elif [ "$chars" -le 20000 ]; then
    fail "$path has $chars characters, within the cap of 20000: take it off the debt list"
  elif [ "$chars" -gt "$cap" ]; then
    fail "$path has $chars characters, past its $cap on the debt list"
  fi
done
while read -r path _; do
  [ -z "$path" ] || [ -f "$root/$path" ] || fail "$path is on the debt list of the SKILL.md cap, but does not exist"
done <<<"$debt"

echo 'rules_test: ok'
