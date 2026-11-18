#!/usr/bin/env bash
# The setup and the helpers that the tests of the github module source; the
# module's row in docs/ARCHITECTURE.md names them. Its name does not end in
# _test.sh, so make test does not run it alone.
#
# It sets root, scripts, fixtures and tmp, removes tmp at exit, and puts a
# fake gh first on PATH. The fake answers from payloads recorded on this
# repository, filtered through jq as gh's own --jq does, and logs every call,
# so no test reaches GitHub. It defines fail, check, answer, writes and stops.

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scripts=$root/skills/github/scripts
fixtures=$root/tests/fixtures/github
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/bin"
cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE/calls"
case "$*" in *"${FAKE_FAIL:-no failure asked}"*) echo 'gh: HTTP 502' >&2; exit 1 ;; esac
filter=. search='' repo=''
for ((i = 1; i <= $#; i++)); do
  j=$((i + 1))
  case ${!i} in --jq) filter=${!j} ;; --search) search=${!j} ;; --repo) repo=${!j} ;; --silent) exec >/dev/null ;; esac
done
# A list answers from issues-<search>.json or prs-<search>.json, and the open
# issues from open-issues.json, in $FAKE first. As GitHub's search, which does
# not follow a rename, a search finds nothing without the resolved --repo.
list() {
  local f=$1-$search.json
  [ -n "$search" ] || f=open-issues.json
  [ -z "$search" ] || [ "$repo" = kalinichenko88/agent-skills ] || f=none
  if [ -f "$FAKE/$f" ]; then f=$FAKE/$f; else f=$FIXTURES/$f; fi
  if [ -f "$f" ]; then jq -r "$filter" "$f"; else echo '[]' | jq -r "$filter"; fi
}
case "$1 $2" in
  'api repos/{owner}/{repo}') echo kalinichenko88/agent-skills ;;
  'api user') echo kalinichenko88 ;;
  'api graphql')
    # As GitHub, only the issues that the query asks for.
    asked=$(grep -oE 'n[0-9]+: issueOrPullRequest' <<<"$*" | cut -d: -f1 | jq -Rsc 'split("\n") - [""]')
    jq --argjson asked "$asked" 'if $asked == [] then . else
      .data.repository |= with_entries(select(.key as $k | any($asked[]; . == $k))) end' \
      "$FAKE/graphql.json" | jq -r "$filter"
    # graphql.next.json, when there, answers from the next call on.
    [ ! -f "$FAKE/graphql.next.json" ] || mv "$FAKE/graphql.next.json" "$FAKE/graphql.json" ;;
  'issue list') list issues ;;
  'pr list') list prs ;;
  'issue view')
    jq ".data.repository.n$3 | {body, assignees: [.assignees.nodes[]?]}" "$FAKE/graphql.json" | jq -r "$filter" ;;
  'issue edit') while [ $# -gt 0 ] && [ "$1" != --body-file ]; do shift; done; [ $# = 0 ] || cp "$2" "$FAKE/body" ;;
  'label list') if [ -f "$FAKE/labels.json" ]; then jq -r "$filter" "$FAKE/labels.json"; fi ;;
  'issue comment') ;;
  'issue develop')
    case $3 in
      --list) cat "$FAKE/linked" 2>/dev/null || true ;;
      --help) echo '      --worktree path        Check out the branch into a worktree at the given path' ;;
    esac ;;
  'repo view') echo '{"defaultBranchRef":{"name":"trunk"}}' | jq -r "$filter" ;;
  *) echo "fake gh: no answer for: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" FAKE="$tmp" FIXTURES="$fixtures" TMPDIR="$tmp"

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
check() { [ "$2" = "$3" ] || fail "$1" "$(printf 'want: %s\ngot:  %s' "$2" "$3")"; }
# Sets the GraphQL answer: issues and PRs #4 to #10 as recorded, with #5, or
# the path $2, changed by the jq filter $1.
answer() { jq "${2:-.data.repository.n5} |= ($1)" "$fixtures/${3:-tracker.json}" >"$tmp/graphql.json"; }
writes() { grep -E '^issue (edit|comment)|^issue develop [0-9]+ --name' "$tmp/calls" || true; }

# bash 3.2 runs an EXIT trap with $? at 0 when set -u stops a script. stops
# <script> <n> <args> copies the scripts, puts a stop after the n-th line that
# sets an EXIT trap in that script, and runs the copy with a finished from the
# environment. Two stops: an unbound variable, the case itself, and an exit 0,
# which gives the trap the $? of 0 of bash 3.2 on any bash. Each must exit
# non-zero, show that it reached the stop, and leave nothing in TMPDIR.
stops() {
  local script=$1 at=$2 stop mark before out
  shift 2
  for stop in unbound exit; do
    rm -rf "$tmp/stopped"
    cp -R "$scripts" "$tmp/stopped"
    awk -v at="$at" -v stop="$stop" '{ print } !/^[ \t]*#/ && /trap .* EXIT/ && ++n == at {
      print (stop == "exit" ? "echo stop-after-trap; exit 0" : ": \"$unbound_after_trap\"") }' \
      "$scripts/$script" >"$tmp/stopped/$script"
    mark='stop-after-trap'
    [ "$stop" = exit ] || mark='unbound_after_trap: unbound variable'
    before=$(ls -A "$tmp")
    out=$(finished=1 bash "$tmp/stopped/$script" "$@" 2>&1) && fail "$script $at exits 0 after its $stop stop" "$out"
    case $out in *"$mark"*) ;; *) fail "$script $at stops before its $stop stop" "$out" ;; esac
    check "$script $at leaves nothing in TMPDIR after its $stop stop" "$before" "$(ls -A "$tmp")"
  done
}
