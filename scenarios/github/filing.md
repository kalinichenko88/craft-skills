# File a finding

The run works on a task, or on a change that the person asked for, and
meets a finding. Without a question to the person, it fixes the finding in
the pull request of the task, adds it to an open task on the same code, adds
a comment to an open task with the same report, or creates a task for it.
When a task already reports the finding or decided it, or an open pull
request fixes it, the run files nothing. The last message names a name or a
wording that no rule of the repository asks for, and a finding that the run
cannot file. A defect of the implementation is the exception to the
question: it goes to the tracker of the repository of the implementation,
after the person says yes.

Not covered yet:

- a reproduction that a finding adds to an open task with the same report;
- an edge case that no real input of the repository holds;
- a defect of the implementation that the default branch of its repository
  no longer has, a defect of the implementation that the run meets in the
  repository of the implementation, and the answer no to a task for a
  defect of the implementation.

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

## A defect in the module of the task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `src/parser/read.ts`
- `src/parser/read.ts` is the only caller of `splitLine` in
  `src/parser/split.ts`, and the run read `splitLine`
- the docstring of `splitLine` says that a line with n commas gives n + 1
  fields, and `splitLine` drops the last field of a line that ends with a
  comma
When: the run meets that defect in `src/parser/split.ts`
Then:
- the pull request of #91 fixes `splitLine`
- the pull request of #91 adds a test that fails on the old `splitLine` and
  passes on the new one
- the text of the pull request of #91 names the finding as not part of #91
Never:
- a task is created for that defect
- the person is asked what to do with that defect

## A defect in another module, with no task on its code

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- the repository has the labels `bug` and `docs`
- `addTax` in `src/report/total.ts` adds the tax twice
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the title of the new task states the defect
- the text of the new task names `src/report/total.ts` and the line of the
  defect
- the text of the new task says how the defect shows
- the text of the new task says why the defect is not part of #91
- the new task has the label `bug`
- the last message names the new task with its id and its title
Never:
- the person is asked before the task is created
- a label is created
- the pull request of #91 changes `src/report/total.ts`

## A finding that an open task reports

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- task #12 is open, with no assignee; it names `addTax` and reports that it
  adds the tax twice, in other words than the run would write
When: the run meets that defect in `src/report/total.ts`
Then:
- #12 stays open
- the text of #12 stays as it was
Never:
- a task is created for the defect
- the assignees of #12 change

## A finding that a closed task decided

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `roundLine` in `src/report/total.ts` rounds each line before the sum
- task #40 is closed; it names `roundLine`, and a comment on it says that
  the rounding stays on purpose
When: the run meets that rounding in `src/report/total.ts`
Then:
- #40 stays closed
Never:
- a task is created for the rounding
- #40 is opened again

## An open task with no assignee on the code of the finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it has the label `enhancement`, and it asks that
  `addTax` take the rate from the order
When: the run meets that defect in `src/report/total.ts`
Then:
- the text of #12 holds the defect as an added finding
- that added finding names `src/report/total.ts` and the line of the defect
- that added finding says how the defect shows
- that added finding says why the defect is not part of #91
- the text of #12 before the added finding stays as it was
- the title of #12 names its own problem and the defect
- #12 has the labels `enhancement` and `bug`
- a comment on #12 says that a finding was added to its text
- the last message names #12 with its title
Never:
- a new task is created for the defect

## A busy task on the code of the finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the label `bug`
- task #12 is open, assigned to another person, with no added finding; it
  asks that `addTax` take the rate from the order
- branch `feat/12-rate-from-order` is linked to #12
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the text of the new task names #12 as a related task
- a comment on #12 names the new task
Never:
- the text of #12 changes
- the title of #12 changes
- the assignees of #12 change

## A task on the code of the finding that holds two added findings

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the label `bug`
- task #12 is open, with no assignee, no linked branch and no pull request;
  it asks that `addTax` take the rate from the order, and its text holds two
  added findings
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the text of the new task names #12 as a related task
- a comment on #12 names the new task
Never:
- the text of #12 changes
- the title of #12 changes

