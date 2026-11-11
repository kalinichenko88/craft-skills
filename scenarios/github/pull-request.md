# Merge the work of a task

The run ends the work on a task that it took into work. It opens the pull
request of the task, and asks the person whether to merge it. The answer of
the person starts the rest: the run merges the pull request, or leaves it
open. After a merge, the run corrects the open tasks that the merge makes
false, and removes the workspace of the task when the person asked for it.

Not covered yet:

- a push that fails, and a branch that has an open pull request already;
- the opening of a pull request that closes a task that its text does not
  close on purpose, by a closing word or by a link;
- a task that the pull request closes and that another person is assigned
  to;
- the language of the title and the text of the pull request, and the text
  of the commit that the merge adds;
- the answer do not merge, and a merge that fails for another reason than a
  rule of the repository;
- a pull request check that is cancelled, one that does not end, and one
  that starts only after the run reads the pull request checks;
- the merge of a branch that no workspace of its task has;
- a duplicate that closes only after a reproduction of the failure, after
  the merge;
- the end of the work on a task whose text holds an added finding that the
  work does not fix, when the person said nothing of it;
- in the corrections after a merge: a title that the merge makes false, a
  number that it changes, a place in the code that it removes, a task that
  holds two added findings, a task whose premise it removes, a question that
  it answers, a proposal that it rules out, and a default branch that moved
  after the last push of the branch;
- an error of the tracker after the merge;
- a run that started in the workspace of the task, and cannot remove it;
- a finding in the rules or the scripts that the run follows, at the end of
  the run.

## The pull request of a task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the pull request of #91 is assigned to the person
- the pull request of #91 closes #91
- the title of the pull request of #91 is `<type>: <sentence>` or
  `<type>(<scope>): <sentence>`, where `<type>` is one of feat, fix,
  refactor, docs, test, ci, chore
- the person is asked whether to merge the pull request of #91
- the question has three answers: merge and remove the workspace of #91,
  merge only, and do not merge
- the question comes after the pull request of #91 opens
- the run waits
Never:
- the pull request of #91 is merged
- #91 closes
- the pull request of #91 closes a task other than #91

## A pull request that closes a second task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- task #12 is open, assigned to the person, with no linked branch and no
  pull request; it reports that `parseRows` in `src/parser/read.ts` reads a
  tab as a field separator
