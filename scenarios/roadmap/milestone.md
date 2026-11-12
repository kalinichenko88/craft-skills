# Tell what is left in a milestone

The person asks what is left to close a milestone, or what can be taken from
`Later`. The run reads the tracker and gives the open tasks of that
milestone, each task after the tasks it waits on, and each with its state:
free, busy, or what it waits on. From `Later`, it gives the free tasks. The run changes nothing in the tracker or in the repository.

Not covered yet:

- the count of the closed tasks of a milestone, and its due date;
- a task that is split into smaller tasks;
- a task in `Later` that waits on another task;
- the question with no milestone, whose answer gives each open milestone,
  and the tasks with no milestone;
- a run of another flow that reads the roadmap.

## What is left in a milestone

Given:
- `M1 · First demo` is open, with tasks #20, #21, #22 and #25
- task #20 is closed
- task #21 is open and free
- task #22 is open, and waits on #21
- task #25 is open, assigned to another person, with the label `in progress`
When: the person writes "What is left to close M1?"
Then:
- the person is given #21, #22 and #25 as the open tasks of
  `M1 · First demo`
- #21 comes before #22
- the person is told that #21 is free and waits on no task
- the person is told that #22 waits on #21
- the person is told that #25 is assigned to another person
Never:
- #20 is given as a task that is left
- a label, an assignee or the milestone of a task changes

## A task that waits on a task of a later milestone

Given:
- `M1 · First demo` and `M2 · Payments` are open
- task #22 is open, in `M1 · First demo`, and waits on #31
- task #31 is open and free, in `M2 · Payments`
When: the person writes "What is left to close M1?"
Then:
- the person is told that #22 waits on #31
- the person is told that #31 is in `M2 · Payments`
Never:
- the milestone of #31 changes

## The free tasks of Later

Given:
- the milestone `Later` holds tasks #60 and #61, both open
- task #60 is free
- task #61 is assigned to another person, with the label `in progress`
When: the person writes "What can I take from Later?"
Then:
- the person is given #60 as a task to take
Never:
- #61 is given as a task to take
- the milestone of #60 changes
