#!/usr/bin/env bash
# Runs worktree.sh of the github skill against the fake gh of
# tests/github_harness.sh.

set -eu

# shellcheck source=tests/github_harness.sh
. "$(dirname "$0")/github_harness.sh"

# worktree.sh reads the local branches: it runs in a checkout of its own.
git init -q "$tmp/repo"
git -C "$tmp/repo" -c user.name=t -c user.email=t commit -q --allow-empty -m 'First commit'

# worktree.sh in a main checkout, with DRY_RUN=1. As recorded, #5 has no
# assignee. The main checkout never takes the branch in place, also when
# its HEAD is on the default branch of origin.
answer .
git -C "$tmp/repo" update-ref refs/remotes/origin/trunk HEAD
top=$(git -C "$tmp/repo" rev-parse --show-toplevel)
: >"$tmp/calls"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
check 'worktree.sh with DRY_RUN=1 prints its writes and the path' \
  "$(printf 'dry run: gh label create in\\ progress --description The\\ work\\ on\\ it\\ runs --color fbca04\ndry run: gh issue edit 5 --add-assignee @me --add-label in\\ progress\ndry run: gh issue develop 5 --name feat/5-scout-citations --checkout --worktree %s\ndry run: echo .claude/worktrees/ >>%s\n%s' \
    "$top/.claude/worktrees/feat/5-scout-citations" "$top/.git/info/exclude" "$top/.claude/worktrees/feat/5-scout-citations")" "$out"
check 'worktree.sh with DRY_RUN=1 runs no write' '' "$(writes)"
grep -q .claude/worktrees/ "$top/.git/info/exclude" && fail 'worktree.sh with DRY_RUN=1 wrote info/exclude'
# A repository that has the label already, in any case, gets no new one. A
# search of the labels finds more than the name: "in progress" finds invalid.
echo '[{"name": "invalid"}, {"name": "In Progress"}]' >"$tmp/labels.json"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'label create'*) fail 'worktree.sh creates a label that the repository has' "$out" ;; esac
echo '[{"name": "invalid"}]' >"$tmp/labels.json"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'dry run: gh label create in\ progress'*) ;; *) fail 'worktree.sh takes another label for in progress' "$out" ;; esac
echo '[{"name": "in progress"}]' >"$tmp/labels.json"

printf 'feat/5-linked\thttps://github.com/kalinichenko88/agent-skills/tree/feat/5-linked\n' >"$tmp/linked"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'using it'*'--name feat/5-linked --checkout'*) ;;
  *) fail 'worktree.sh reuses the linked branch' "$out" ;;
esac

# A linked branch on an issue that nobody is assigned to can be someone
# else's: worktree.sh warns, and does not assign the issue to you.
case $out in *'warning: #5 has a linked branch and nobody is assigned'*) ;;
  *) fail 'worktree.sh warns about a linked branch with no assignee' "$out" ;;
esac
case $out in *'dry run: gh issue edit'*) fail 'worktree.sh assigns an issue whose linked branch can be someone else'"'"'s' "$out" ;; esac
out=$(cd "$tmp/repo" && FAKE_FAIL='issue view' DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations 2>&1) &&
  fail 'worktree.sh goes on when it cannot read the assignees' "$out"
case $out in *'dry run: gh issue edit'*) fail 'worktree.sh assigns an issue whose assignees it could not read' "$out" ;; esac
answer '.assignees.nodes = [{login: "kalinichenko88"}]'
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *warning*) fail 'worktree.sh warns about a linked branch on an issue assigned to you' "$out" ;; esac
case $out in *'dry run: gh issue edit 5 --add-assignee @me'*) ;;
  *) fail 'worktree.sh assigns an issue that is already yours' "$out" ;;
esac

# An issue that someone else is assigned to is theirs, with a linked branch or
# without one: worktree.sh warns, and does not assign the issue to you.
answer '.assignees.nodes = [{login: "someone"}]'
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'warning: #5 is assigned to someone'*) ;;
  *) fail 'worktree.sh warns about an issue with a linked branch that someone else is assigned to' "$out" ;;
esac
case $out in *'dry run: gh issue edit'*) fail 'worktree.sh assigns an issue with a linked branch that someone else is assigned to' "$out" ;; esac
mv "$tmp/linked" "$tmp/linked.kept"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'warning: #5 is assigned to someone'*) ;;
  *) fail 'worktree.sh warns about an issue that someone else is assigned to' "$out" ;;
esac
case $out in *'dry run: gh issue edit'*) fail 'worktree.sh assigns an issue that someone else is assigned to' "$out" ;; esac
# The command of the warning puts the label on, so a repository with no label
# gets it on this path too.
rm "$tmp/labels.json"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'dry run: gh label create in\ progress'*"gh issue edit 5 --add-assignee @me --add-label 'in progress'"*) ;;
  *) fail 'worktree.sh does not prepare the label for the command of its warning' "$out" ;;
