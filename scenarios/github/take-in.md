# Take a task into work

The whole text that the person writes names one task: "#91", "take #91", or
the link of the task. It can also say where the work runs: on a branch only,
or on the branch that the workspace is on. The run checks whether the task is
free, tells the person the gist of the task, closes its duplicates, and starts
the work on a branch linked to the task, or on the branch that the workspace
is on. A next text of the person after a run that asked or waited goes on
with the task of that run.

Not covered yet:

- a task on the same code that is busy, or whose text waits on a decision;
- a duplicate that tells only the failure that was seen, when the
  reproduction shows another cause;
- the answers to the question what to do with a branch in the workspace
  that has the name of the new branch;
- other pairs of states that each end the run in another way, as a closed
  task with a busy duplicate;
- a text after a wait that names another task.

## A free task

Given:
- task #91 is open, with no assignee, no linked branch and no pull request
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the gist comes before any change to the tracker or the workspace
- #91 is assigned to the person
- #91 has the label `in progress`
- a branch `<type>/91-<two to four words>` exists, where `<type>` is one of
  feat, fix, refactor, docs, test, ci, chore
- that branch is made from the default branch
- that branch is linked to #91
Never:
- #91 gets a second linked branch

## A closed task

Given:
- task #91 is closed
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is closed
- the run waits
Never:
- the state of #91 changes
- the assignees of #91 change
- a branch for #91 is created

## A task that another person is assigned to

Given:
- task #91 is open, assigned to another person
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is assigned to another person
- the run waits
Never:
- the assignees of #91 change
- a branch for #91 is created

## A task with another person's pull request

Given:
- task #91 is open, with no assignee
- pull request #96 of another person is open and closes #91
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #96 of another person closes #91
- the run waits
Never:
- the assignees of #91 change
- a branch for #91 is created

## A task with the person's pull request

Given:
- task #91 is open, with no assignee
- pull request #96 of the person is open and closes #91
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that the work on #91 has pull request #96
- the run stops
Never:
- the assignees of #91 change
- a branch for #91 is created

## A task assigned to the person, with no branch

Given:
- task #91 is open, assigned to the person, without the label
  `in progress`, with no linked branch and no pull request
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- #91 stays assigned to the person
- #91 has the label `in progress`
- a branch for #91 exists, as in A free task
- that branch is made from the default branch
- that branch is linked to #91
Never:
- the person is asked whether the work on #91 runs somewhere else
- #91 gets a second linked branch

## A task in progress for the person, with no branch

Given:
- task #91 is open, assigned to the person, with the label `in progress`,
  no linked branch and no pull request
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is in progress already
- the person is asked whether the work on #91 runs somewhere else or
  continues here
- the run waits
Never:
- a branch for #91 is created
- the assignees of #91 change

## The work on the person's task continues here

Given:
- task #91 is open, assigned to the person, with the label `in progress`,
  no linked branch and no pull request
- an earlier run asked whether the work on #91 runs somewhere else or
  continues here
When: the person answers that it continues here
Then:
- #91 stays assigned to the person
- a branch for #91 exists, as in A free task
- that branch is made from the default branch
- that branch is linked to #91
Never:
- #91 gets a second linked branch

## The work on the person's task runs somewhere else

Given:
- task #91 is open, assigned to the person, with the label `in progress`,
  no linked branch and no pull request
- an earlier run asked whether the work on #91 runs somewhere else or
  continues here
When: the person answers that it runs somewhere else
Then:
- the run stops
Never:
- a branch for #91 is created
- the assignees of #91 change

## A linked branch with no assignee

Given:
- task #91 is open, with no assignee
- branch `fix/91-typo` is linked to #91
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that `fix/91-typo` is linked to #91
- the person is asked whose branch `fix/91-typo` is
- the run waits
Never:
- the assignees of #91 change
- a branch for #91 is created

## The person's work is in the workspace

Given:
- task #91 is open, assigned to the person
- branch `fix/91-typo` is linked to #91, and no pull request closes #91
- the workspace has `fix/91-typo`, with the same last commit as the
  repository
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told in one line that the work on #91 continues on
  `fix/91-typo`
