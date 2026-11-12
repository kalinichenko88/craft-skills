# Scenarios

A scenario says what a flow does, as seen from outside: the state of the
tracker and of git after the run, and what the person was told or asked. It
names no agent host, no command and no subagent. Each implementation of a flow
does it in its own way. craft is one of them; another one needs only this
folder.

A word for a thing that an implementation keeps in its own way comes from
[`TERMS.md`](TERMS.md). Git words keep their git meaning, and other words
their plain meaning.

## The layout

One file for each flow, in the folder of the skill that owns it:
`scenarios/<skill>/<flow>.md`. The file starts with a `#` title, one
paragraph on what starts the flow, and a list of what the file does not cover
yet.

| File | The flow |
| --- | --- |
| [`github/take-in.md`](github/take-in.md) | The person names one task, and the run takes it into work. |
| [`github/filing.md`](github/filing.md) | The run meets a finding outside its task, and fixes it in the pull request of the task, adds it to a task, creates a task for it, or files nothing when a task already reports it or settles it. |
| [`github/pull-request.md`](github/pull-request.md) | The run ends the work on a task and opens its pull request. On the person's answer, it merges the pull request or leaves it open; after a merge, it corrects the open tasks that the merge makes false, closes the duplicates that it left for a reproduction, asks whether to report a defect of the implementation that the work showed, and removes the workspace of the task when the person asks for it. |
| [`product/worth.md`](product/worth.md) | The person asks for a feature, or a review shows that a feature gives its users nothing, and the run gives the person a worth report on it: before the work, or after that review. On the person's answer, it writes the product decision, puts the task off to `Later`, or closes it as not planned. |
| [`review-loop/review.md`](review-loop/review.md) | Reviews read the change on a branch in rounds, when the run ends the work on a task, when the person asks for a review or for a pull request, when the person asks the run to handle the review comments on the pull request, or when the person answers a question of an earlier run. For a task, or when the person asked for a pull request, the run then opens the pull request and asks whether to merge it, in the same run. A spec and a plan that the run writes get their own reads. |
| [`roadmap/next.md`](roadmap/next.md) | The person asks what to take now or what can run in parallel, and the run gives one task, or at most three lanes on the path to the first current milestone. |
| [`roadmap/milestone.md`](roadmap/milestone.md) | The person asks what is left to close a milestone, or what can be taken from `Later`, and the run gives its open tasks with what each waits on, or the free tasks of `Later`. |
| [`roadmap/later.md`](roadmap/later.md) | The person puts a task off, and the run moves it into `Later`, or moves nothing and asks what to do with the tasks that wait on it. |
| [`roadmap/plan.md`](roadmap/plan.md) | The person asks for a roadmap, or to plan again after the last task of a milestone, and the run proposes the whole roadmap and writes it after one approval. |
| [`roadmap/triage.md`](roadmap/triage.md) | The person asks to triage the open tasks with no label, no milestone or the label `question`, and the run proposes one table with a duplicate, a label, a milestone and a comment for each, and writes it after one approval. |

## The shape of a scenario

One scenario for each `##` heading. Its name is unique in `scenarios/`, over
the files of every skill. Under it come four labels, in this order:

```markdown
## A task that another person is assigned to

Given:
- task #91 is open, assigned to another person
When: the person writes "#91"
Then:
- the person is told that #91 is assigned to another person
- the run waits
Never:
- the assignees of #91 change
- a branch for #91 is created
```

- **Given** is the state before the When: the tasks, the branches, the
  workspace, and what an earlier run said. It can also say what a review
  reports, as `round 1 reports one defect: …`: a review is outside the run,
  as the tracker is. What the scenario does not name is absent: no other
  task, no branch but the default branch, and no report of a review. A named
  thing brings what it needs, as a pull request brings its branch.
- **When** is one line: the one event that starts the flow. It starts with
  "the person" or with "the run":
  - what the person writes, which starts the run, as
    `When: the person writes "#91"`;
  - a point that the run gets to by itself, after the person started it,
    as `When: the run meets a finding in src/parser/read.ts`. The Given
    then names what the run works on, as task #91, and what the run did
    before that point. It holds a state that brings each correct run to
    that point: a test cannot make the run get there.

  Take a When of the run only when nothing that the person writes starts
  that point. An answer to a question of an earlier run is a When of the
  person.
- **Then** is what holds after the run.
- **Never** is what no run may do, also on the way to a correct end.

A scenario with a When of the run:

```markdown
## A function that no code calls, in a file of the task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `src/parser/read.ts` holds a function that its module does not export
  and that no code calls
When: the run meets that function in `src/parser/read.ts`
Then:
- the pull request of #91 removes that function
- the text of the pull request of #91 names the finding as not part of #91
Never:
- a task is created for that function
```

Each Then and Never item is one fact, so that one test can check it: a
state of the tracker, a state of git, a message to the person, how the run
ends, or the order of two of these. A message is checked by what it says,
not by its words. Each item that names a message says in what order it
comes, when the order matters.

A wait and a stop are the exception to one test for each item. They end a
run in the same state, and differ only in what the next text that the person
writes does (`TERMS.md`). So a test of the run checks only that nothing more
changed. The difference shows in the next run: in a scenario whose Given
holds the earlier run, as the scenarios of an answer to a question do.

A scenario can build on another one, by its heading: "a branch for #91
exists, as in A free task" takes one item, and "the outcomes of A free task
hold for #91" takes all its Then items.

## Reading the scenarios against each other

[`check.md`](check.md) is a prompt for a model. It reads the scenarios of
all the files one pair at a time, and reports two outcomes for one state, a
word in two meanings, an item that one test cannot check, and a state that
no scenario covers, with a table of that coverage. It changes no file: a
person reads each finding and decides on it. One run finds a part of the
conflicts, not all of them.
