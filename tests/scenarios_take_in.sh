#!/usr/bin/env bash
# The cases of tests/scenarios_eval.sh, one for each scenario of
# scenarios/github/take-in.md that a case runs: the Given of each case, as a
# tracker in JSON and a workspace with a bare origin, the record of a run, and
# the checks of the Then and Never items of its scenario. The eval runs it so:
#
#   scenarios_take_in.sh cases
#   scenarios_take_in.sh not_run
#   scenarios_take_in.sh setup <dir> <case>
#   scenarios_take_in.sh record <dir>
#   scenarios_take_in.sh check <dir> <case>
#
# Needs bash, jq, git and awk.

# shellcheck disable=SC2016 # Markdown's backticks, and jq and checks run later
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
# cases: one line for each case, with its name, the cap of one of its runs in
# dollars, and the message of the person. A case that goes on into the work
# after the take-in has the higher cap.
cases() { printf '%s\n' 'free 4 #91' 'other 2 #91' 'down 2 #91' 'dup 4 #91' 'busy 4 #91'; }
# The scenarios of take-in that no case runs yet (#237, #239).
# tests/scenarios_checks_test.sh fails for a heading of the file that is
# neither a case nor in this list, and for a name here that is no heading.
not_run() {
  printf '%s\n' "A closed task" "A task with another person's pull request" "A task with the person's pull request" \
    "A task assigned to the person, with no branch" "The work on the person's task continues here" \
    "The work on the person's task runs somewhere else" "A linked branch with no assignee" \
    "The person's work is in the workspace" "The person's branch moved on somewhere else" "A task of another repository"
}

title='README: the install command says npm instal'
body='The README tells the reader to run `npm instal shop`. npm has no instal command, so the command fails. Done when the README says `npm install shop`.'
me=kim other=rivera
# #95, the duplicate: the same report in other words. In the case of a free
# duplicate, its text has a stack trace that #91 does not have.
title95='Installing shop by the README leaves the app without the module'
body95='I followed README.md to install shop, and the package did not install: the command there is `npm instal shop`, with one l.'
trace="Error: Cannot find module 'shop'
Require stack:
- /home/lee/app/index.js
    at Module._resolveFilename (node:internal/modules/cjs/loader:1225:15)
    at Module._load (node:internal/modules/cjs/loader:1051:27)
    at Module.require (node:internal/modules/cjs/loader:1311:19)
    at require (node:internal/modules/helpers:179:18)
    at Object.<anonymous> (/home/lee/app/index.js:1:14)"

# setup <dir> <case>: the workspace <dir>, its origin <dir>.origin, the
# tracker <dir>.state.json, and the fake gh in <dir>.bin.
setup() {
  local w=$1
  git init -q --bare -b main "$w.origin"
  git init -q -b main "$w"
  git -C "$w" config user.name "$me"
  git -C "$w" config user.email "$me@example.com"
  printf '# shop\n\nInstall it with `npm instal shop`.\n' >"$w/README.md"
  git -C "$w" add README.md
  git -C "$w" commit -qm 'docs: add the README'
  git -C "$w" remote add origin "$w.origin"
  git -C "$w" push -q -u origin main
  jq -n --arg case "$2" --arg me "$me" --arg other "$other" --arg origin "$w.origin" \
    --arg w "$w" --arg title "$title" --arg body "$body" --arg title95 "$title95" --arg body95 "$body95" --arg trace "$trace" '
    def task($n; $t; $b; $who): {number: $n, title: $t, body: $b, state: "OPEN", stateReason: null,
      assignees: $who, labels: [], comments: [], linked: []};
    {me: $me, repo: "acme/shop", origin: $origin, workspace: $w, down: ($case == "down"), prs: [],
      labels: ["bug", "debt", "enhancement"], visibility: "PUBLIC",
      issues: ([task(91; $title; $body; if $case == "other" then [$other] else [] end)]
        + if $case == "dup" then [task(95; $title95; $body95 + "\n\nThen my app failed:\n\n```\n" + $trace + "\n```"; [])]
          elif $case == "busy" then [task(95; $title95; $body95; [$other])] else [] end)}' >"$w.state.json"
  mkdir "$w.bin"
  printf '#!/usr/bin/env bash\nexec bash %q %q "$@"\n' "$root/tests/fake_gh.sh" "$w.state.json" >"$w.bin/gh"
  chmod +x "$w.bin/gh"
}

