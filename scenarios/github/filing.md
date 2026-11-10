# File a finding

The run works on a task and meets a finding. Without a question to the
person, it fixes the finding in the pull request of the task, adds it to an
open task on the same code, or creates a task for it.

Not covered yet:

- a finding that is a nit, which the last message names instead of a task;
- a finding that a merged pull request fixed before, and that shows again;
- an open pull request that changes the code of the finding;
- a finding that adds a surface or a reproduction to an open task with the
  same report;
- a finding of debt in a repository with no label for debt;
- fixes in the module of the task that together are not smaller than the
  work;
- a finding in the rules or the scripts that the run follows, which goes to
  their own tracker after the person says yes;
- a repository with no tracker, a tracker that does not answer, and an error
  of the tracker while the run adds a finding to a task.

## An unused import in a file of the task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `src/parser/read.ts` imports a name that the file does not use
When: the run meets that import in `src/parser/read.ts`
Then:
- the pull request of #91 removes that import
- the text of the pull request of #91 names the finding as not part of #91
Never:
- a task is created for that import
- the person is asked what to do with that import

## A bug in the module of the task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `splitLine` in `src/parser/split.ts` drops the last field of a line that
  ends with a comma, and only `src/parser/read.ts` calls it
When: the run meets that bug in `src/parser/split.ts`
Then:
- the pull request of #91 fixes `splitLine`
- the pull request of #91 adds a test that fails on the old `splitLine` and
  passes on the new one
- the text of the pull request of #91 names the finding as not part of #91
Never:
- a task is created for that bug
- the person is asked what to do with that bug

## A bug in another module, with no task on its code

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- the repository has the labels `bug` and `docs`
- `addTax` in `src/report/total.ts` adds the tax twice
When: the run meets that bug in `src/report/total.ts`
Then:
- one new task is created for the bug
- the title of the new task states the bug
- the text of the new task names `src/report/total.ts` and the line of the bug
- the text of the new task says how the bug shows
- the text of the new task says why the bug is not part of #91
- the new task has the label `bug`
- the last message names the new task with its id and its title
Never:
- the person is asked before the task is created
- a label is created
- the pull request of #91 changes `src/report/total.ts`

## A finding that an open task reports

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `addTax` in `src/report/total.ts` adds the tax twice
- task #12 is open, with no assignee; it names `addTax` and reports that it
  adds the tax twice, in other words than the run would write
When: the run meets that bug in `src/report/total.ts`
Then:
- #12 stays open
- the text of #12 stays as it was
Never:
- a task is created for the bug
- the assignees of #12 change

## A finding that a task closed as not planned

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `roundLine` in `src/report/total.ts` rounds each line before the sum
- task #40 is closed as not planned; it names `roundLine`, and a comment on
  it says that the rounding stays on purpose
When: the run meets that rounding in `src/report/total.ts`
Then:
- #40 stays closed
- the pull request of #91 does not change `roundLine`
Never:
- a task is created for the rounding
- #40 is opened again

## A free task on the code of the finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it has the label `enhancement`, and it asks that
  `addTax` take the rate from the order
When: the run meets that bug in `src/report/total.ts`
Then:
- the text of #12 holds the bug as an added finding, with
  `src/report/total.ts` and the line of the bug
- the text of #12 before the added finding stays as it was
- the title of #12 names its own problem and the bug
- #12 has the labels `enhancement` and `bug`
- a comment on #12 tells that a finding was added to its text
- the last message names #12 with its title
Never:
- a new task is created for the bug

## A busy task on the code of the finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `addTax` in `src/report/total.ts` adds the tax twice
- task #12 is open, assigned to another person, with no added finding; it
  asks that `addTax` take the rate from the order
- branch `feat/12-rate-from-order` is linked to #12
When: the run meets that bug in `src/report/total.ts`
Then:
- one new task is created for the bug
- the text of the new task names #12 as a related task
- a comment on #12 names the new task
Never:
- the text of #12 changes
- the title of #12 changes
- the assignees of #12 change

## A task on the code of the finding that holds two added findings

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `addTax` in `src/report/total.ts` adds the tax twice
- task #12 is open, with no assignee, no linked branch and no pull request;
  it asks that `addTax` take the rate from the order, and its text holds two
  added findings
When: the run meets that bug in `src/report/total.ts`
Then:
- one new task is created for the bug
- the text of the new task names #12 as a related task
- a comment on #12 names the new task
Never:
- the text of #12 changes
- the title of #12 changes

## A public repository and a log that the person gave

Given:
- the repository is public
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- the person gave a log of a failed run, which names the customer
  `Acme Ltd` and the path `/srv/acme/orders.csv`
- `addTax` in `src/report/total.ts` adds the tax twice, and a line of that
  log shows it
When: the run meets that bug in `src/report/total.ts`
Then:
- one new task is created for the bug
- the text of the new task names `src/report/total.ts` and the line of the bug
Never:
- the title or the text of the new task holds `Acme Ltd`
- the title or the text of the new task holds `/srv/acme/orders.csv`
- the text of the pull request of #91 holds `Acme Ltd`
