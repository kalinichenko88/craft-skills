#!/usr/bin/env bash
# The cases of tests/scenarios_eval.sh, one for each scenario of
# scenarios/github/take-in.md that a case runs. tests/scenarios_take_in/ holds
# a file for each case, <case>.sh, which defines four functions:
#
#   <case>_case    the line of the case, by line: its name, the cap of one
#                  message in dollars, its scenario, the message of the
#                  person, and in a case of two messages the answer to the
#                  question of the first one, in the same session. A case
#                  that goes on into the work after the take-in has the
#                  higher cap.
#   <case>_given   the steps of its Given after the base that setup makes:
#                  its branches, and its change of the tracker in $given, jq
#   <case>_check   the checks of the Then and Never items of its scenario
#   <case>_copies  the changed copies of its recorded run, which
#                  tests/scenarios_checks_test.sh checks
#
# This file holds what the cases share: the task, the workspace with a bare
# origin and the tracker in JSON that each Given starts from, the snapshot of
# the git state, and the helpers of the checks. The eval runs it so:
#
#   scenarios_take_in.sh cases
#   scenarios_take_in.sh not_run
#   scenarios_take_in.sh setup <dir> <case>
#   scenarios_take_in.sh snapshot <dir> <to>
#   scenarios_take_in.sh check <dir> <case>
#
# Needs bash, jq, git and awk.

# shellcheck disable=SC2016 # Markdown's backticks, and jq and checks run later
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
for f in "$root"/tests/scenarios_take_in/*.sh; do
  # shellcheck source=/dev/null # one file for each case
  . "$f"
done
# line <field>...: the fields of the line of a case, with a tab between them.
line() { local IFS=$'\t'; echo "$*"; }
cases() { for f in "$root"/tests/scenarios_take_in/*.sh; do f=${f##*/}; "${f%.sh}_case"; done; }
# known <case>: the case has a file.
known() { declare -F "$1_case" >/dev/null || { echo "$0: no case $1" >&2; return 2; }; }
# The scenarios of take-in that no case runs yet, one on each line: those of
# #246, which #320 gives cases. tests/scenarios_checks_test.sh fails for a
# heading of the file that is neither a case nor in this list, and for a name
# here that is no heading.
not_run() {
  printf '%s\n' \
    'A settled bug on the code of the task' \
    'A duplicate that tells only what was seen' \
    'A task that names a line that moved' \
    'A task that holds an added finding' \
    'A branch only' \
    'Stay on the branch of the workspace' \
    "The person's pull request is in the workspace" \
    'A linked branch of another repository only' \
    'A branch in the workspace with the name of the new branch' \
    'The text of the task cannot be read' \
    'An earlier run works on the task in another conversation' \
    'A closed task with a free duplicate' \
    "Another person's task whose linked branch the workspace has" \
    "The workspace's branch has a commit that the repository does not have" \
    "The linked branch is another person's" \
    "The linked branch is the person's" \
    'The work on the linked branch continues here' \
    'The work on the linked branch runs somewhere else' \
    'A text after a wait that names no task' \
    'A text after a stop that names the task again'
}

title='README: the install command says npm instal'
body='The README tells the reader to run `npm instal shop`. npm has no instal command, so the command fails. Done when the README says `npm install shop`.'
typo='npm instal shop' # the defect, in the words of the body; not in the fixed command
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

# elsewhere <branch> <who>: a commit of <who> on <branch> of the origin of
# the workspace $w of setup, from another clone: the fix of #91.
elsewhere() {
  git clone -q "$w.origin" "$w.elsewhere"
  git -C "$w.elsewhere" switch -qc "$1"
  printf '# shop\n\nInstall it with `npm install shop`.\n' >"$w.elsewhere/README.md"
  git -C "$w.elsewhere" -c user.name="$2" -c user.email="$2@example.com" commit -qam 'docs: fix the install command'
  git -C "$w.elsewhere" push -q origin "$1"
  rm -rf "$w.elsewhere"
}

