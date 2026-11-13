# Merging a pull request

The *Merging* row of `SKILL.md` sends you here.

Merging is always `gh pr merge --squash --delete-branch`, with `--subject` and
`--body` in English, as every commit message is, also when the PR is in another
language. `--subject` is the PR title in English, then ` (#<PR>)`, so the title
takes the same `type: sentence` shape. Without it, GitHub takes the title, or a
one-commit branch's subject, as it is. `--body` is one list in the shape of
*Commits* in `SKILL.md` — at most five bullets — that sums up every commit on
the branch, not just the first: without it GitHub fills the squash commit from
a repository setting, by default every branch commit's full message in turn.
One commit per PR keeps `main` readable, and the branch has nothing left to say
once it is in. A closing word before a number in
the subject or the `--body` closes that issue when the commit lands, and
`closingIssuesReferences` does not show it: write both without one.

**The checks come first.** Before `gh pr merge`, wait for the checks of the
pull request, then list each one that did not pass. Run each command on its
own. Run the watch in the foreground, with a time limit of 10 minutes. When
the shell moves it to the background, stop it. Then read the list:

```bash
gh pr checks <PR> --watch --fail-fast >/dev/null
gh pr checks <PR> --json name,bucket,link --jq '.[] | select(.bucket != "pass" and .bucket != "skipping") | "\(.bucket) \(.name) \(.link)"'
```

The list decides, not the exit code of the watch: a cancelled check gives 0,
and no check at all gives 1.

- The list is empty, and the list command printed no error: merge.
- A `fail` or `cancel` line: do not merge. Give the person each line, and
  keep the worktree and the branch. The person decides: a fix, a new run of
  the check, or the merge all the same.
- Only `pending` lines: watch once more, the same way. Still `pending`: give
  the person each line, and wait for the person's word. A check can wait
  for days, for a person's approval or for a runner that is offline.
- `no checks reported`: a check can start late. Read again after a minute,
  and with still none, merge.

When the list command fails with another error, or GitHub refuses the merge,
as for a rule of the branch that the pull request does not meet, give the
error, and do not merge. The merge all the same, after a `fail`, `cancel` or
`pending` line, is the same `gh pr merge`, with no new wait. Add `--admin` or
`--auto` only when the person names that flag: `--admin` merges past a red
check, and `--auto` leaves the pull request open when the command ends.

Run the merge in the checkout that holds the branch, whatever directory the
session is in: `(cd <path> && gh pr merge …)`, where `<path>` is what
`git for-each-ref --format='%(worktreepath)' refs/heads/<branch>` prints. In
Codex, give `<path>` as the `workdir`. In the branch's linked worktree, `gh`
keeps the worktree and the local branch, and *Cleanup* decides on them. When
the command prints nothing, no checkout holds the branch, and any directory
will do.

**Finishing.** An issue goes stale the moment the code moves under it, and
GitHub does not notice: nothing corrects its text. So the PR closes the task,
every ride-along and every issue the change removes; first, before the pass
below reads the tracker, the label `in progress` comes off each issue that this
task labelled, in this session or an earlier one, and that has it still, closed
or open, with `gh issue edit <n> --remove-label "in progress"`; under each
problem it fixed in an issue that stays open, it adds the line
`Done in #<PR>.`; an issue the description says `Part of` and the merge closed
anyway — `gh issue view 15 --json state` shows it — is reopened, with a
comment that names the PR; a duplicate still held for the reproduction is
closed or commented on, by *Its duplicates close first* in `take-in.md`; and
the same pass updates every open issue on the changed code whose text the
change just falsified.

*Finishing* reads the merged code in a new checkout, outside every checkout.
The branch's worktree is not the merged code when the default branch moved
after the branch's last push. Make an empty directory with `mktemp -d`, and
give the path it prints to every command after it, as it is:

```bash
git fetch origin
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
git worktree add --detach <the mktemp path> origin/<the default branch>
```

Remove it when *Finishing* ends or stops, with
`git worktree remove --force <the mktemp path>`.

To find the open issues on the changed code, run `collect.sh filing`
(`tracker.md`) with every file that `gh pr diff <PR> --name-only` prints, and
the old path of each file the PR renamed. A scout then checks the open issues
that have an entry in the file of `collect.sh`. In Codex, the agent does this
job itself (`tracker.md`). The job is `Job: citations.`, with that checkout as
`Tree:`, and under it one `Decision <n>: <one line>` for each thing the PR
decided. That is a rule, a behaviour or a contract that it changed, a
choice that it made, a way that it rejected, a defect that it removed, and a
number that it changed, as a count or a size that an issue can quote. Take
them from the PR description with its `## Review`, and from each ADR or PDR
that it adds or changes. Count again each number that the merged code holds:
a description can be older than the last fix. When a check sets its limit,
count it as that check counts it. For each changed file with a size limit of
its own, as a cap on its characters that a test sets, or on the `debt` list
of a size check, add a decision with its new size and the check's limit, also
when the description does not give them.

Check each citation that moved or is gone, and each sentence that the scout
gives as false. Correct them by *Filing one next to an existing issue* in
`filing.md`: the body says what was decided and in which PR, and a false title
is rewritten too. A host's title still names every problem in it. A problem
marked `Done in #<PR>.` needs no other correction, and an issue with a problem
left in it stays open. A question that the PR answered is marked answered. A
proposal that it ruled out is rewritten. An issue whose premise is gone closes
with a comment that names the PR. A busy issue gets only the one-line comment
and stays open, as *Filing one next to an existing issue* says. The limit of
two added findings does not stop a correction: it is for added findings.

The last step reads the session for defects in this plugin: *The session at
the end* in `filing.md`.

**Cleanup.** Do it when the person chose merge and clean up, after
*Finishing*. Run in the branch's linked worktree, `gh pr merge --delete-branch`
deletes only the remote branch: it prints `skipping local delete`, and the
worktree and the local branch stay. Run in another checkout, `gh` 2.103
removes that worktree with `git worktree remove` and the local branch with
`git branch -D`. `gh` does not list the ignored files or check the branch
head, and when the removal succeeds, it prints nothing without a TTY. That is
why the merge runs in the worktree. When the branch has no linked worktree,
`gh` deletes the local branch itself, and nothing is left to clean up.

First leave the worktree, the way the session came in. In Claude Code, a
session that `EnterWorktree` moved there leaves with `ExitWorktree` and
`keep`: `remove` does not remove a worktree entered by its path.
`ExitWorktree` does nothing for a session that moved there in any other way,
as with `cd` after `worktree.sh`: that session runs both commands itself,
each with `git -C <the main checkout>`. Only a session that started in the
worktree, as with `claude --worktree` or `codex --worktree`, cannot leave it:
give the person the two commands below, to run after the session ends. In
Codex, the main checkout is the `workdir` of both commands. Run them from the
main checkout, the first line of `git worktree list`:

```bash
git worktree remove <path>
git branch -D <branch>
```

`git worktree remove` refuses a tree with changes or untracked files: then
keep both, and name the files. It deletes the ignored files with no word, so
list them first with `git -C <path> status --short --ignored`. When one of
them is not made again by the build or the package manager, as `.env` or a
local database, keep both, and name it. A squash merge leaves no commit of
the branch on the default branch, so git cannot see that the branch is
merged. Run `-D` only when `git rev-parse <branch>` prints the `headRefOid`
of `gh pr view <PR> --json headRefOid`. Otherwise keep the branch, and name
its commits that the pull request does not have. When both are gone, say
that nothing waits, and that the session can close. Otherwise say what
stays, and why.
