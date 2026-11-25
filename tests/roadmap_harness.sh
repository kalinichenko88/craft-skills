#!/usr/bin/env bash
# The setup and the helpers that the tests of the roadmap module source; the
# module's row in docs/ARCHITECTURE.md names them. Its name does not end in
# _test.sh, so make test does not run it alone.
#
# It sets root, scripts, fixtures and tmp, removes tmp at exit, and puts a
# fake gh first on PATH. The fake answers from payloads recorded on public
# repositories, filtered through jq as gh's own --jq does, and logs every
# call, so no test reaches GitHub. It defines fail, check, reset, msno, ms,
# mark, node, write_page, put, pages, edit and blocks.

# shellcheck disable=SC2016 # the single-quoted $ are jq's
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC2034 # the tests read scripts
scripts=$root/skills/roadmap/scripts
fixtures=$root/tests/fixtures/roadmap
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/bin" "$tmp/fake"
cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE/calls"
case "$*" in *"${FAKE_FAIL:-no failure asked}"*) echo 'gh: HTTP 502' >&2; exit 1 ;; esac
filter=. a='' b=''
for ((i = 1; i <= $#; i++)); do
  j=$((i + 1))
  case ${!i} in
    --jq) filter=${!j} ;;
    -F | -f) case ${!j} in a=*) a=${!j#a=} ;; b=*) b=${!j#b=} ;; esac ;;
  esac
done
# Each answer comes from $FAKE when the file is there, else from the fixture.
src() { if [ -f "$FAKE/$1" ]; then echo "$FAKE/$1"; else echo "$FIXTURES/$1"; fi; }
# The pages of a paginated read, the filter applied to each, as gh does.
pages() {
  local p
  p=$(ls "$FAKE/$1"-*.json 2>/dev/null || ls "$FIXTURES/$1"-*.json)
  for f in $p; do jq -r "$filter" "$f"; done
}
case "$*" in
  'api graphql'*mutation*) ;;
  'api graphql'*'milestones(states: OPEN'*) pages milestone-counts ;;
  'api graphql'*'issues(states: OPEN'*) pages issues ;;
  'api graphql'*'pullRequests(states: OPEN'*) pages prs ;;
  'api graphql'*'a: issue(number'*)
    jq -nr --arg a "$a" --arg b "$b" '{data: {repository: {a: {id: "I_\($a)"}, b: {id: "I_\($b)"}}}}' | jq -r "$filter" ;;
  'api graphql'*'projectsV2('*) jq -r "$filter" "$(src projects-linked.json)" ;;
  'api graphql'*'views('*) jq -r "$filter" "$(src project-views.json)" ;;
  'api graphql'*'workflows('*) jq -r "$filter" "$(src project-workflows.json)" ;;
  'api -X '*) ;;
  'api repos/{owner}/{repo}/milestones?state=closed'*) jq -r "$filter" "$(src milestones-closed.json)" ;;
  'api repos/{owner}/{repo}/milestones?'*) jq -r "$filter" "$(src milestones.json)" ;;
  'api repos/{owner}/{repo}/milestones/'*)
    jq --argjson n "${2##*/}" '.[] | select(.number == $n)' "$(src milestones.json)" | jq -r "$filter" ;;
  'api repos/{owner}/{repo}/compare/'*) jq -r "$filter" "$(src compare.json)" ;;
  'api repos/{owner}/{repo}/pulls/'*/files*) jq -r "$filter" "$(src pr-files.json)" ;;
  'api repos/{owner}/{repo}'*) jq -r "$filter" "$(src repo.json)" ;;
  'issue view'*)
    if [ -f "$FAKE/body-$3" ]; then jq -Rs '{body: .}' "$FAKE/body-$3"; else echo '{"body": ""}'; fi | jq -r "$filter" ;;
  'issue list'*)
    for f in $(ls "$FAKE"/issues-*.json 2>/dev/null || ls "$FIXTURES"/issues-*.json); do
      jq '.data.repository.issues.nodes' "$f"
    done | jq -s 'add | map({number, url: "https://github.com/kalinichenko88/agent-skills/issues/\(.number)"})' | jq -r "$filter" ;;
  'issue edit'*) ;;
  'project list'*) jq -r "$filter" "$(src project-list.json)" ;;
  'project view'* | 'project create'*) jq -r "$filter" "$(src project-view.json)" ;;
  'project item-list'*) jq -r "$filter" "$(src project-items.json)" ;;
  'project link'* | 'project item-add'*) ;;
  *) echo "fake gh: no answer for: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" FAKE="$tmp/fake" FIXTURES="$fixtures" TMPDIR="$tmp"

