# 0009 The next task and the parallel work come from the goal of the nearest milestone, in at most three lanes

- Status: accepted
- Level: feature
- Date: 2026-11-12

## Decision

We will give "what can I take now", "what is the priority" and "what can run
in parallel" one answer: the path from now to the goal, with the top bug
beside it, in at most three lanes of new work. The goal is the nearest milestone, the first current
one. Its `Done when` is a list of outcomes that someone can check, each with
the issues that it needs. Lane 1 holds those issues, with any label, and what
they wait on. The top bug that can run takes the next lane, so that the most
important bug reaches the developers early; bugs rank by milestone first. A
goal task that can run beside them takes the last lane before the other bugs,
tests and improvements do. Lanes 2 and 3 each hold one area of the code.
Work in progress is no lane, and no lane overlaps with it.

When the `Done when` names only closed issues, the next milestone is the goal,
when there is one, and the agent offers to re-plan the first one. When it names no issue, lane 1
is the milestone's issues without the bug label, and what they wait on, and the agent
offers to rewrite the `Done when` as a list. With no milestone, the agent
picks lane 1 by the current goal of `PRODUCT.md`, and says that the pick is
its own.

## Rests on

- With the old rule, 10 of 10 Opus runs on a fixture tracker put a task that
  the goal does not need first, or into the parallel set: 5 of 5 gave a test
  database task as the task to take, and 3 of 5 parallel sets left out a goal
  task (#278, 2026-11-11).
- A `Done when` stays true while its milestone is open: each goal task is
  named, and a new one gets its point. On 2026-11-11 it did not hold on this
  tracker: the 6 issues that the `Done when` of `M3 · Skills hold in real
  runs` names were closed, and none of its 16 open issues was named. So the
  note that offers a re-plan is part of the decision.
- The person runs several sessions at once, and wants the path to a working
  application, split into lanes that do not meet (#278, 2026-11-09).

## Revisit when

A lane 1 on a real tracker leaves out a task that the goal needs twice, or
the person declines the re-plan that a note offers twice.

## Options considered

- `next.sh` reads the issues that the `Done when` names: chosen. It needs no
  new `gh` call, and the answer does not rest on the model.
- The text alone: the agent reads the `Done when` and judges each task. No
  run showed it as reliable, and it keeps goal tasks with the bug label off
  the path.
- Triage moves the work that the goal does not need out of the milestone:
  16 moves on this tracker now, and the old rule still ranks by age.
- Lane 1 as one worker, every goal task in turn, with lanes 2 and 3 for
  other work: the goal waits while both of them hold work that it does not
  need.
- Goal tasks before every bug in lanes 2 and 3: an important bug waits while
  the goal holds all three lanes. The person wants bugs, the important ones
  first, to reach the developers early (2026-11-12).
- No cap on the lanes, as before: the answer can give more lanes than the
  person can run.

## Links

#278, PR #35, `skills/roadmap/SKILL.md`, `skills/roadmap/planning.md`