# setup <dir> <case>: the workspace <dir>, its origin <dir>.origin, the
# tracker <dir>.state.json, and the fake gh in <dir>.bin. <dir>.given.workspace
# and <dir>.given.branches hold the workspace and the origin's branches as the
# Given leaves them, in the shape of snapshot.
setup() {
  local w=$1 given=.
  known "$2"
  git init -q --bare -b main "$w.origin"
  git init -q -b main "$w"
  git -C "$w" config user.name "$me"
  git -C "$w" config user.email "$me@example.com"
  printf '# shop\n\nInstall it with `npm instal shop`.\n' >"$w/README.md"
  git -C "$w" add README.md
  git -C "$w" commit -qm 'docs: add the README'
  git -C "$w" remote add origin "$w.origin"
  git -C "$w" push -q -u origin main
  # The Given: the branches of the case, and its change of a free task's
  # tracker. No step is on the left of && or ||, where set -e does not stop a
  # failure.
  "$2_given"
  jq -n --arg me "$me" --arg other "$other" --arg origin "$w.origin" --arg w "$w" --arg title "$title" \
    --arg body "$body" --arg title95 "$title95" --arg body95 "$body95" --arg trace "$trace" '
    def task($n; $t; $b; $who): {number: $n, title: $t, body: $b, state: "OPEN", stateReason: null,
      assignees: $who, labels: [], comments: [], linked: []};
    def pr($who): {number: 96, title: "docs: fix the npm install command", state: "OPEN", author: {login: $who},
      headRefName: "fix/91-install", url: "https://github.com/acme/shop/pull/96", closes: [91]};
    {me: $me, repo: "acme/shop", origin: $origin, workspace: $w, down: false, prs: [],
      labels: ["bug", "debt", "enhancement"], visibility: "PUBLIC", issues: [task(91; $title; $body; [])]}
    | '"$given" >"$w.state.json"
  mkdir "$w.bin"
  printf '#!/usr/bin/env bash\nexec bash %q %q "$@"\n' "$root/tests/fake_gh.sh" "$w.state.json" >"$w.bin/gh"
  chmod +x "$w.bin/gh"
  snapshot "$w" "$w.given"
}

# snapshot <dir> <to>: <to>.branches holds the origin's branches, each one
# that is not made from main marked so. <to>.workspace holds the changed
# files, the local branches, the worktrees, the branch of HEAD, the commits
# on main and the stash entries of the workspace. Each local branch but main
# gives its last commit, and "changed" when its worktree has a changed file.
snapshot() {
  local b c t
  git -C "$1.origin" for-each-ref --format='%(refname:short)' refs/heads | while read -r b; do
    if git -C "$1.origin" merge-base --is-ancestor main "$b"; then echo "$b"; else echo "$b, not from main"; fi
  done >"$2.branches"
  { git -C "$1" status --porcelain
    git -C "$1" for-each-ref --format='%(refname:short) %(objectname) %(worktreepath)' refs/heads | while read -r b c t; do
      [ "$b" != main ] || { echo main; continue; }
      [ -z "$t" ] || ! git -C "$t" status --porcelain | grep -q . || c="$c changed"
      echo "$b $c"
    done
    echo "worktrees $(git -C "$1" worktree list --porcelain | grep -c '^worktree ')"
    echo "head $(git -C "$1" rev-parse --abbrev-ref HEAD)"
    echo "main $(git -C "$1" rev-list --count main)"
    echo "stash $(git -C "$1" stash list | wc -l | tr -d ' ')"; } >"$2.workspace"
}