esac
echo '[{"name": "in progress"}]' >"$tmp/labels.json"
mv "$tmp/linked.kept" "$tmp/linked"
answer '.assignees.nodes = [{login: "someone"}, {login: "kalinichenko88"}]'
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *warning*) fail 'worktree.sh warns about an issue that you are assigned to beside someone else' "$out" ;; esac
case $out in *'dry run: gh issue edit 5 --add-assignee @me'*) ;;
  *) fail 'worktree.sh assigns an issue that you are assigned to beside someone else' "$out" ;;
esac
out=$(cd "$tmp/repo" && FAKE_FAIL='api user' DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations 2>&1) &&
  fail 'worktree.sh goes on when it cannot read your login' "$out"
case $out in *'HTTP 502'*) ;; *) fail 'worktree.sh stops on something else than the failed login read' "$out" ;; esac
case $out in *'dry run: gh issue edit'*) fail 'worktree.sh assigns an issue when it could not read your login' "$out" ;; esac

printf 'feat/5-scout-citations\thttps://github.com/kalinichenko88/agent-skills/tree/feat/5-scout-citations\n' >>"$tmp/linked"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations)
case $out in *'using it'*) fail 'worktree.sh leaves a linked branch it was given' "$out" ;; esac
case $out in *'--name feat/5-scout-citations --checkout'*) ;;
  *) fail 'worktree.sh checks out the linked branch it was given' "$out" ;;
esac

# An issue linked only to a branch in another repository, as a fork's: gh
# would make a new branch of that name in this one. worktree.sh stops before
# its first write.
# The line is gh issue develop --list as recorded, with another owner.
printf 'feat/5-linked\thttps://github.com/someone/agent-skills/tree/feat/5-linked\n' >"$tmp/linked"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations 2>&1) &&
  fail 'worktree.sh goes on with a linked branch in another repository' "$out"
check 'worktree.sh names the linked branch in another repository' \
  "$(printf '#5 is linked only to branches in another repository:\nhttps://github.com/someone/agent-skills/tree/feat/5-linked')" "$out"
# A linked branch in this repository still wins, after one in a fork, and
# over the fork branch's own name.
printf 'feat/5-scout-citations\thttps://github.com/kalinichenko88/agent-skills/tree/feat/5-scout-citations\n' >>"$tmp/linked"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-linked)
case $out in *'using it'*'--name feat/5-scout-citations --checkout'*) ;;
  *) fail 'worktree.sh skips a linked branch in another repository' "$out" ;;
esac

# worktree.sh --here, for "a branch only": it assigns the issue and checks the
# branch out in the checkout where it runs.
answer .
rm -f "$tmp/linked"
echo '[{"name": "in progress"}]' >"$tmp/labels.json"
: >"$tmp/calls"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-scout-citations --here)
check 'worktree.sh --here assigns and checks the branch out where it is' \
  "$(printf 'dry run: gh issue edit 5 --add-assignee @me --add-label in\\ progress\ndry run: gh issue develop 5 --name feat/5-scout-citations --checkout\n%s' "$top")" "$out"
(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 b --there >/dev/null 2>&1) && fail 'worktree.sh takes an unknown third argument'

# A local branch of the name that no worktree holds, on an issue with no linked
# branch, as a merged pull request's branch that stayed: gh would check its old
# commits out as the work. worktree.sh stops before its first write and names
# them.
git -C "$tmp/repo" -c user.name=t -c user.email=t commit -q --allow-empty -m 'Old work'
git -C "$tmp/repo" branch fix/5-old
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old 2>&1) &&
  fail 'worktree.sh goes on with an old local branch of the name' "$out"
case $out in *'local branch fix/5-old'*'Old work'*) ;;
  *) fail 'worktree.sh names the old local branch and its commits' "$out" ;;
esac
case $out in *'dry run:'*) fail 'worktree.sh writes before it stops on an old local branch' "$out" ;; esac
# A worktree that still holds the branch, as one left after the merge, does
# not make it the issue's work. The stop names the worktree, to work in or to
# remove.
git -C "$tmp/repo" worktree add -q "$tmp/old" fix/5-old
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old 2>&1) &&
  fail 'worktree.sh goes on with an old local branch that a worktree holds' "$out"
case $out in *'local branch fix/5-old'*'checked out in '*'/old'*'Old work'*) ;;
  *) fail 'worktree.sh names the worktree that holds the old local branch' "$out" ;;
esac
case $out in *'dry run:'*) fail 'worktree.sh writes before it stops on an old local branch that a worktree holds' "$out" ;; esac
# --local: the person said that the local branch holds this work, or the issue
# continues on it. worktree.sh takes it as it is, where it is checked out.
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old --local)
case $out in *'fix/5-old is checked out already'*'/old') ;;
  *) fail 'worktree.sh --local works on the local branch in the worktree that holds it' "$out" ;;