- the work goes on, on `fix/91-typo`
Never:
- the person is asked whether the work runs somewhere else
- #91 gets a second linked branch
- the assignees of #91 change

## The person's branch moved on somewhere else

Given:
- task #91 is open, assigned to the person
- branch `fix/91-typo` is linked to #91, and no pull request closes #91
- the repository's `fix/91-typo` has a commit that the workspace's
  `fix/91-typo` does not have
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is assigned to the person
- the person is told that `fix/91-typo` is linked to #91
- the person is asked whether the work on #91 runs somewhere else or
  continues here
- the run waits
Never:
- a branch for #91 is created
- the workspace's `fix/91-typo` changes

## A task of another repository

Given:
- task #91 is open in another repository, with no assignee
When: the person writes the link of #91
Then:
- the first message about #91 tells its gist
- the person is told that #91 is in another repository
- the run stops
Never:
- the assignees of #91 change
- a branch for #91 is created

## The tracker does not answer

Given:
- task #91 is open, with no assignee
- the tracker answers each read with an error
When: the person writes "#91"
Then:
- the person is told that the tracker could not be read, with its error
- the run stops
Never:
- the person is told a gist of #91 that the run did not read
- the assignees of #91 change
- a branch for #91 is created

## A free duplicate

Given:
- task #91 is open, with no assignee
- task #95 is open, with no assignee, and reports the same thing as #91 in
  other words; it names the same file as #91, and its text has a stack trace
  that #91 does not have
When: the person writes "#91"
Then:
- a comment on #91 holds the stack trace of #95
- #95 is closed as a duplicate of #91
- the comment on #91 comes before #95 closes
- #95 closes before the work starts
- the last message names #95 as closed
- the outcomes of A free task hold for #91
Never:
- #91 closes

## A busy duplicate

Given:
- task #91 is open, with no assignee
- task #95 is open, assigned to another person, and reports the same thing
  as #91 in other words; it names the same file as #91
When: the person writes "#91"
Then:
- #95 stays open
- the person is told that #95 stays open because it is busy
- the outcomes of A free task hold for #91
Never:
- #95 closes
- the assignees of #95 change

## A settled bug on the code of the task

Given:
- the repository has the label `bug`
- task #91 is open, with no assignee, no linked branch and no pull request;
  it reports that `parseRows` in `src/parser/read.ts` turns an empty line
  into a row with one empty field
- task #12 is open, with the label `bug`, no assignee, no linked branch and
  no pull request; it reports that `parseRows` reads a tab as a field
  separator, and says that `parseRows` must split a line only at commas
- the fix of #12 changes one line of `parseRows`, and the fix of #91 changes
  more lines than that
When: the person writes "#91"
Then:
- the outcomes of A free task hold for #91
- #12 is assigned to the person
- #12 has the label `in progress`
- #12 is assigned to the person before the work starts
- the work on #91 fixes the defect of #12
Never:
- #12 closes

## A duplicate that tells only what was seen

Given:
- task #91 is open, with no assignee, no linked branch and no pull request;
  it reports that `splitLine` in `src/parser/split.ts` drops the last field
  of a line that ends with a comma
- task #95 is open, with no assignee, no linked branch and no pull request;
  it says only that an imported table has one column less than its file,
  and names no cause, no file of the code and no function
- the failure of #95 comes from that defect of `splitLine`
When: the person writes "#91"
Then:
- #95 is closed as a duplicate of #91
- a reproduction of the failure of #95 runs in the workspace of #91
- #95 closes after that reproduction
- the last message names #95 as closed
- the outcomes of A free task hold for #91
Never:
- #91 closes

## A task that names a line that moved

Given:
- task #91 is open, with no assignee, no linked branch and no pull request;
  its text names `src/parser/read.ts:42` as the line of `parseRows`
- on the default branch, `parseRows` starts at line 57 of
  `src/parser/read.ts`, and line 42 is in another function
