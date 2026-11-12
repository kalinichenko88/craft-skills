# Plan the roadmap

The person asks for a roadmap, or a milestone has no open task left and the
person asks to plan again. The run reads the documents of the product and
the tracker, talks through what they leave open, and proposes the whole
plan: the milestones in order, each with its goal and its `Done when`, the
new tasks of each milestone, their dependencies, and the current milestones.
After a milestone with no open task, the plan also says whether to close it.
The run writes nothing to the tracker before the person approves the plan,
and one approval covers all of it.

Not covered yet:

- a milestone whose title is not in the form `M<n> · <name>`, which the plan
  keeps;
- the due dates of the milestones;
- a task that is split into smaller tasks;
- a dependency that would make a task outside `Later` wait on a task in
  `Later`, and a chain of dependencies that comes back to its first task;
- the answer that changes a part of the plan, and the answer no;
- the new tasks with no label or no milestone, whose triage is a part of a
  plan again;
- a plan again that the person asks for while the milestone has open tasks;
- the view of the plan that the run sets up after the writes.

## A roadmap before its approval

Given:
- the repository has no milestone and no task
- `docs/product.md` describes the users of the product, its goal, and what
  its first demo shows
When: the person writes "Plan the roadmap"
Then:
- the person is asked a question about the plan
- the run waits
Never:
- a milestone is created
- a task is created
- a dependency is created

## The approval of a roadmap

Given:
- the repository has no milestone and no task
- an earlier run proposed a plan and asked the person to approve it
- in that plan, `M1 · First demo` is the current milestone; its goal is that
  a new user signs up and sees the dashboard
- in that plan, the `Done when` of `M1 · First demo` has two outcomes: a new
  user signs up, with the task Add the sign-up form, and the user sees an
  empty dashboard, with the task Show an empty dashboard
- in that plan, Show an empty dashboard waits on Add the sign-up form
- in that plan, `M2 · Payments` comes after `M1 · First demo`, with the task
  Take a card payment, and `Later` comes last
When: the person answers yes
Then:
- the milestones `M1 · First demo`, `M2 · Payments` and `Later` exist
- the task Add the sign-up form is open, in `M1 · First demo`
- the task Show an empty dashboard is open, in `M1 · First demo`
- the task Take a card payment is open, in `M2 · Payments`
- Show an empty dashboard waits on Add the sign-up form
- the `Done when` of `M1 · First demo` names the id of Add the sign-up form
  in its outcome a new user signs up
- the `Done when` of `M1 · First demo` names the id of Show an empty
  dashboard in its outcome the user sees an empty dashboard
- `M1 · First demo` is the current milestone
- after the writes, the person is given the plan as the tracker holds it
Never:
- the person is asked again to approve the plan
- two tasks have one title
- `M2 · Payments` is a current milestone

## A plan again after the last task of a milestone

Given:
- `M1 · First demo` is open and the current milestone; its tasks #21 and #22
  are closed
- `M2 · Payments` is open, after `M1 · First demo`; task #31 is open and
  free, in `M2 · Payments`
When: the person writes "M1 has no open task left. Plan again"
Then:
- the person is asked whether to close `M1 · First demo`
- the proposal gives the `Done when` of `M2 · Payments`, with the tasks of
  each outcome
- the proposal makes `M2 · Payments` the current milestone
- the run waits
Never:
- `M1 · First demo` is closed
- the text of `M2 · Payments` changes

## The approval of a plan again

Given:
- `M1 · First demo` is open and the current milestone; its tasks #21 and #22
  are closed
- `M2 · Payments` is open, after `M1 · First demo`; task #31 is open and
  free, in `M2 · Payments`
- an earlier run proposed to close `M1 · First demo`, to give
  `M2 · Payments` the `Done when` with one outcome, a customer pays by card,
  with task #31, and to make `M2 · Payments` the current milestone; it asked
  the person to approve that plan
When: the person answers yes
Then:
- `M1 · First demo` is closed
- the `Done when` of `M2 · Payments` names #31 in its outcome a customer
  pays by card
- `M2 · Payments` is the current milestone
Never:
- #31 is closed
- the milestone of #31 changes
