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
  grep -qE '^(sub)?Bash.*worktree\.sh 91 fix/91-typo' "$d.events" ||
    { echo "$0: $d gives the branch of #91 no name fix/91-typo: the Given of its scenario does not hold" >&2; return 2; }
  sha=$(tip "$d.given.workspace" | cut -d' ' -f2 | cut -c1-7)
  item 'the person is told that the workspace has fix/91-typo' 'told fix/91-typo'
  item 'the person is told the commit of fix/91-typo that the repository does not have' 'told "$sha" || told "try a shorter install command"'
  item 'the person is asked what to do with fix/91-typo' 'asked "fix/91-typo|branch"'
  item 'the question has three answers: keep it and give the new branch another name, delete it, and take it as the branch of #91' \
    'says "another name|other name|new name|different name|rename" && says "delete|remove" && says "(take|use|keep|continue)[^.]*(as|on) (the|it|fix/91-typo)"'
  nowrite 'the run waits'
  kept 'never: fix/91-typo changes'
  item 'never: the assignees of #91 change' '[ "$assignees" = "[]" ]'
  unlabelled
  item 'never: #91 gets a linked branch' '[ "$linked" = "[]" ]'
}
samename_copies() { :; }
