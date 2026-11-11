#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
otherws_case() { line otherws 2 "Another person's task whose linked branch the workspace has" '#91'; }
otherws_given() { wsbranch; given='.issues[0] |= (.assignees = [$other] | .linked = ["fix/91-typo"])'; }
otherws_check() {
  first
  item 'the person is told that #91 is assigned to another person' 'told "$other"'
  nochange 'the run waits'
  item 'never: the person is told that the work on #91 continues' '! says "continues on fix/91-typo|work (on #91 )?continues"'
  item 'never: the person is asked whether the work runs somewhere else' '! asked "$where"'
  kept "never: the workspace's fix/91-typo changes"
  keeps '["rivera"]'
}
otherws_copies() {
  # No name of the assignee, a write, the work told as going on, a question
  # whether it runs somewhere else, the branch moved, and the person added.
  copy otherws
  sed -i.bak '/^text/s/rivera/someone/g' "$tmp/$n/otherws.events"
  flips otherws 'the person is told that #91 is assigned to another person'
  copy otherws
  add otherws $'Bash\tgh issue edit 91 --add-assignee @me'
  flips otherws 'the run waits: no change'
  copy otherws
  add otherws $'text\tThe work on #91 continues on fix/91-typo.'
  flips otherws 'never: the person is told that the work on #91 continues'
  copy otherws
  add otherws $'text\tDoes the work on #91 run somewhere else, or here?'
  flips otherws 'never: the person is asked whether the work runs somewhere else'
  copy otherws
  sed -i.bak 's/^fix\/91-typo .*/fix\/91-typo 0000000000000000000000000000000000000000/' "$tmp/$n/otherws.workspace"
  flips otherws "never: the workspace's fix/91-typo changes" 'the run waits: no change'
  copy otherws
  state otherws '.issues[0].assignees += ["kim"]'
  flips otherws 'never: the assignees of #91 change'
}
otherws_fails() { :; }
