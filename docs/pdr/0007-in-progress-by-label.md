# 0007 An assignee says who may take an issue, and the label in progress says that its work runs

- Status: accepted
- Level: feature
- Date: 2026-11-11

## Decision

We will read an issue's assignee as the account that may take it, not as a
sign that its work runs. An issue whose one mark is the person's own
assignee is free for the person: take-in takes it with no question, the
roadmap offers it, and it can be a duplicate, a ride-along or a host. An
issue that another person is assigned to, and the person is not, stays
theirs. The label `in progress` says that the work runs: each take-in puts it
on with the assignee, as do a ride-along at its verdict and "stay on this
branch", and *Finishing* takes it off. A linked branch and an open pull
request that closes the issue make it busy too. No step takes the label off
work that stopped: the person does.

## Rests on

- The plugin is for small teams (`docs/PRODUCT.md`), where an assignee often
  plans who does a task before anyone starts it. The person's decision on
  #285, 2026-11-11.
- On two public team trackers, 8 of the 16 open issues with an assignee had
  no linked branch and no pull request: 2 of 7 on cli/cli and 6 of 9 on
  astral-sh/ruff, in the newest 300 open issues of each, on 2026-11-11. On
  this tracker it was 1 of 4 (#231), and on a private tracker that uses the
  plugin 0 of 2.
- A person works on several computers, and opens the pull request at the end
  of the work, so a branch or a pull request alone comes too late to say
  that the work started. The person, on #285.
- GitHub's API has no call that links an existing branch to a second issue
  (`createLinkedBranch` makes a new branch), so a ride-along gets no branch
  of its own to show that its work runs.

## Revisit when

Two sessions take the same issue because one of them did not put the label
on, or the label stays on stopped work so often that the person asks for a
step that takes it off.

## Options considered

- Any assignee makes an issue busy, as before (PR #155): an issue assigned at
  creation or to plan the work looks taken when no work started.
- The Status field of a GitHub Project: it needs the `project` scope on each
  machine and a project in each repository, and gives the scripts nothing
  that a label does not.
- A linked branch or an open pull request only: the work on several
  computers and the pull request at the end leave a started task without
  either, and a ride-along has no branch of its own.
- An assignment in the first minute after creation as a plan: it misses an
  assignment by hand later.
- The label `in progress`, beside a linked branch and an open pull request:
  chosen.

## Links

#285, PR #155, PR #124, PR #181, `skills/github/tracker.md`,
`scenarios/TERMS.md`
