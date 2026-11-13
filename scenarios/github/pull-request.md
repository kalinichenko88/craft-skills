# Merge the work of a task

The run ends the work on a task that it took into work. It opens the pull
request of the task, and asks the person whether to merge it. The answer of
the person starts the rest: the run merges the pull request, or leaves it
open. After a merge, the run corrects the open tasks that the merge makes
false, closes the duplicates that it left for a reproduction, asks whether
to report a defect of the implementation that the work showed, and removes
the workspace of the task when the person asked for it.

Not covered yet: none.

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

## A push that the repository refuses

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`
- the check passes on `fix/91-parse-rows`
- the repository refuses each push of `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the person is told that the push of `fix/91-parse-rows` failed, with its
  error
- `fix/91-parse-rows` in the workspace of #91 holds the work on #91
Never:
- a pull request of #91 opens
- the person is asked whether to merge a pull request of #91

## A branch that has an open pull request already

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the workspace of #91 is on `fix/91-parse-rows`
- after #96 opened, the work on #91 added one commit to
  `fix/91-parse-rows` in the workspace of #91, which the repository's
  `fix/91-parse-rows` does not have
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the repository's `fix/91-parse-rows` has the same last commit as the
  one in the workspace of #91
- #96 is open
- the text of #96 tells what the new commit changes
- the person is asked whether to merge #96
- the question comes after the repository's `fix/91-parse-rows` has the
  new commit
Never:
- a second pull request opens for `fix/91-parse-rows`
- #96 is merged

## A pull request that fixes the own problem of a second task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- task #40 is open, assigned to the person, with no linked branch and no
  pull request; its text holds its own problem, that `parseRows` in
  `src/parser/read.ts` reads a tab as a field separator, and one added
  finding, that `addTax` in `src/report/total.ts` adds the tax twice
- the run took #40 along for its own problem when it took #91 into work
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`, fixes the own problem of #40, and does not change
  `src/report/total.ts`
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the text of the pull request of #91 says that it does a part of #40
Never:
- the pull request of #91 closes #40

## A task that another person linked to the branch of the task

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`
- task #40 is open; it reports that `addTax` in `src/report/total.ts` adds
  the tax twice, and another person made `fix/91-parse-rows` a linked
  branch of #40 too
- the work on #91 does not change `src/report/total.ts`
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the pull request of #91 closes #91
- the pull request of #91 does not close #40
Never:
- #40 closes

## A pull request that closes a task of another person

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- task #12 is open, assigned to another person, with no linked branch and
  no pull request; it reports that `parseRows` in `src/parser/read.ts` reads
  a tab as a field separator