# record <dir>: <dir>.events holds the messages to the person, as text lines,
# the session's thinking that has words, as think lines, and each tool call of
# the session and its subagents, as its tool's name, or sub and the name, and
# its command, path or skill. Some messages that come before a tool call are
# text lines. Another one can reach the log only as a think line, in other
# words, without the task's id and title (#206), with
# --include-partial-messages too. Paths of this machine become <craft>,
# <work> and <tmp>. <dir>.branches holds the origin's branches, each one that
# is not made from main marked so. <dir>.workspace
# holds the changed files, the local branches, the worktrees, the branch of
# HEAD, the commits on main and the stash entries of the workspace. Each line
# of a command becomes one part of a line, after "; ".
record() {
  jq -r 'select(.type == "assistant") | (if .parent_tool_use_id then "sub" else "" end) as $sub
    | .message.content[]
    | if .type == "text" and $sub == "" then "text\t" + (.text | gsub("\n"; " "))
      elif .type == "thinking" and $sub == "" and (.thinking // "" | test("[a-z]")) then "think\t" + (.thinking | gsub("\n"; " "))
      elif .type == "tool_use" then $sub + .name + "\t"
        + ((.input.command // .input.file_path // .input.skill // .input.description // "") | tostring | gsub("\n"; "; "))
      else empty end' "$1.jsonl" |
    awk -v r="$root" -v w="$1" -v t="${TMPDIR:-/tmp}" '{ gsub(r, "<craft>"); gsub("(/private)?" w, "<work>")
      gsub("(/private)?" t, "<tmp>/"); gsub("<tmp>//", "<tmp>/"); print }' >"$1.events"
  git -C "$1.origin" for-each-ref --format='%(refname:short)' refs/heads | while read -r b; do
    if git -C "$1.origin" merge-base --is-ancestor main "$b"; then echo "$b"; else echo "$b, not from main"; fi
  done >"$1.branches"
  { git -C "$1" status --porcelain
    git -C "$1" for-each-ref --format='%(refname:short)' refs/heads
    echo "worktrees $(git -C "$1" worktree list --porcelain | grep -c '^worktree ')"
    echo "head $(git -C "$1" rev-parse --abbrev-ref HEAD)"
    echo "main $(git -C "$1" rev-list --count main)"
    echo "stash $(git -C "$1" stash list | wc -l | tr -d ' ')"; } >"$1.workspace"
}

# check <dir> <case>: one line for each item, PASS, FAIL or SKIP, with the scenario.
# The gist is the first message that names #91 or its title, when it holds
# the title. A think line before that message, or before the first change
# with no message about #91 before it, gives SKIP: it can be a message that
# the log holds only in other words, and the log cannot show what it told.
# "The run waits" and "the run stops" have the same check, "no change": one
# run cannot show the difference (scenarios/README.md), so a run that stops
# passes "the run waits".
# shellcheck disable=SC2034,SC2329 # the items read the values and call issue, at and told through eval
check() {
  local d=$1 s first_write named nline gist titled think assignees linked branch same last
  # A write: an edit of a file, a commit, a branch, a worktree, or a write to
  # the tracker. A read, as `sed -n 1p worktree.sh` or `git merge-base`, is
  # none.
  first_write=$(W='(^|[;&|(] *)(bash |sh )?[^ ;&|]*(worktree|add-finding)\.sh|gh issue (edit|close|comment|create|reopen)|gh pr (create|merge|edit|close|comment)|gh api .*(-X|--method) *(POST|PATCH|PUT|DELETE)|gh api graphql.*mutation|git( +-[Cc] +[^ ]+)* +((commit|push|switch|checkout|worktree +add|merge|rebase|reset|cherry-pick|stash +(push|pop|apply|drop|save))([ ;&|)]|$)|stash *([;&|)]|$)|branch +[A-Za-z])|sed -i|perl -[a-z]*i' \
    awk -F'\t' '$1 ~ /^(sub)?(Edit|Write|NotebookEdit|EnterWorktree)$/ ||
      $1 ~ /^(sub)?Bash$/ && ($2 ~ ENVIRON["W"] || $2 ~ /gh issue develop/ && $2 !~ /(--list|--help| -l| -h)( |$)/) { print NR; exit }' "$d.events")
  named=$(grep -n "^text" "$d.events" | grep -F -e '#91' -e "$title" | head -n 1)
  nline=${named%%:*}
  gist=$(grep -F "$title" <<<"$named" | cut -d: -f1 || true)
  titled=$(grep -n "^text" "$d.events" | grep -F "$title" | head -n 1 | cut -d: -f1)
  think=$(grep -n "^think" "$d.events" | head -n 1 | cut -d: -f1)
  last=$(awk -F'\t' '$1 == "text" { last = $2 } END { print last }' "$d.events")
  # The workspace as setup leaves it: no changed file, main, one worktree,
  # HEAD on main, one commit on main, no stash entry.
  same='[ "$(cat "$d.workspace")" = "$(printf "main\nworktrees 1\nhead main\nmain 1\nstash 0")" ]'
  assignees=$(jq -c '.issues[] | select(.number == 91) | .assignees' "$d.state.json")
  linked=$(jq -c '.issues[] | select(.number == 91) | .linked' "$d.state.json")
  branch=$(jq -r '.[0] // empty' <<<"$linked")
  item() { if eval "$2"; then echo "PASS $s: $1"; else echo "FAIL $s: $1"; fi; }
  issue() { jq -rc --argjson n "$1" ".issues[] | select(.number == \$n) | $2" "$d.state.json"; }
  # at <jq test>: the test holds on the tracker. In it, at("close 95") is the
  # index of the first write "close 95" in the log of the fake gh, marked or
  # not, or null.
  at() { jq -e "def at(\$w): [(.log // [])[] | split(\" \")[0:2] | join(\" \") == \$w] | index(true); $1" "$d.state.json" >/dev/null; }
  told() { grep "^text" "$d.events" | grep -qiF "$1"; }
  before() { [ -n "$1" ] && { [ -z "$first_write" ] || [ "$1" -lt "$first_write" ]; }; }
  # first: the first message about #91 tells its gist.
  first() {
    if [ -n "$think" ] && { [ -z "$nline" ] || [ "$think" -lt "$nline" ]; }; then
      echo "SKIP $s: the first message about #91 tells its gist: a think line comes before it"
    else
      item 'the first message about #91 tells its gist' '[ -n "$gist" ]'
    fi
  }
  # outcomes: the Then and Never items of A free task, for #91.
  outcomes() {
    first
    if ! before "$gist" && ! before "$nline" && before "$think"; then
      echo "SKIP $s: the gist comes before any change: only a think line comes before the change"
    else
      item 'the gist comes before any change' 'before "$gist"'
    fi
    item '#91 is assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
    item 'a branch <type>/91-<two to four words> exists' 'grep -qE "^(feat|fix|refactor|docs|test|ci|chore)/91-[a-z0-9]+(-[a-z0-9]+){1,3}(, not from main)?\$" "$d.branches"'
    item 'that branch is made from the default branch' '[ -n "$branch" ] && grep -qxF "$branch" "$d.branches"'
    item 'that branch is linked to #91' '[ -n "$branch" ] && cut -d, -f1 "$d.branches" | grep -qxF "$branch"'
    item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
  }
  case $2 in
    free) s='A free task'
      outcomes
      ;;
    other) s='A task that another person is assigned to'
      first
      item 'the person is told that #91 is assigned to another person' 'told "$other"'
      item 'the run waits: no change' '[ -z "$first_write" ] && eval "$same"'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$other\"]" ]'
      item 'never: a branch for #91 is created' '[ "$(cat "$d.branches")" = main ] && [ "$linked" = "[]" ]'
      ;;
    down) s='The tracker does not answer'
      item 'the person is told the error of the tracker' 'told 502'
      item 'the run stops: no change' '[ -z "$first_write" ] && eval "$same"'
      item 'never: a gist of #91 that the run did not read' '[ -z "$titled" ]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      item 'never: a branch for #91 is created' '[ "$(cat "$d.branches")" = main ] && [ "$linked" = "[]" ]'
      ;;
    dup) s='A free duplicate'
      # Each line of the trace, with its indent or without.
      item 'a comment on #91 holds the stack trace of #95' 'jq -e --arg t "$trace" "(.issues[] | select(.number == 91) | .comments)
        | any(.[]; .body as \$b | all(\$t | split(\"\\n\")[] | sub(\"^ +\"; \"\"); . as \$l | \$b | contains(\$l)))" "$d.state.json" >/dev/null'
      item '#95 is closed as a duplicate of #91' '[ "$(issue 95 "[.state, .stateReason, .duplicateOf]")" = "[\"CLOSED\",\"DUPLICATE\",91]" ]'
      item 'the comment on #91 comes before #95 closes' 'at "(at(\"comment 91\") // 1e9) < (at(\"close 95\") // -1)"'
      # The work: a changed file or a commit in the workspace (scenarios/TERMS.md).
      item '#95 closes before the work starts' 'at "(.log // []) | index(\"close 95\") != null"'
      item 'the last message names #95 as closed' 'grep -qiE "clos(ed|ing)([^.]|\.[^ ])*#95|#95([^.]|\.[^ ])*clos(ed|ing)" <<<"$last"'
      item 'never: #91 closes' '[ "$(issue 91 .state)" = OPEN ]'
      outcomes
      ;;
    busy) s='A busy duplicate'
      item '#95 stays open' '[ "$(issue 95 .state)" = OPEN ]'
      item 'the person is told that #95 stays open because it is busy' 'grep "^text" "$d.events" | grep -F "#95" | grep -qiE "busy|$other"'
      outcomes
      item 'never: #95 closes' 'at "at(\"close 95\") == null"'
      item 'never: the assignees of #95 change' '[ "$(issue 95 .assignees)" = "[\"$other\"]" ]'
      ;;
    *) echo "$0: no case $2" >&2; return 2 ;;
  esac
}

case ${1:-} in
  cases | not_run | setup | record | check) "$@" ;;
  *) echo "usage: $0 cases | not_run | setup <dir> <case> | record <dir> | check <dir> <case>" >&2; exit 2 ;;
esac