- the run took #12 along when it took #91 into work
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`, and fixes the defect of #12 too
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 closes #91
- the pull request of #91 closes #12
- the text of the pull request of #91 names #12 as a task that it closes
  beside #91
Never:
- #12 closes before the pull request of #91 is merged

## A pull request that does a part of its task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person;
  its text holds its own problem, that `parseRows` in `src/parser/read.ts`
  drops the last field of a line that ends with a comma, and one added
  finding, that `parseRows` drops a line that holds only spaces
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the person told the run that the added finding of #91 is left for
  another pull request
- the work on #91 fixes its own problem on `fix/91-parse-rows`, and does not
  fix its added finding
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the text of the pull request of #91 says that it does a part of #91
- the pull request of #91 does not close #91
- the person is asked whether to merge the pull request of #91
Never:
- #91 closes

## A pull request with no workspace of its task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91; the workspace is on it, and
  no workspace of #91 exists
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the person is asked whether to merge the pull request of #91
- the run waits
Never:
- the question offers to remove a workspace

## The answer merge only

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- the merge adds one commit to the default branch
- that commit holds every change of #96
- the subject of that commit starts with the title of #96
- #91 is closed
- #91 does not have the label `in progress`
- the repository has no branch `fix/91-parse-rows`
Never:
- the workspace of #91 is removed
- the workspace loses `fix/91-parse-rows`
- a task other than #91 closes

## The answer merge and remove the workspace

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the workspace of #91 has the folder `node_modules/`, which an ignore rule
  of the repository matches, and which the package manager of the
  repository makes again
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only hold
- the workspace of #91 is removed
- the workspace has no branch `fix/91-parse-rows`
- the last message tells that nothing of the work on #91 is left to clean
  up
Never:
- the workspace of #91 is removed before #96 is merged

## The answer merge only while a pull request check runs

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 runs, and passes three minutes later
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #91 is closed
Never:
- #96 is merged while `test` runs

## The answer merge after a pull request check failed

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 failed
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- #96 is open
- #91 is open
- the person is told that `test` of #96 failed
- the workspace of #91 is on `fix/91-parse-rows`
- the run waits
Never:
- #96 is merged
- the workspace of #91 is removed

## A merge that a rule of the repository refuses

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- a rule of the repository refuses the merge of a pull request that no
  other person approved, and no other person approved #96
- the account of the person may merge past that rule
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is open
- the person is told that a rule of the repository refused the merge of #96
- the run waits
Never:
- #96 is merged

## A merge that fixes an added finding of another task

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- task #15 is open, with no assignee, no linked branch and no pull request
  that closes it; its text holds its own problem, that `addTax` in
  `src/report/total.ts` takes a fixed rate in place of the rate of the
  order, and one added finding, that `addTax` adds the tax twice
- #96 fixes the defect that `addTax` adds the tax twice, and does not change
  the rate that `addTax` takes
- the text of #96 says that #96 does a part of #15, and #96 does not close
  #15
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #15 is open
- the text of #15 says, under its added finding, that #96 fixed it
- the problem of #15 stays in its text as it was
Never:
- the text of #15 says that #96 fixed its own problem

## A task done in part that a link closes

Given:
- task #91 is open, assigned to the person; its text holds its own problem,
  that `parseRows` in `src/parser/read.ts` drops the last field of a line
  that ends with a comma, and one added finding, that `parseRows` drops a
  line that holds only spaces
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open and merges `fix/91-parse-rows`
  into the default branch; it fixes the problem of #91 and not its added
  finding, and its text says that #96 does a part of #91
- when #96 opened, an earlier run removed it from the linked pull requests
  of #91; after that, another person made #96 a linked pull request of #91
  again, so #96 closes #91
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #91 is open
- a comment on #91 names #96
- the text of #91 says, under its own problem, that #96 fixed it
Never:
- the text of #91 says that #96 fixed its added finding

## A merge that moves the code that a free task names

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 moves `splitLine` from `src/parser/split.ts` to
  `src/parser/fields.ts`, and changes nothing in `splitLine`
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks that `splitLine` keep the commas inside quotes, and names
  `splitLine` at `src/parser/split.ts:12`
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 names `src/parser/fields.ts` as the file of `splitLine`
- the text of #30 says that #96 moved `splitLine`
- the text of #30 still asks that `splitLine` keep the commas inside quotes
- a comment on #30 names #96
Never:
- a task is created

## A merge that moves the code that a busy task names

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 moves `splitLine` from `src/parser/split.ts` to
  `src/parser/fields.ts`, and changes nothing in `splitLine`
- task #30 is open, assigned to another person; its text asks that
  `splitLine` keep the commas inside quotes, and names `splitLine` at
  `src/parser/split.ts:12`
- branch `feat/30-quoted-commas` is linked to #30
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- a comment on #30 names #96
- that comment names `src/parser/fields.ts` as the file of `splitLine`
- the last message names #30
Never:
- the text of #30 changes
- the title of #30 changes
- the assignees of #30 change

## A workspace of the task with a file that git does not track

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the workspace of #91 has the file `notes.txt`, which git does not track
  and no ignore rule matches
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only hold
- the workspace of #91 has `notes.txt`
- the workspace has `fix/91-parse-rows`
- the person is told that the workspace of #91 stays because of `notes.txt`
Never:
- the workspace of #91 is removed

## A workspace of the task with an ignored file that no build makes

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the workspace of #91 has the file `.env`, which an ignore rule of the
  repository matches, and which no build and no package manager of the
  repository makes
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only hold
- the workspace of #91 has `.env`
- the workspace has `fix/91-parse-rows`
- the person is told that the workspace of #91 stays because of `.env`
Never:
- the workspace of #91 is removed

## A branch of the task with a commit that the pull request does not have

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the workspace's `fix/91-parse-rows` has one commit that the repository's
  `fix/91-parse-rows` and #96 do not have
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only hold
- the workspace of #91 is removed
- the workspace has `fix/91-parse-rows`, with the commit that #96 does not
  have
- the person is told the commit of `fix/91-parse-rows` that #96 does not
  have
Never:
- `fix/91-parse-rows` is deleted from the workspace
- the last message tells that nothing of the work on #91 is left to clean
  up