esac
# Linked to the issue, the local branch is the issue's work: worktree.sh goes
# on, in the worktree that holds it, or with gh when none does.
printf 'fix/5-old\thttps://github.com/kalinichenko88/agent-skills/tree/fix/5-old\n' >"$tmp/linked"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old)
case $out in *'fix/5-old is checked out already'*'/old') ;;
  *) fail 'worktree.sh works on a linked branch in the worktree that holds it' "$out" ;;
esac
git -C "$tmp/repo" worktree remove "$tmp/old"
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old) ||
  fail 'worktree.sh stops on the local branch that is linked to the issue' "$out"
case $out in *'--name fix/5-old --checkout'*) ;;
  *) fail 'worktree.sh checks out the local branch that is linked to the issue' "$out" ;;
esac
rm "$tmp/linked"
# With no worktree that holds it, --local makes one with git: gh would make a
# new remote branch of the name.
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old --local)
case $out in *"dry run: git worktree add $top/.claude/worktrees/fix/5-old fix/5-old"*) ;;
  *) fail 'worktree.sh --local makes a worktree for the local branch' "$out" ;;
esac
case $out in *'gh issue develop'*) fail 'worktree.sh --local makes or links a branch with gh' "$out" ;; esac
out=$(cd "$tmp/repo" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old --local --here)
case $out in *'dry run: git switch fix/5-old'*) ;;
  *) fail 'worktree.sh --local --here checks the local branch out where it is' "$out" ;;
esac

# A session in a linked worktree, as one that claude --worktree started, takes
# the branch where it is while that worktree holds no other work. Changes, or a
# commit that origin's default branch lacks, are another session's work, as its
# pull request: the branch gets a worktree of its own (#404).
git -C "$tmp/repo" update-ref refs/remotes/origin/trunk HEAD
git -C "$tmp/repo" worktree add -q -b feat/1-a "$tmp/wt" HEAD
wt=$(git -C "$tmp/wt" rev-parse --show-toplevel)
own="--checkout --worktree $top/.claude/worktrees/feat/5-b"
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b)
case $out in *"--name feat/5-b --checkout"$'\n'"$wt") ;;
  *) fail 'worktree.sh takes the branch where it is in a worktree with no other work' "$out" ;;
esac
# --local, as continue.md runs it, the same way.
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old --local)
case $out in *'dry run: git switch fix/5-old'$'\n'"$wt") ;;
  *) fail 'worktree.sh --local takes the local branch where it is in a worktree with no other work' "$out" ;;
esac
# The default branch moved on after the worktree was made: its HEAD is behind,
# and it holds no other work.
git -C "$tmp/repo" -c user.name=t -c user.email=t commit -q --allow-empty -m 'Merged since'
git -C "$tmp/repo" update-ref refs/remotes/origin/trunk HEAD
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b)
case $out in *"--name feat/5-b --checkout"$'\n'"$wt") ;;
  *) fail 'worktree.sh takes the branch where it is in a worktree that is behind the default branch' "$out" ;;
esac
# With no default branch of origin to compare with, nothing shows that the
# worktree is free. The read of the default branch comes before any write.
git -C "$tmp/repo" update-ref -d refs/remotes/origin/trunk
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b)
case $out in *"$own"*) ;; *) fail 'worktree.sh switches a worktree it cannot compare with the default branch' "$out" ;; esac
out=$(cd "$tmp/wt" && FAKE_FAIL='repo view' DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b 2>&1) &&
  fail 'worktree.sh goes on when it cannot read the default branch' "$out"
case $out in *'dry run:'*) fail 'worktree.sh writes before it reads the default branch' "$out" ;; esac
git -C "$tmp/repo" update-ref refs/remotes/origin/trunk HEAD
echo change >"$tmp/wt/file"
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b)
case $out in *"$own"*) ;; *) fail 'worktree.sh switches a worktree with changes to another branch' "$out" ;; esac
rm "$tmp/wt/file"
git -C "$tmp/wt" -c user.name=t -c user.email=t commit -q --allow-empty -m 'Work of another session'
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 feat/5-b)
case $out in *"$own"*"$top/.claude/worktrees/feat/5-b") ;;
  *) fail 'worktree.sh switches a worktree with a commit that the default branch lacks' "$out" ;;
esac
out=$(cd "$tmp/wt" && DRY_RUN=1 bash "$scripts/worktree.sh" 5 fix/5-old --local)
case $out in *"dry run: git worktree add $top/.claude/worktrees/fix/5-old fix/5-old"*) ;;
  *) fail 'worktree.sh --local switches a worktree with a commit that the default branch lacks' "$out" ;;
esac
git -C "$tmp/repo" worktree remove --force "$tmp/wt"

echo 'github_worktree_test: ok'