## A public repository and a log that the person gave

Given:
- the repository is public
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- the person gave a log of a failed import, which names the customer
  `Acme Ltd` and the path `/srv/acme/orders.csv`
- `addTax` in `src/report/total.ts` adds the tax twice, and a line of that
  log shows it
- the repository has the label `bug`
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the text of the new task names `src/report/total.ts` and the line of the
  defect
Never:
- the title or the text of the new task holds `Acme Ltd`
- the title or the text of the new task holds `/srv/acme/orders.csv`
- the text of the pull request of #91 holds `Acme Ltd`
- the text of the pull request of #91 holds `/srv/acme/orders.csv`

## A feature outside the task, with no task on its code

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- the run read `README.md`, which lists "an export of the report to CSV"
  under *Planned*
- `writeReport` in `src/report/total.ts` writes the report as text only,
  and no task holds the export to CSV
- the repository has the labels `bug` and `enhancement`
When: the run meets that finding in `src/report/total.ts`
Then:
- one new task is created for the feature
- the title of the new task names its work as an action
- the new task has the label `enhancement`
- the last message names the new task with its id and its title
Never:
- the title of the new task states that the report has no export to CSV
- the person is asked before the task is created
- the pull request of #91 changes `src/report/total.ts`

## A defect in the module of the task with two ways to fix it

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `splitHeader` in `src/parser/header.ts` and `splitLine` in
  `src/parser/split.ts`
- `parseRows` calls `splitHeader` for the first line of a text
- `splitHeader` drops a comma inside quotes, and `splitLine` keeps it; the
  fix can make `splitHeader` call `splitLine`, or change the code of
  `splitHeader`
- the repository has the label `bug`
When: the run meets that defect in `src/parser/header.ts`
Then:
- one new task is created for the defect
- the text of the new task names `splitHeader`
- the new task has the label `bug`
Never:
- the pull request of #91 changes `src/parser/header.ts`
- the person is asked before the task is created

## A defect in the module of the task that code outside the module relies on

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the docstring of `splitLine` in `src/parser/split.ts` says that a line
  with n commas gives n + 1 fields, and `splitLine` drops the last field of
  a line that ends with a comma
- `importTable` in `src/import-table.ts` calls `splitLine`, and adds an
  empty last field itself for a line that ends with a comma
- the run read `src/parser/split.ts` and `src/import-table.ts`
- the repository has the label `bug`
When: the run meets that defect in `src/parser/split.ts`
Then:
- one new task is created for the defect
- the text of the new task names `splitLine`
- the text of the new task names `importTable`
Never:
- the pull request of #91 changes `src/parser/split.ts`

## A finding that no label of the repository fits

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the labels `documentation`, `question` and
  `in progress`, and no other label
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the new task has no label
Never:
- a label is created

## Two findings for the same open task in one run

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the docstring of `addTax` says that it rounds the tax to the nearest
  cent, and `addTax` rounds it down
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it has the label `enhancement`, and it asks that
  `addTax` in `src/report/total.ts` take the rate from the order
When: the run meets those two defects in `src/report/total.ts`
Then:
- the text of #12 holds the tax added twice as an added finding
- the text of #12 holds the tax rounded down as an added finding
- the title of #12 names its own problem and the two defects
Never:
- a new task is created for either defect

## An open task on the code of the finding that holds one added finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch and no pull request;
  it has the labels `enhancement` and `bug`, it asks that `addTax` take the
  rate from the order, and its text holds one added finding: `addTax`
  rounds the tax down
When: the run meets that defect in `src/report/total.ts`
Then:
- the text of #12 holds the tax added twice as a second added finding
- the first added finding of #12 stays as it was
- the title of #12 names its own problem and the two added findings
Never:
- a new task is created for the defect