- the person told the run that the pull request of #91 closes #12 too
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`, and fixes the defect of #12 too
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 closes #12
- the person is told that #12 is assigned to another person
Never:
- the assignees of #12 change

## A repository whose pull requests are in another language

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `src/parser/read.ts` on
  `fix/91-parse-rows`
- the check passes on `fix/91-parse-rows`
- the person's language is English
- the titles and the texts of the last ten merged pull requests of the
  repository are in German, after the type at the start of each title
- the titles and the texts of the tasks of the repository, #91 too, are in
  German
When: the run ends the work on #91
Then:
- the title of the pull request of #91 starts with a type
- the title of the pull request of #91 is in German after its type
- the text of the pull request of #91 is in German
Never:
- the person is asked in which language to write the pull request of #91

## The end of the work with an added finding that needs an answer

Given:
- the run took task #91 into work, and #91 is open, assigned to the person;
  its text holds its own problem, that `parseRows` in `src/parser/read.ts`
  drops the last field of a line that ends with a comma, and one added
  finding, that `parseRows` drops a line that holds only spaces
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the person said nothing of the added finding of #91, and no text of the
  repository says whether `parseRows` keeps a line that holds only spaces
- the work on #91 fixes its own problem on `fix/91-parse-rows`, and does not
  fix its added finding
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the person is asked whether `parseRows` keeps a line that holds only
  spaces
- the run waits
- the pull request of #91 does not close #91
Never:
- #91 closes
- the person is asked whether to merge the pull request of #91

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
- the subject of that commit is the title of #96 in English, then `(#96)`
- #91 is closed
- #91 does not have the label `in progress`
- the repository has no branch `fix/91-parse-rows`
Never:
- the workspace of #91 is removed
- the workspace loses `fix/91-parse-rows`
- a task other than #91 closes

## The answer merge only for a pull request in another language

Given:
- task #91 is open, assigned to the person, with the label `in progress`
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- the titles and the texts of the last ten merged pull requests of the
  repository are in German, after the type at the start of each title
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91; its title is in German after the type
  at its start, and its text is in German
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- the merge adds one commit to the default branch
- the subject of that commit starts with the type at the start of the
  title of #96
- the subject of that commit is in English after its type
- the subject of that commit ends with `(#96)`
- the text of that commit under its subject is in English
Never:
- the person is asked in which language to write the commit

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

## A merge all the same after a pull request check failed

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 failed
- a rule of the repository refuses the merge of a pull request whose check
  `test` did not pass
- the account of the person may merge past that rule
- an earlier run told the person that `test` of #96 failed, and waited
When: the person writes "merge #96 all the same"
Then:
- #96 is open
- the person is told that a rule of the repository refused the merge of #96
- the run waits
Never:
- #96 is merged

## A merge all the same after a pull request check failed, with no rule

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 failed
- an earlier run told the person that `test` of #96 failed, and waited
When: the person writes "merge #96 all the same"
Then:
- #96 is merged
- #91 is closed
Never:
- the person is asked whether to merge #96

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

## The answer do not merge

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers do not merge
Then:
- #96 is open
- #91 is open
- the workspace of #91 is on `fix/91-parse-rows`
- the repository has `fix/91-parse-rows`
Never:
- #96 is merged
- the workspace of #91 is removed

## A merge that a conflict with the default branch stops

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 passed
- after the last push of `fix/91-parse-rows`, a commit on the default
  branch changed the same lines of `src/parser/read.ts` as #96, so #96 has a
  conflict with the default branch
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- #96 is open
- #91 is open
- the person is told that the merge of #96 failed, with its error
- the workspace of #91 is on `fix/91-parse-rows`
- the run waits
Never:
- #96 is merged
- the workspace of #91 is removed

## The answer merge after a pull request check was cancelled

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `test` of #96 was cancelled
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- #96 is open
- #91 is open
- the person is told that `test` of #96 was cancelled
- the workspace of #91 is on `fix/91-parse-rows`
- the run waits
Never:
- #96 is merged
- the workspace of #91 is removed

## The answer merge while a pull request check does not end

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `deploy` of #96 needs the approval of another
  person to go on, and does not end
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is open
- the person is told that `deploy` of #96 has not ended
- the run waits
Never:
- #96 is merged

## A merge all the same while a pull request check does not end

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the pull request check `deploy` of #96 needs the approval of another
  person to go on, and does not end
- a rule of the repository refuses the merge of a pull request whose check
  `deploy` did not pass
- the account of the person may merge past that rule
- an earlier run told the person that `deploy` of #96 has not ended, and
  waited
When: the person writes "merge #96 all the same"
Then:
- #96 is open
- the person is told that a rule of the repository refused the merge of #96
- the run waits
Never:
- #96 is merged

## The answer merge before a pull request check starts

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- when the person answers, #96 has no pull request check; its pull request
  check `test` starts 30 seconds later, and passes three minutes after it
  starts
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #91 is closed
Never:
- #96 is merged before `test` passes

## The answer merge for a branch with no workspace of its task

Given:
- task #91 is open, assigned to the person
- the workspace is on branch `fix/91-parse-rows`, and no workspace of #91
  exists
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run asked whether to merge #96, with two answers: merge, and
  do not merge
When: the person answers merge
Then:
- #96 is merged
- #91 is closed
- the repository has no branch `fix/91-parse-rows`
- the workspace is on the default branch
- the workspace has no branch `fix/91-parse-rows`
Never:
- the workspace is removed

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

## A merge that makes the title of a free task false

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 moves `splitLine` from `src/parser/split.ts` to
  `src/parser/fields.ts`, and changes nothing in `splitLine`
- task #30 is open, with no assignee, no linked branch and no pull request;
  its title is "`splitLine` in `src/parser/split.ts` drops the commas inside
  quotes", and its text asks that `splitLine` keep them
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the title of #30 names `src/parser/fields.ts` as the file of `splitLine`
- the title of #30 says that `splitLine` drops the commas inside quotes
- a comment on #30 names #96
- the title of #30 does not name `src/parser/split.ts`
Never:
- #30 closes

## A merge that changes a number that a free task gives

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the check of the repository fails on a file of more than 400 lines;
  `src/parser/read.ts` has 380 lines on the default branch, and 395 lines
  with #96
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks that `src/parser/read.ts` be split before it has more than
  400 lines, and says that it has 380 lines
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 says that `src/parser/read.ts` has 395 lines
- the text of #30 still asks that `src/parser/read.ts` be split
- a comment on #30 names #96
- the text of #30 does not say that `src/parser/read.ts` has 380 lines
Never:
- #30 closes

## A merge that removes a place in the code that a free task names

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 deletes `src/parser/legacy.ts`, with its function `readLegacy`
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text reports that a tab at the end of a field stays in the field, in
  `splitLine` at `src/parser/split.ts:12` and in `readLegacy` at
  `src/parser/legacy.ts:30`
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 still reports the tab in `splitLine` at
  `src/parser/split.ts:12`
- the text of #30 says that #96 deleted `src/parser/legacy.ts`
- a comment on #30 names #96
- the text of #30 does not name `src/parser/legacy.ts:30` as a place of
  the defect
Never:
- #30 closes

## A merge that moves the code that a task with two added findings names

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 moves `splitLine` from `src/parser/split.ts` to
  `src/parser/fields.ts`, and changes nothing in `splitLine`
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text names `splitLine` at `src/parser/split.ts:12`, and holds its own
  problem, that `splitLine` drops the commas inside quotes, and two added
  findings, that `splitLine` drops an empty last field, and that it keeps a
  carriage return at the end of a line
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 names `src/parser/fields.ts` as the file of `splitLine`
- the text of #30 holds its own problem
- the text of #30 holds its two added findings
- a comment on #30 names #96
Never:
- a task is created

## A merge that removes the premise of a free task

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 deletes `src/parser/legacy.ts`
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks that `src/parser/legacy.ts` and `src/parser/read.ts` use
  one `splitLine`, as each of them holds its own `splitLine`
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is closed
- a comment on #30 names #96
Never:
- #30 closes before #96 is merged

## A merge that answers the question of a free task

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 makes `parseRows` in `src/parser/read.ts` drop each empty line of a
  file, and its text says that it decided so
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks whether `parseRows` in `src/parser/read.ts` keeps the empty
  lines of a file or drops them, and asks for a test of `parseRows` on a
  file with empty lines
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 says that #96 answered its question: `parseRows` drops
  each empty line
- the text of #30 still asks for a test of `parseRows` on a file with
  empty lines
- a comment on #30 names #96
- the text of #30 does not ask whether `parseRows` keeps the empty lines,
  as a question that is open
Never:
- #30 closes

## A merge that rules out the proposal of a free task

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 makes `parseRows` in `src/parser/read.ts` return the bad lines of a
  file in a list, without their line numbers; its text says that it ruled
  out an error from `parseRows` for a bad line
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks that a user of the product who imports a file sees the line
  number of each bad line, and proposes that `parseRows` in
  `src/parser/read.ts` give an error that holds that number
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 still asks that a user of the product who imports a file
  sees the line number of each bad line
- the text of #30 says that #96 ruled out an error from `parseRows` for a
  bad line
- a comment on #30 names #96
- the text of #30 does not propose that `parseRows` give an error for a
  bad line
Never:
- #30 closes

## A merge after the default branch moved under the branch of the task

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- #96 moves `splitLine` from `src/parser/split.ts` to
  `src/parser/fields.ts`, and changes nothing in `splitLine`; on
  `fix/91-parse-rows`, `splitLine` starts at line 12 of
  `src/parser/fields.ts`
- after the last push of `fix/91-parse-rows`, a commit on the default
  branch added 10 lines at the start of `src/parser/fields.ts`, and #96 has
  no conflict with the default branch
- task #30 is open, with no assignee, no linked branch and no pull request;
  its text asks that `splitLine` keep the commas inside quotes, and names
  `splitLine` at `src/parser/split.ts:12`
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #30 is open
- the text of #30 names `splitLine` at `src/parser/fields.ts:22`
- a comment on #30 names #96
Never:
- the text of #30 names `src/parser/fields.ts:12`

## A duplicate left for a reproduction that the merge fixes

Given:
- task #91 is open, assigned to the person; it reports that `parseRows` in
  `src/parser/read.ts` drops the last field of a line that ends with a
  comma
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, closes #91, and fixes that defect
- task #95 is open, with no assignee, no linked branch and no pull request;
  it tells only that the total of an order report is too low for a file
  whose lines end with a comma, and names no code
- the run that took #91 into work left #95 open until a reproduction of its
  failure
- before the merge, the failure of #95 shows on the default branch, and
  does not show with the code of #96
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #95 is closed as a duplicate of #91
Never:
- #95 closes before #96 is merged

## A duplicate left for a reproduction that the merge does not fix

Given:
- task #91 is open, assigned to the person; it reports that `parseRows` in
  `src/parser/read.ts` drops the last field of a line that ends with a
  comma
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, closes #91, and fixes that defect
- task #95 is open, with no assignee, no linked branch and no pull request;
  it tells only that the total of an order report is too low for a file
  whose lines end with a comma, and names no code
- the run that took #91 into work left #95 open until a reproduction of its
  failure
- before the merge, the failure of #95 shows on the default branch, and
  with the code of #96 too
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #95 is open
- a comment on #95 names what else than the defect of #91 can cause its
  failure
Never:
- #95 closes

## An error of the tracker after the merge

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- after #96 is merged, the tracker answers each read with an error
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- #91 is closed
- the person is told that the tracker could not be read after the merge of
  #96, with its error
- the person is told that the corrections of the open tasks after the
  merge of #96 did not run
Never:
- the person is told that no open task needs a correction after the merge
  of #96

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

## A run that cannot remove the workspace of its task

Given:
- task #91 is open, assigned to the person
- the run started in the workspace of #91, which is on branch
  `fix/91-parse-rows`, and cannot remove that workspace while it runs
- `fix/91-parse-rows` has two commits that the default branch does not
  have, and the same last commit in the repository and in the workspace of
  #91
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only hold
- the workspace of #91 is on `fix/91-parse-rows`
- the person is told what removes the workspace of #91 and
  `fix/91-parse-rows` after the run ends
Never:
- the last message tells that nothing of the work on #91 is left to clean
  up

## A step of the implementation that the person pointed out

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- during the work on #91, the person told an earlier run that it skipped a
  step of the implementation, and that run then did that step
- the repository is not the repository of the implementation
- the default branch of the repository of the implementation holds that
  step as that run read it, and no task of its tracker reports that a run
  skipped it
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- the person is asked whether to create a task in the tracker of the
  repository of the implementation, which reports that a run skipped that
  step
- the question gives the title of that task
- the question gives the text of that task
- the question comes after #96 is merged
- the run waits
Never:
- a task is created in the tracker of the repository of the
  implementation
- a task is created in the tracker of the repository

## A script of the implementation that failed during the work

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- during the work on #91, a script of the implementation failed on an
  input that is valid by the text of the implementation
- the repository is not the repository of the implementation
- the default branch of the repository of the implementation holds that
  script as it ran, and no task of its tracker reports that failure
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- the person is asked whether to create a task in the tracker of the
  repository of the implementation, which reports that failure
- the question gives the title of that task
- the question gives the text of that task
- the question comes after #96 is merged
- the run waits
Never:
- a task is created in the tracker of the repository of the
  implementation
- a task is created in the tracker of the repository

## A pointed-out step, in the repository of the implementation

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- during the work on #91, the person told an earlier run that it skipped a
  step of the implementation, and that run then did that step
- the repository is the repository of the implementation, and no task of
  its tracker reports that a run skipped that step
- an earlier run asked whether to merge #96, with three answers: merge and
  remove the workspace of #91, merge only, and do not merge
When: the person answers merge only
Then:
- #96 is merged
- a task of the tracker reports that a run skipped that step
- the report of that step reaches the tracker after #96 is merged
Never:
- the person is asked whether to create a task for that step
