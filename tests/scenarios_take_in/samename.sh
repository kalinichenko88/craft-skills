#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
samename_case() { line samename 2 'A branch in the workspace with the name of the new branch' '#91'; }
# The instructions of the project give the branch of #91 its name, and the
# workspace has a branch of that name with a commit of its own.
samename_given() {
  printf 'The branch of issue #91 is named `fix/91-typo`.\n' >"$w/CLAUDE.md"
  git -C "$w" add CLAUDE.md
  git -C "$w" commit -qm 'docs: name the branch of #91'
  git -C "$w" push -q origin main
  git -C "$w" switch -qc fix/91-typo
  printf '# shop\n\nInstall it with `npm i shop`.\n' >"$w/README.md"
  git -C "$w" commit -qam 'docs: try a shorter install command'
  git -C "$w" switch -q main
}
samename_check() {
  local sha
  grep -qE '^(sub)?Bash.*worktree\.sh["'"'"']? 91 fix/91-typo' "$d.events" ||
    { echo "$0: $d gives the branch of #91 no name fix/91-typo: the Given of its scenario does not hold" >&2; return 2; }
  sha=$(tip "$d.given.workspace" | cut -d' ' -f2 | cut -c1-7)
  item 'the person is told that the workspace has fix/91-typo' 'told fix/91-typo'
  item 'the person is told the commit of fix/91-typo that the repository does not have' 'told "$sha" || told "try a shorter install command"'
  # A question, or a request to choose, as "Choose one:" before a list.
  item 'the person is asked what to do with fix/91-typo' 'asked "fix/91-typo|branch" || says "choose|pick one"'
  item 'the question has three answers: keep it and give the new branch another name, delete it, and take it as the branch of #91' \
    'says "another name|other name|new name|different name|rename" && says "(delete|remove)( the| this)? (branch|fix/91-typo|it )" && says "(take|use|keep|continue)[^.]*(as|on) (the|it|fix/91-typo)"'
  nowrite 'the run waits'
  kept 'never: fix/91-typo changes'
  keeps
  unlabelled
  item 'never: #91 gets a linked branch' '[ "$linked" = "[]" ]'
}
samename_copies() {
  local sha
  sha=$(grep '^fix/91-typo ' "$fixtures/samename.given.workspace" | cut -d' ' -f2 | cut -c1-7)
  # No name of the branch, no commit told, no request to choose, no word of a
  # delete, a write to #91, the branch moved, #91 assigned, labelled and
  # linked; and another name of the branch.
  copy samename
  sed -i.bak '/^text/s#fix/91-typo#the branch#g' "$tmp/$n/samename.events"
  flips samename 'the person is told that the workspace has fix/91-typo'
  copy samename
  sed -i.bak "/^text/{s/$sha/a commit/g; s/try a shorter install command/a change/g;}" "$tmp/$n/samename.events"
  flips samename 'the person is told the commit of fix/91-typo that the repository does not have'
  copy samename
  sed -i.bak '/^text/{s/[Cc]hoose/take/g; s/?/./g;}' "$tmp/$n/samename.events"
  flips samename 'the person is asked what to do with fix/91-typo'
  copy samename
  sed -i.bak '/^text/s/[Dd]elete/drop/g' "$tmp/$n/samename.events"
  flips samename 'the question has three answers: keep it and give the new branch another name, delete it, and take it as the branch of #91'
  copy samename
  state samename '.log = ["edit 91"]'
  flips samename 'the run waits: no change'
  copy samename
  sed -i.bak 's/^fix\/91-typo .*/fix\/91-typo 0000000000000000000000000000000000000000/' "$tmp/$n/samename.workspace"
  flips samename 'never: fix/91-typo changes' 'the run waits: no change'
  copy samename
  state samename '.issues[0].assignees = ["kim"]'
  flips samename 'never: the assignees of #91 change'
  copy samename
  state samename '.issues[0].labels = ["in progress"]'
  flips samename 'never: #91 gets the label in progress'
  copy samename
  state samename '.issues[0].linked = ["fix/91-typo"]'
  flips samename 'never: #91 gets a linked branch'
  copy samename
  sed -i.bak '/^Bash/s#worktree\.sh" 91 fix/91-typo#worktree.sh" 91 fix/91-readme#' "$tmp/$n/samename.events"
  notchecked samename
}
samename_fails() { :; }