When: the person writes "#91"
Then:
- the text of #91 names `src/parser/read.ts:57` as the line of `parseRows`
- the rest of the text of #91 stays as it was
- the text of #91 changes before the work starts
- the outcomes of A free task hold for #91
Never:
- the text of #91 names `src/parser/read.ts:42`

## A task that holds an added finding

Given:
- task #91 is open, with no assignee, no linked branch and no pull request;
  it reports that `parseRows` in `src/parser/read.ts` turns an empty line
  into a row with one empty field
- the text of #91 holds one added finding: `splitLine` in
  `src/parser/split.ts` drops the last field of a line that ends with a
  comma
When: the person writes "#91"
Then:
- the outcomes of A free task hold for #91
- the first message about #91 names its added finding
- the work on #91 fixes the defect of its added finding
Never:
- a task is created for the added finding of #91

## A branch only

Given:
- task #91 is open, with no assignee, no linked branch and no pull request
When: the person writes "#91, a branch only"
Then:
- the outcomes of A free task hold for #91
- the workspace is on the branch that is linked to #91
Never:
- a workspace of #91 is created

## Stay on the branch of the workspace

Given:
- task #91 is open, with no assignee, no linked branch and no pull request
- the workspace is on branch `fix/rows`, which no task links
When: the person writes "#91, stay on this branch"
Then:
- the first message about #91 tells its gist
- #91 is assigned to the person
- #91 has the label `in progress`
- the workspace stays on `fix/rows`
Never:
- a branch for #91 is created
- #91 gets a linked branch
- a workspace of #91 is created

## The person's pull request is in the workspace

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- pull request #96 of the person is open and closes #91; its branch is
  `fix/91-typo`
- the workspace has `fix/91-typo`, with the same last commit as the
  repository
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told in one line that the work on #91 continues on
  `fix/91-typo`
- the work goes on, on `fix/91-typo`
Never:
- the person is asked whether the work runs somewhere else
- a pull request other than #96 closes #91
- a branch for #91 is created
- the assignees of #91 change

## A linked branch of another repository only

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- branch `fix/91-typo` of another repository is linked to #91, and no
  branch of the repository is
- an earlier run asked whether the work on #91 runs somewhere else or
  continues here
When: the person answers that it continues here
Then:
- the person is told the link of `fix/91-typo` in the other repository
- the run waits
Never:
- a branch for #91 is created
- #91 gets a second linked branch
- the assignees of #91 change

## A branch in the workspace with the name of the new branch

Given:
- task #91 is open, with no assignee, no linked branch and no pull request
- the run told the gist of #91, and gives the branch of #91 the name
  `fix/91-typo`
- the workspace has branch `fix/91-typo`, with one commit that no branch of
  the repository has
When: the run meets `fix/91-typo` in the workspace
Then:
- the person is told that the workspace has `fix/91-typo`
- the person is told the commit of `fix/91-typo` that the repository does
  not have
- the person is asked what to do with `fix/91-typo`
- the question has three answers: keep it and give the new branch of #91
  another name, delete it, and take it as the branch of #91
- the run waits
Never:
- `fix/91-typo` changes
- the assignees of #91 change
- #91 gets the label `in progress`
- #91 gets a linked branch

## The text of the task cannot be read

Given:
- task #91 is open, with no assignee, no linked branch and no pull request
- the tracker answers the read of the title and the text of #91 with an
  error, and each other read with no error
When: the person writes "#91"
Then:
- the person is told that the text of #91 could not be read, with its error
- that message comes before any change to the tracker or the workspace
- #91 is assigned to the person
- #91 has the label `in progress`
- a branch for #91 is made from the default branch
- that branch is linked to #91
Never:
- the person is told a gist of #91 that the run did not read

## An earlier run works on the task in another conversation

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- branch `fix/91-typo` is linked to #91, and no pull request closes #91
- the workspace has `fix/91-typo`, with the same last commit as the
  repository
- an earlier run took #91 into the work in another conversation, which is
  open; the first text of that conversation is "#91"
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told which conversation holds the work on #91
- the run stops
Never:
- the person is asked whether the work runs somewhere else
- the workspace's `fix/91-typo` changes
- a workspace of #91 is created

