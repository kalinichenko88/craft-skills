#!/usr/bin/env bash
# The setup and the helpers that the tests of the architecture skill's
# invariants.sh source: tests/architecture_scripts_test.sh,
# tests/architecture_since_test.sh and tests/architecture_fences_test.sh. Its
# name does not end in _test.sh, so make test does not run it alone.
#
# It sets root, inv and tmp, removes tmp at exit, and defines fail, check,
# new_repo, commit and run.

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# A person's color.ui=always or grep.column=true must not reach what the
# script reads from git; they go after any configuration the environment
# already gives git.
n=${GIT_CONFIG_COUNT:-0}
export "GIT_CONFIG_KEY_$n=color.ui" "GIT_CONFIG_VALUE_$n=always" \
  "GIT_CONFIG_KEY_$((n + 1))=grep.column" "GIT_CONFIG_VALUE_$((n + 1))=true" GIT_CONFIG_COUNT=$((n + 2))
inv=$root/skills/architecture/scripts/invariants.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
check() { [ "$2" = "$3" ] || fail "$1" "$(printf 'want: %s\ngot:  %s' "$2" "$3")"; }

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q -b main
  git -C "$1" config user.name test
  git -C "$1" config user.email test@example.com
}
# -f, so that a global gitignore cannot drop a file the test needs.
commit() { git -C "$1" add -A -f && git -C "$1" commit -qm "$2"; }
# run <dir> [arg...]: runs invariants.sh in <dir>, and sets code, out and err.
# shellcheck disable=SC2034 # the tests read code, out and err
run() {
  local dir=$1
  shift
  code=0
  out=$(cd "$dir" && bash "$inv" "$@" 2>"$tmp/err") || code=$?
  err=$(cat "$tmp/err")
}
