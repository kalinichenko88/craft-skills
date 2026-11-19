# The summary and the pull request

*Worth first*, *The rounds*, *A review of the architecture* and *Fixes from
other places* are sections of `SKILL.md`, next to this file.

## The summary

When the review ends, run the repository's own check on the final branch.
With an architecture file on the branch, the check also runs
`bash <dir>/../architecture/scripts/invariants.sh --new-since <base> HEAD`,
with `<base>` of step 1 of *The rounds*: a failing hit marked `new` fails
the check. The review of the architecture reads only the range of
round 1, and a fix of a later round can break an invariant.
Then report in this order. Each item is one line, except **Change:**, which
is a list. With no person and a verdict of `craft:product` other than
`do it`, its report comes first in the summary, before **Change:**. When the
summary is not the turn's last message, the report starts that message too.

- **Change:** what the branch changed as a whole, for a person who did not
  follow the session: one to five bullets. In English, they are the merge's
  `--body` in `merge.md` of the `craft:github` skill.
- **Rounds:** the verdict of *Worth first*, or why it did not run.
  `ponytail-review`'s lines saved, or why it did not run. The walk: its
  tool and the count of findings it confirmed, or why it did not run. Each
  round, its level and range, and the count of findings it confirmed. The
  last pass, the same way. At `xhigh`, the Codex review: its range and the
  count of findings it confirmed, or why it did not run. At `high` and
  `xhigh`, and for a change to tests only, the review of the tests, the same
  way. The review of the architecture, the same way. With no architecture
  file and no ADR folder, once per pull request, the line that
  `craft:architecture` can write the first file, unless the project
  keeps none. The security review's
  result. The check's result. For a change to documents only: round 1; the
  review of the architecture, when it ran; the Codex read and the count of
  findings it confirmed, or why it did not run;
  and `documents only` for each of the last pass and the security review that
  did not run.
- **Decisions:** each choice you made: the finding, the choice, the reason.
  Each question on business logic, with the person's answer, or `open`.
- **Fixed:** what changed and in which file, the commit, and any side effect
  a fix had elsewhere.
- **Declined:** each finding that did not survive, with the reason.
- **Filed:** the issues opened or added to, with their numbers and titles.
  After them, marked `not filed`, each finding outside the task that
  `craft:github` calls a nit or rules out.
- **Docs:** the docs the branch changed, or `docs impact: none` and why, as
  *Docs move with the change* in the global prompt asks.

The pull request description carries the same summary under `## Review`, and
each later fix commit adds its lines there. A later review then recognises a
declined finding instead of arguing it again.

In a public repository, the `## Review` section and each reply to a review
comment are public. An example from a private source goes in without its
names, numbers, titles, paths or code: *Public repositories* in the
`craft:github` skill says what a private source is and what to write
instead.

## The pull request

Go on in the same turn when all of these hold:

- The task is an issue taken into work, or the person asked for a pull request.
- The branch is not the default branch.
- The check on the final branch passes.

Then:

1. Push the branch, in a command of its own. When the push succeeds and
   the branch has an open pull request, add the summary's lines to its
   `## Review`. When it succeeds and the branch has none, open the pull
   request through the `craft:github` skill, with the summary under
   `## Review`.
2. When questions on business logic are still open, ask them. An answer that
   needs no fix goes into `## Review`. The fix for an answer, when it needs
   one, goes through *Fixes from other places* and *The summary*, and then
   through this section again, its conditions first.
3. When the last push in step 1 succeeded, the pull request is open and no
   question on business logic is open, show the `gh pr merge` command that
   `merge.md` in that skill gives. Ask one question with three answers:
   merge and clean up, merge only, or do not merge. When
   `git for-each-ref --format='%(worktreepath)' refs/heads/<branch>` prints
   nothing or the first path of `git worktree list`, the branch has no linked
   worktree: ask only whether to merge, and do no *Cleanup*. When step 4 of
   *The rounds* stopped the rounds, the question has one more answer: up to
   three more rounds, the first on the fix of the defects that step 4 left
   open. After those rounds come *The summary* and this section again, its
   conditions first.
   On a merge answer, run the merge in the checkout that holds the branch,
   as that file says. When it succeeds, file the defects that step 4
   left open, through that skill. Its Boy Scout check does not apply to
   them: the merged pull request takes no more fixes. Then do *Finishing*
   from that skill, and on merge and clean up, its *Cleanup* after that.
   When it fails, give the error, and keep the worktree and the branch.

Only the merge and the open questions wait for the person.