fail() {
  printf 'FAIL: %s\n' "$1"
  [ -z "${2:-}" ] || printf '%s\n' "$2"
  exit 1
}
check() { [ "$2" = "$3" ] || fail "$1" "$(printf 'want: %s\ngot:  %s' "$2" "$3")"; }
# Empties the fake's answers, so each case starts from the fixtures.
reset() { find "$FAKE" -mindepth 1 ! -name calls -delete; }
# The recorded number of a milestone: M0 to M5, or Later.
msno() { jq -r --arg m "$1" '.[] | select(.title == $m or (.title | startswith($m + " "))) | .number' "$fixtures/milestones.json"; }
# Changes the milestones that the fake answers with by the jq filter $1.
ms() {
  local f=$FAKE/milestones.json
  [ -f "$f" ] || f=$fixtures/milestones.json
  jq "$@" "$f" >"$FAKE/milestones.next" && mv "$FAKE/milestones.next" "$FAKE/milestones.json"
}
mark() { ms 'map(if .title == $m or (.title | startswith($m + " ")) then .description += "\n\nCurrent." else . end)' --arg m "$1"; }
# The open issues, as one page: put '19 20:M2 21:Later 22:-' makes #19 in M1,
# #20 in M2, #21 in Later and #22 with no milestone. Each is the recorded
# issue, emptied of its labels, people, links and sub-issues.
node='{number: .[0], title: "Issue \(.[0])", milestone: (if .[1] then {number: .[1]} else null end)} as $new
  | $t + $new | .labels.nodes = [] | .assignees.nodes = [] | .linkedBranches.nodes = []
  | .closedByPullRequestsReferences.nodes = [] | .blockedBy.nodes = [] | .parent = null
  | .subIssuesSummary = {total: 0, completed: 0}'
write_page() {
  jq --argjson spec "$2" ".data.repository.issues.nodes[0] as \$t
    | .data.repository.issues.pageInfo.hasNextPage = $3 | .data.repository.issues.nodes = [\$spec[] | $node]" \
    "$fixtures/issues-1.json" >"$FAKE/issues-$1.json"
}
put() {
  local spec='' e n m
  for e in $1; do
    n=${e%%:*} m=M1
    [ "$e" = "$n" ] || m=${e#*:}
    if [ "$m" = - ]; then m=null; else m=$(msno "$m"); fi
    spec="$spec,[$n,$m]"
  done
  rm -f "$FAKE"/issues-*.json
  write_page 1 "[${spec#,}]" false
}
# Issues 1 to $1, all in M1, as pages of 100.
pages() {
  local m p=1 first
  m=$(msno M1)
  rm -f "$FAKE"/issues-*.json
  for ((first = 1; first <= $1; first += 100)); do
    write_page "$p" "$(jq -nc --argjson f "$first" --argjson l "$1" --argjson m "$m" '[range($f; [$f + 100, $l + 1] | min) | [., $m]]')" \
      "$([ $((first + 100)) -le "$1" ] && echo true || echo false)"
    p=$((p + 1))
  done
}
# Changes issue $1 by the jq filter $2, on whichever page it is.
edit() {
  local f
  for f in "$FAKE"/issues-*.json; do
    jq --argjson n "$1" ".data.repository.issues.nodes |= map(if .number == \$n then ($2) else . end)" "$f" >"$f.next"
    mv "$f.next" "$f"
  done
}
# Makes issue $1 blocked by the open issues $2… of this repository.
blocks() {
  local n=$1 m
  shift
  for m in "$@"; do
    edit "$n" ".blockedBy.nodes += [{number: $m, state: \"OPEN\", repository: {nameWithOwner: \"kalinichenko88/agent-skills\"}}]"
  done
}