## A feature on the code of an open task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- the run read `README.md`, which lists "an export of the report to CSV"
  under *Planned*
- `writeReport` in `src/report/total.ts` writes the report as text only,
  and no task holds the export to CSV
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it has the label `enhancement`, and it asks that
  `writeReport` put the date in the head of the report
When: the run meets that finding in `src/report/total.ts`
Then:
- the text of #12 holds the export to CSV as an added finding
- the title of #12 names its own work and the export to CSV
Never:
- a new task is created for the export to CSV

## A name that no rule of the repository asks for

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `writeReport` in `src/report/total.ts` keeps the sum in a value named
  `tmp2`
- no text of the repository has a rule for names
When: the run meets that name in `src/report/total.ts`
Then:
- the last message names `tmp2` in `src/report/total.ts`
Never:
- a task is created for that name
- the text of a task gets that name as an added finding
- the pull request of #91 changes `src/report/total.ts`

## A defect that a merged pull request fixed before

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- task #40 is closed as done; its text names `addTax` and reports that it
  adds the tax twice
- pull request #45, merged, names `addTax` in its text, made `addTax` in
  `src/report/total.ts` add the tax once, and closed #40
- commit `a1b2c3d` on the default branch, after #45 and before the branch
  of #91, makes `addTax` add the tax twice again, and the run read it
- the repository has the label `bug`
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the title or the text of the new task says that the defect of #40 shows
  again
- the text of the new task names #45
- the new task has the label `bug`
Never:
- #40 is opened again

## An open pull request that fixes the finding

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice, and no task names
  `addTax`
- pull request #50 of another person is open; its text names `addTax`, and
  it makes `addTax` add the tax once
When: the run meets that defect in `src/report/total.ts`
Then:
- #50 is open
- the text of #50 stays as it was
Never:
- a task is created for the defect

## An open pull request on the code of the finding that does not fix it

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice, and no task names
  `addTax`
- pull request #50 of another person is open; its text names `addTax`, and
  it makes `addTax` take the rate from the order, and keeps the second add
  of the tax
- the repository has the label `bug`
When: the run meets that defect in `src/report/total.ts`
Then:
- one new task is created for the defect
- the text of the new task names #50
Never:
- the text of #50 changes

## A finding that shows the defect of an open task in one more place

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the run read `src/report/refund.ts`, whose `refundTax` calls `addTax`, so
  that a refund gets the tax twice too
- task #12 is open, with no assignee; it reports that `addTax` adds the tax
  twice on an order, and does not name a refund
When: the run meets that defect in `src/report/refund.ts`
Then:
- a comment on #12 says that a refund gets the tax twice too
- that comment names `refundTax`
- the text of #12 stays as it was
Never:
- a task is created for the defect
- the title of #12 changes

## A finding of debt in a repository with no label for debt

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `sumLines` and `sumRefunds` in `src/report/total.ts` are two copies of 30
  lines that differ in one name, and no task names them
- the repository has the labels `bug` and `enhancement`, and no label for
  debt
When: the run meets those copies in `src/report/total.ts`
Then:
- one new task is created for the copies
- the new task has the label `debt`
- the label `debt` is created before the new task
Never:
- the pull request of #91 changes `src/report/total.ts`

## Fixes in the module of the task that together are not smaller than the work

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 10 lines of `parseRows` in `src/parser/read.ts`
- `src/parser/read.ts` is the only caller of `splitLine` and of `joinLine`
  in `src/parser/split.ts`, and the run read both
- the docstring of `splitLine` says that a line with n commas gives n + 1
  fields, and `splitLine` drops the last field of a line that ends with a
  comma
- the docstring of `joinLine` says that it puts quotes around a field that
  holds a comma, and `joinLine` puts none
- each defect has one way to fix it, and each fix changes 6 lines with its
  test