# check <dir> <case>: one line for each item, PASS, FAIL or SKIP, with the scenario.
# The gist is the first message that names #91, its title or its typo (a
# narration can drop the id and title, ADR 0008), when it holds the title. A
# think line before it, or before a change with no such message, gives SKIP.
# "The run waits" and "the run stops" have the same check, "no change": one
# run cannot show the difference (scenarios/README.md), so a run that stops
# passes "the run waits". A case whose Given does not hold in the run, as a
# case of two messages with no question before the answer, gives no item and
# exits 2.
# shellcheck disable=SC2034,SC2329 # the items read the values and call issue, at and told through eval
check() {
  local d=$1 s first_write named nline gist titled think assignees linked branch same last where yours
  known "$2"
  # A run before 2026-11-11 kept no snapshot of its Given.
  [ -f "$d.given.workspace" ] && [ -f "$d.given.branches" ] ||
    { echo "$0: $d has no .given.workspace or .given.branches: its run is older than the snapshot of its Given" >&2; return 2; }
  s=$(cases | awk -F'\t' -v c="$2" '$1 == c { print $3 }')
  # A write: an edit of a file, a commit, a branch, a worktree, or a write to
  # the tracker. A read, as `sed -n 1p worktree.sh` or `git merge-base`, is
  # none.
  first_write=$(W='(^|[;&|(] *)(bash |sh )?[^ ;&|]*(worktree|add-finding)\.sh|gh issue (edit|close|comment|create|reopen)|gh pr (create|merge|edit|close|comment)|gh api .*(-X|--method) *(POST|PATCH|PUT|DELETE)|gh api graphql.*mutation|gh label (create|edit|delete)|git( +-[Cc] +[^ ]+)* +((commit|push|switch|checkout|worktree +add|merge|rebase|reset|cherry-pick|stash +(push|pop|apply|drop|save))([ ;&|)]|$)|stash *([;&|)]|$)|branch +[A-Za-z])|sed -i|perl -[a-z]*i' \
    awk -F'\t' '$1 ~ /^(sub)?(Edit|Write|NotebookEdit|EnterWorktree)$/ ||
      $1 ~ /^(sub)?Bash$/ && ($2 ~ ENVIRON["W"] || $2 ~ /gh issue develop/ && $2 !~ /(--list|--help| -l| -h)( |$)/) { print NR; exit }' "$d.events")
  named=$(grep -n "^text" "$d.events" | grep -F -e '#91' -e "$title" -e "$typo" | head -n 1)
  nline=${named%%:*}
  gist=$(grep -F "$title" <<<"$named" | cut -d: -f1 || true)
  titled=$(grep -n "^text" "$d.events" | grep -F "$title" | head -n 1 | cut -d: -f1)
  think=$(grep -n "^think" "$d.events" | head -n 1 | cut -d: -f1)
  last=$(awk -F'\t' '$1 == "text" { last = $2 } END { print last }' "$d.events")
  # The workspace as the Given leaves it.
  same='cmp -s "$d.given.workspace" "$d.workspace"'
  where='somewhere else|elsewhere|(another|other) (session|machine|computer)' yours="assigned to (you|$me)"
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
  says() { grep "^text" "$d.events" | grep -qiE "$1"; }
  # asked <regex>: a match and then a question mark, in one sentence of a message.
  asked() { grep "^text" "$d.events" | grep -qiE "($1)[^.?!]*\?"; }
  # tip <snapshot>: the line of fix/91-typo in a snapshot of the workspace.
  tip() { grep '^fix/91-typo ' "$1" || true; }
  nochange() { item "$1: no change" '[ -z "$first_write" ] && eval "$same"'; }
  # nobranch <linked>: the origin has the branches of the Given, and #91 has
  # the linked branches <linked>, as JSON.
  nobranch() { item 'never: a branch for #91 is created' "cmp -s \"\$d.given.branches\" \"\$d.branches\" && [ \"\$linked\" = '$1' ]"; }
  before() { [ -n "$1" ] && { [ -z "$first_write" ] || [ "$1" -lt "$first_write" ]; }; }
  # first: the first message about #91 tells its gist.
  first() {
    if [ -n "$think" ] && { [ -z "$nline" ] || [ "$think" -lt "$nline" ]; }; then
      echo "SKIP $s: the first message about #91 tells its gist: a think line comes before it"
    else
      item 'the first message about #91 tells its gist' '[ -n "$gist" ]'
    fi
  }
  # branched: the items of A free task on the branch of #91.
  branched() {
    item 'a branch <type>/91-<two to four words> exists' 'grep -qE "^(feat|fix|refactor|docs|test|ci|chore)/91-[a-z0-9]+(-[a-z0-9]+){1,3}(, not from main)?\$" "$d.branches"'
    item 'that branch is made from the default branch' '[ -n "$branch" ] && grep -qxF "$branch" "$d.branches"'
    item 'that branch is linked to #91' '[ -n "$branch" ] && cut -d, -f1 "$d.branches" | grep -qxF "$branch"'
    item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
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
    labelled
    branched
  }
  labelled() { item '#91 has the label in progress' '[ "$(issue 91 "any(.labels[]; ascii_downcase == \"in progress\")")" = true ]'; }
  # answered: the person answers after a question whether the work runs
  # somewhere else, or the Given of the case does not hold.
  answered() {
    { grep -q '^person' "$d.events" && sed -n '/^person/q;p' "$d.events" | grep '^text' | grep -qiE "($where)[^.?!]*\?"; } ||
      { echo "$0: $d has no answer of the person after a question whether the work runs somewhere else: the Given of its scenario does not hold" >&2; return 2; }
  }
  "$2_check"
}

case ${1:-} in
  cases | not_run | setup | snapshot | check) "$@" ;;
  *) echo "usage: $0 cases | not_run | setup <dir> <case> | snapshot <dir> <to> | check <dir> <case>" >&2; exit 2 ;;
esac