## A closed task with a free duplicate

Given:
- task #91 is closed
- task #95 is open, with no assignee, no linked branch and no pull request,
  and reports the same thing as #91 in other words; it names the same file
  as #91
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is closed
- the run waits
Never:
- #95 closes
- a comment is added to #91
- the state of #91 changes
- a branch for #91 is created

## Another person's task whose linked branch the workspace has

Given:
- task #91 is open, assigned to another person
- branch `fix/91-typo` is linked to #91, and no pull request closes #91
- the workspace has `fix/91-typo`, with the same last commit as the
  repository
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told that #91 is assigned to another person
- the run waits
Never:
- the person is told that the work on #91 continues
- the person is asked whether the work runs somewhere else
- the workspace's `fix/91-typo` changes
- the assignees of #91 change

## The workspace's branch has a commit that the repository does not have

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- branch `fix/91-typo` is linked to #91, and no pull request closes #91
- the workspace's `fix/91-typo` has the last commit of the repository's
  `fix/91-typo`, and one commit after it
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is told in one line that the work on #91 continues on
  `fix/91-typo`
- the work goes on, on `fix/91-typo`
- the commit that the repository did not have stays on `fix/91-typo`
Never:
- the person is asked whether the work runs somewhere else
- a branch for #91 is created
- #91 gets a second linked branch

## The linked branch is another person's

Given:
- task #91 is open, with no assignee
- branch `fix/91-typo` is linked to #91
- an earlier run asked whose branch `fix/91-typo` is
When: the person answers that it is another person's
Then:
- the person is told that the work on #91 is another person's
- the run waits
Never:
- the person is asked whether the work on #91 runs somewhere else
- the assignees of #91 change
- #91 gets the label `in progress`
- a branch for #91 is created

## The linked branch is the person's

Given:
- task #91 is open, with no assignee
- branch `fix/91-typo` is linked to #91
- an earlier run asked whose branch `fix/91-typo` is
When: the person answers that it is the person's
Then:
- the person is asked whether the work on #91 runs somewhere else or
  continues here
- the run waits
Never:
- the assignees of #91 change
- #91 gets the label `in progress`
- a branch for #91 is created

## The work on the linked branch continues here

Given:
- task #91 is open, with no assignee
- branch `fix/91-typo` is linked to #91
- an earlier run asked whose branch `fix/91-typo` is, the person answered
  that it is the person's, and the run then asked whether the work on #91
  runs somewhere else or continues here
When: the person answers that it continues here
Then:
- #91 is assigned to the person
- #91 has the label `in progress`
- the work goes on, on `fix/91-typo`
Never:
- a branch for #91 is created
- #91 gets a second linked branch

## The work on the linked branch runs somewhere else

Given:
- task #91 is open, with no assignee
- branch `fix/91-typo` is linked to #91
- an earlier run asked whose branch `fix/91-typo` is, the person answered
  that it is the person's, and the run then asked whether the work on #91
  runs somewhere else or continues here
When: the person answers that it runs somewhere else
Then:
- the run stops
Never:
- the assignees of #91 change
- #91 gets the label `in progress`
- the workspace gets `fix/91-typo`

## A text after a wait that names no task

Given:
- task #91 is open, assigned to another person, with no linked branch and
  no pull request
- an earlier run told the gist of #91 and that #91 is assigned to another
  person, and waited
When: the person writes "It is mine now, take it"
Then:
- #91 is assigned to the person
- #91 has the label `in progress`
- a branch for #91 exists, as in A free task
- that branch is made from the default branch
- that branch is linked to #91
Never:
- the other person stops being an assignee of #91
- the person is asked whose the work on #91 is

## A text after a stop that names the task again

Given:
- task #91 is open, assigned to the person, with the label `in progress`,
  no linked branch and no pull request
- an earlier run asked whether the work on #91 runs somewhere else or
  continues here, the person answered that it runs somewhere else, and the
  run stopped
When: the person writes "#91"
Then:
- the outcomes of A task in progress for the person, with no branch hold
  for #91
Never:
- a branch for #91 is created
- the assignees of #91 change
