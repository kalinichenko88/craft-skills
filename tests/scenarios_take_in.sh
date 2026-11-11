#!/usr/bin/env bash
# The cases of tests/scenarios_eval.sh, one for each scenario of
# scenarios/github/take-in.md that a case runs: the Given of each case, as a
# tracker in JSON and a workspace with a bare origin, the snapshot of its git
# state, and the checks of the Then and Never items of its scenario. The eval
# runs it so:
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
# cases: one line for each case, with its name, the cap of one message in
# dollars, the message of the person, and in a case of two messages the
# answer to the question of the first one, in the same session. A case that
# goes on into the work after the take-in has the higher cap.
cases() {
  printf '%s\n' 'free 4 #91' 'other 2 #91' 'down 2 #91' 'dup 4 #91' 'busy 4 #91' 'closed 2 #91' 'otherpr 2 #91' \
    'mypr 2 #91' 'assigned 2 #91' 'here 4 #91 It continues here.' 'there 2 #91 It runs somewhere else.' \
    'linked 2 #91' 'inws 4 #91' 'moved 2 #91' 'otherrepo 2 https://github.com/acme/lib/issues/91'
}
# The scenarios of take-in that no case runs yet, one on each line: none now.
# tests/scenarios_checks_test.sh fails for a heading of the file that is
# neither a case nor in this list, and for a name here that is no heading.
not_run() { :; }

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
# tracker <dir>.state.json, and the fake gh in <dir>.bin. <dir>.given.workspace
# and <dir>.given.branches hold the workspace and the origin's branches as the
# Given leaves them, in the shape of snapshot.
setup() {
  local w=$1
  # elsewhere <branch> <who>: a commit of <who> on <branch> of the origin,
  # from another clone: the fix of #91.
  elsewhere() {
    git clone -q "$w.origin" "$w.elsewhere"
    git -C "$w.elsewhere" switch -qc "$1"
    printf '# shop\n\nInstall it with `npm install shop`.\n' >"$w.elsewhere/README.md"
    git -C "$w.elsewhere" -c user.name="$2" -c user.email="$2@example.com" commit -qam 'docs: fix the install command'
    git -C "$w.elsewhere" push -q origin "$1"
    rm -rf "$w.elsewhere"
  }
  git init -q --bare -b main "$w.origin"
  git init -q -b main "$w"
  git -C "$w" config user.name "$me"
  git -C "$w" config user.email "$me@example.com"
  printf '# shop\n\nInstall it with `npm instal shop`.\n' >"$w/README.md"
  git -C "$w" add README.md
  git -C "$w" commit -qm 'docs: add the README'
  git -C "$w" remote add origin "$w.origin"
  git -C "$w" push -q -u origin main
  # The Given: the branches of the case, and its change of a free task's tracker.
  # No step is on the left of && or ||, where set -e does not stop a failure.
  local given=.
  case $2 in
    free) ;;
    other) given='.issues[0].assignees = [$other]' ;;
    down) given='.down = true' ;;
    dup) given='.issues += [task(95; $title95; $body95 + "\n\nThen my app failed:\n\n```\n" + $trace + "\n```"; [])]' ;;
    busy) given='.issues += [task(95; $title95; $body95; [$other])]' ;;
    closed) given='.issues[0] |= (.state = "CLOSED" | .stateReason = "COMPLETED")' ;;
    otherpr) elsewhere fix/91-install "$other"; given='.prs = [pr($other)]' ;;
    mypr) elsewhere fix/91-install "$me"; given='.prs = [pr($me)]' ;;
    assigned | here | there) given='.issues[0].assignees = [$me]' ;;
    linked) git -C "$w.origin" branch fix/91-typo main; given='.issues[0].linked = ["fix/91-typo"]' ;;
    inws | moved) git -C "$w" branch fix/91-typo; git -C "$w" push -q -u origin fix/91-typo
      [ "$2" = inws ] || elsewhere fix/91-typo "$me"
      given='.issues[0] |= (.assignees = [$me] | .linked = ["fix/91-typo"])' ;;
    otherrepo) given='.issues[0].repo = "acme/lib"' ;;
    *) echo "$0: no case $2" >&2; return 2 ;;
  esac
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
# The gist is the first message that names #91 or its title, when it holds
# the title. A think line before that message, or before the first change
# with no message about #91 before it, gives SKIP: it can be a message that
# the log holds only in other words, and the log cannot show what it told.
# "The run waits" and "the run stops" have the same check, "no change": one
# run cannot show the difference (scenarios/README.md), so a run that stops
# passes "the run waits". With no answer after a question where the work
# runs, a run of here or there gives no item: its Given does not hold.
# shellcheck disable=SC2034,SC2329 # the items read the values and call issue, at and told through eval
check() {
  local d=$1 s first_write named nline gist titled think assignees linked branch same last where yours
  # A run before 2026-11-11 kept no snapshot of its Given.
  [ -f "$d.given.workspace" ] && [ -f "$d.given.branches" ] ||
    { echo "$0: $d has no .given.workspace or .given.branches: its run is older than the snapshot of its Given" >&2; return 2; }
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
    branched
  }
  case $2 in
    here | there) { grep -q '^person' "$d.events" && sed -n '/^person/q;p' "$d.events" | grep '^text' | grep -qiE "($where)[^.?!]*\?"; } ||
      { echo "$0: $d has no answer of the person after a question whether the work runs somewhere else: the Given of its scenario does not hold" >&2; return 2; } ;;
  esac
  case $2 in
    free) s='A free task'
      outcomes
      ;;
    other) s='A task that another person is assigned to'
      first
      item 'the person is told that #91 is assigned to another person' 'told "$other"'
      nochange 'the run waits'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$other\"]" ]'
      nobranch '[]'
      ;;
    down) s='The tracker does not answer'
      item 'the person is told the error of the tracker' 'told 502'
      nochange 'the run stops'
      item 'never: a gist of #91 that the run did not read' '[ -z "$titled" ]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '[]'
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
    closed) s='A closed task'
      first
      item 'the person is told that #91 is closed' 'told closed'
      nochange 'the run waits'
      item 'never: the state of #91 changes' '[ "$(issue 91 "[.state, .stateReason]")" = "[\"CLOSED\",\"COMPLETED\"]" ]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '[]'
      ;;
    otherpr) s="A task with another person's pull request"
      first
      item 'the person is told that #96 of another person closes #91' 'grep "^text" "$d.events" | grep -F "#96" | grep -qiF "$other"'
      nochange 'the run waits'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '[]'
      ;;
    mypr) s="A task with the person's pull request"
      first
      item 'the person is told that the work on #91 has pull request #96' 'told "#96"'
      nochange 'the run stops'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '[]'
      ;;
    assigned) s='A task assigned to the person, with no branch'
      first
      item 'the person is told that #91 is assigned to the person already' 'says "$yours"'
      item 'the person is asked whether the work on #91 runs somewhere else or continues here' 'asked "$where"'
      nochange 'the run waits'
      nobranch '[]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
      ;;
    here) s="The work on the person's task continues here"
      item '#91 stays assigned to the person' '[ "$assignees" = "[\"$me\"]" ]'
      branched
      ;;
    there) s="The work on the person's task runs somewhere else"
      nochange 'the run stops'
      nobranch '[]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
      ;;
    linked) s='A linked branch with no assignee'
      first
      item 'the person is told that fix/91-typo is linked to #91' 'told fix/91-typo'
      item 'the person is asked whose branch fix/91-typo is' 'asked "whose|yours|your (own )?branch|someone else|another person"'
      nochange 'the run waits'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '["fix/91-typo"]'
      ;;
    inws) s="The person's work is in the workspace"
      first
      # What the message says: the log keeps no line break of a message.
      item 'the person is told in one line that the work on #91 continues on fix/91-typo' \
        'grep "^text" "$d.events" | grep -F fix/91-typo | grep -qi continu'
      # A commit on fix/91-typo, or a changed file in its worktree.
      item 'the work goes on, on fix/91-typo' '[ -n "$(tip "$d.workspace")" ] && [ "$(tip "$d.workspace")" != "$(tip "$d.given.workspace")" ]'
      item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
      item 'never: #91 gets a second linked branch' '[ "$(jq length <<<"$linked")" -le 1 ]'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[\"$me\"]" ]'
      ;;
    moved) s="The person's branch moved on somewhere else"
      first
      item 'the person is told that #91 is assigned to the person' 'says "$yours"'
      item 'the person is told that fix/91-typo is linked to #91' 'told fix/91-typo'
      item 'the person is asked whether the work on #91 runs somewhere else or continues here' 'asked "$where"'
      nochange 'the run waits'
      nobranch '["fix/91-typo"]'
      item "never: the workspace's fix/91-typo changes" '[ "$(tip "$d.workspace" | cut -d" " -f2)" = "$(tip "$d.given.workspace" | cut -d" " -f2)" ]'
      ;;
    otherrepo) s='A task of another repository'
      first
      item 'the person is told that #91 is in another repository' 'told acme/lib'
      nochange 'the run stops'
      item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
      nobranch '[]'
      ;;
    *) echo "$0: no case $2" >&2; return 2 ;;
  esac
}

case ${1:-} in
  cases | not_run | setup | snapshot | check) "$@" ;;
  *) echo "usage: $0 cases | not_run | setup <dir> <case> | snapshot <dir> <to> | check <dir> <case>" >&2; exit 2 ;;
esac
