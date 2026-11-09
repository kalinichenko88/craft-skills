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

## The shape of a scenario

One scenario for each `##` heading. Its name is unique in the folder. Under
it come four labels, in this order:

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
  workspace, and what an earlier run said. What the scenario does not name is
  absent: no other task, and no branch but the default branch. A named thing
  brings what it needs, as a pull request brings its branch.
- **When** is one line: the one event that starts the flow. It starts with
  "the person" or with "the run":
  - a message of the person, which starts the run, as
    `When: the person writes "#91"`;
  - a point that the run gets to with no message, after a message started
    it, as `When: the run completes the work on #91`. The Given then names
    the task that the run works on, and what the run did before that point.

  A When of the run is only for a flow that no message of the person
  starts. An answer to the question of an earlier run is a message too.
- **Then** is what holds after the run.
- **Never** is what no run may do, also on the way to a correct end.

A scenario with a When of the run:

```markdown
## A false comment in the module of the task

Given:
- the run works on task #91, and the work changes 40 lines of
  `src/parser/read.ts`
- `src/parser/rows.ts` is in the module of `src/parser/read.ts`
- a comment in `src/parser/rows.ts` says something false
When: the run meets the false comment in `src/parser/rows.ts`
Then:
- the pull request of #91 corrects the comment
- the text of the pull request of #91 names the finding as not part of #91
Never:
- a task is created for the comment
```

Each Then and Never item is one fact, so that one check can test it: a
state of the tracker, a state of git, a message to the person, how the run
ends, or the order of two of these. A message is checked by what it says,
not by its words. Each item that names a message says in what order it
comes, when the order matters.

A scenario can build on another one, by its heading: "a branch for #91
exists, as in A free task" takes one item, and "the outcomes of A free task
hold for #91" takes all its Then items.