- the repository has the label `bug`
When: the run meets those two defects in `src/parser/split.ts`
Then:
- the pull request of #91 fixes one of the two defects
- one new task is created for the other defect
- the text of the pull request of #91 names the fixed defect as not part of
  #91
Never:
- the pull request of #91 fixes both defects

## A defect of the implementation that the run meets in the work

Given:
- the outcomes of A free task hold for #91
- the repository is `acme/shop`, and it is not the repository of the
  implementation
- a rule of the implementation names a script; the default branch of the
  repository of the implementation holds that rule as the run read it, and
  has no script of that name
- the work on #91 comes to the step of that rule, and the run reads it
- the repository of the implementation is public, and no task of its
  tracker reports that rule
When: the run meets that rule in the work on #91
Then:
- the person is asked whether to create a task in the tracker of the
  repository of the implementation, which reports that rule
- the question gives the title of that task
- the question gives the text of that task
- the question says that the repository of the implementation is public
Never:
- the text of that task, as the question gives it, names `acme/shop`
- a task is created in the tracker of the repository of the
  implementation
- a task is created in the tracker of the repository

## The answer yes to a task for a defect of the implementation

Given:
- the outcomes of A free task hold for #91
- the repository is not the repository of the implementation
- an earlier run asked whether to create a task in the tracker of the
  repository of the implementation, which reports that a rule of the
  implementation names a script that its default branch does not have, and
  gave the title and the text of that task
When: the person answers yes
Then:
- one new task is created in the tracker of the repository of the
  implementation
- the new task has the title and the text that the question gave
- the new task has no label and no assignee
- the last message names the new task with its id and its title
Never:
- a task is created in the tracker of the repository

## A repository with no tracker

Given:
- the repository has no tracker, and the workspace has no remote
- the person asked the run to change 40 lines of `parseRows` in
  `src/parser/read.ts`, and the run works on branch `fix/parse-rows`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
When: the run meets that defect in `src/report/total.ts`
Then:
- the last message names the defect of `addTax`
Never:
- a commit on `fix/parse-rows` changes `src/report/total.ts`

## A tracker that does not answer

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- from the time when the run meets that defect, the tracker gives an error
  to each request
When: the run meets that defect in `src/report/total.ts`
Then:
- the person is told the error of the tracker
- the last message names the defect of `addTax`
Never:
- the pull request of #91 changes `src/report/total.ts`

## An error of the tracker while the run adds a finding to a task

Given:
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- `addTax` in `src/report/total.ts` adds the tax twice
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it asks that `addTax` take the rate from the order
- the tracker gives an error to each change of #12
When: the run meets that defect in `src/report/total.ts`
Then:
- the text of #12 stays as it was
- the person is told that the defect was not added to #12
- the person is told the error of the tracker
Never:
- a new task is created for the defect

## A public repository, a log that the person gave, and an open task on the code

Given:
- the repository is public
- the outcomes of A free task hold for #91
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
- the run read `src/report/total.ts`, the only caller of `parseRows`, and
  the work on #91 does not change it
- the person gave a log of a failed import, which names the customer
  `Acme Ltd` and the path `/srv/acme/orders.csv`
- `addTax` in `src/report/total.ts` adds the tax twice, and a line of that
  log shows it
- the repository has the labels `bug` and `enhancement`
- task #12 is open, with no assignee, no linked branch, no pull request and
  no added finding; it has the label `enhancement`, and it asks that
  `addTax` take the rate from the order
When: the run meets that defect in `src/report/total.ts`
Then:
- the text of #12 holds the defect as an added finding
- that added finding names `src/report/total.ts` and the line of the defect
Never:
- the title or the text of #12 holds `Acme Ltd`
- the title or the text of #12 holds `/srv/acme/orders.csv`
- a comment on #12 holds `Acme Ltd`
- a comment on #12 holds `/srv/acme/orders.csv`
- the text of the pull request of #91 holds `Acme Ltd`
- the text of the pull request of #91 holds `/srv/acme/orders.csv`
