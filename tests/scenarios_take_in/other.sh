#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
other_case() { line other 2 'A task that another person is assigned to' '#91'; }
other_given() { given='.issues[0].assignees = [$other]'; }
other_check() {
  first
  item 'the person is told that #91 is assigned to another person' 'told "$other"'
  nochange 'the run waits'
  keeps "$other"
  nobranch '[]'
}
other_copies() {
  # The person added to another person's task.
  copy other
  state other '.issues[0].assignees += ["kim"]'
  flips other 'never: the assignees of #91 change'

  # Writes on another person's task: to the tracker, in the shell, with git -C,
  # and on the second line of a command.
  local write read
  for write in 'gh issue edit 91 --add-assignee @me' "sed -i '' s/instal/install/ README.md" \
    'git -C <work> commit -qam fix' 'cd <work>; bash <craft>/skills/github/scripts/worktree.sh 91 docs/91-x' \
    'gh label create "in progress" --color fbca04'; do
    copy other
    add other "$(printf 'Bash\t%s' "$write")"
    flips other 'the run waits: no change'
  done

  # Changes to the workspace that the log does not show: a changed file, and a
  # commit on main.
  copy other
  { echo ' M README.md'; cat "$fixtures/other.workspace"; } >"$tmp/$n/other.workspace"
  flips other 'the run waits: no change'
  copy other
  sed -i.bak 's/^main 1$/main 2/' "$tmp/$n/other.workspace"
  flips other 'the run waits: no change'

  # Reads on another person's task.
  for read in 'git diff $(git merge-base origin/main HEAD)' 'git branch 2>&1 | head' 'git stash list' \
    'gh issue develop 91 -l' 'sed -n 1,80p <craft>/skills/github/scripts/worktree.sh'; do
    copy other
    add other "$(printf 'Bash\t%s' "$read")"
    stays
  done
}
other_fails() { :; }
