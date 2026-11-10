# Review a change

The run reviews the change on a branch: when it ends the work on a task, or
when the person asks for a review. The review reads the change in rounds,
fixes what they report, and tells the person what it did. When the run took
a task into work, the run then opens the pull request of the task and asks
whether to merge it, in the same run.

Not covered yet:

- the check that a new capability is worth it, the review for code that is
  not necessary, and the walk through a screen that the change alters;
- the review of the architecture, the review of the tests, and the second
  reader of a change at level xhigh;
- a review that reads no file of its part of the branch;
- a report that needs an input that the real data does not hold, and a
  finding outside the task;
- the comments of a review by another person;
- a change to the text of a skill or a prompt, alone or with code;
- a branch that has an open pull request already, and a push that fails;
- the answer to an open question on business logic;
- the person's request for a pull request with no task;
- the review of a spec and of a plan.

## A review with no defect

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- a review of the whole branch reports two nits and no defect: a comment of
  `parseRows` gives a wrong count of fields, and the name of a test does not
  say what it tests
- the security review reports no security hole
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the two nits
- the security review reads the branch after that commit
- the pull request of #91 is open
- the text of the pull request of #91 names round 1, its level and the part
  of the branch that it read
- the text of the pull request of #91 gives the result of the security
  review and of the check
- the pull request of #91 opens after the security review
- the person is asked whether to merge the pull request of #91
- the run waits
Never:
- a review reads the commit that fixes the two nits
- a last pass runs
- the run waits before the pull request of #91 opens

## A defect in the first round

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- a review of the whole branch reports one defect: `parseRows` drops the
  last field of a line that ends with a comma
- each review after it reports no defect
- the security review reports no security hole
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes that defect
- round 2 reads only that commit
- after round 2, one last pass reads the whole branch
- the text of the pull request of #91 names round 1, round 2 and the last
  pass
- the person is asked whether to merge the pull request of #91
Never:
- round 2 reads the whole branch
- round 3 runs

## A defect that the last pass reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- a review of the whole branch reports one defect: `parseRows` drops the
  last field of a line that ends with a comma
- the review of the commit that fixes it reports no defect
- the last pass reports one defect: `countFields` in `src/parser/read.ts`
  still gives the old count for a line that ends with a comma
- each review after the last pass reports no defect
- the security review reports no security hole
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the defect of
  `countFields`
- a round reads only that commit
- the pull request of #91 is open
Never:
- a second last pass runs

## A defect in each of three rounds

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- a review of the whole branch reports one defect: `parseRows` drops the
  last field of a line that ends with a comma
- the review of the commit that fixes it reports one defect in that fix:
  `parseRows` gives one empty field for an empty line
- the review of the commit that fixes that second defect reports one defect
  in that fix: `parseRows` drops an empty line inside quotes
- the security review reports no security hole
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the first defect, and one
  that fixes the second defect
- the text of the pull request of #91 names three rounds
- the text of the pull request of #91 names the defect of round 3 as not
  fixed
- the pull request of #91 is open
- the person is asked whether to merge the pull request of #91
- the question has four answers: merge and remove the workspace of #91,
  merge only, do not merge, and up to three more rounds
- the run waits
Never:
- round 4 runs
- `fix/91-parse-rows` fixes the defect of round 3
- a last pass runs
- the pull request of #91 is merged

## The answer merge only after a stop at round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run stopped the review of #96 after round 3, and round 3
  reported a defect that is not fixed: `parseRows` drops an empty line
  inside quotes
- the text of #96 names that defect as not fixed
- the repository has the labels `bug` and `docs`
- the earlier run asked whether to merge #96, with four answers: merge and
  remove the workspace of #91, merge only, do not merge, and up to three
  more rounds
When: the person answers merge only
Then:
- #96 is merged
- one new task is created for the defect that is not fixed
- the new task is created after #96 is merged
- the text of the new task names `parseRows` and says how the defect shows
- the last message names the new task with its id and its title
Never:
- a commit is added to `fix/91-parse-rows` after the answer

## The answer more rounds after a stop at round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run stopped the review of #96 after round 3, and round 3
  reported a defect that is not fixed: `parseRows` drops an empty line
  inside quotes
- the review of the commit that fixes that defect reports no defect
- the check passes on `fix/91-parse-rows`
- the earlier run asked whether to merge #96, with four answers: merge and
  remove the workspace of #91, merge only, do not merge, and up to three
  more rounds
When: the person answers up to three more rounds
Then:
- #96 has a commit that fixes that defect
- a round reads only that commit
- the text of #96 names that round
- the person is asked again whether to merge #96
- the run waits
Never:
- #96 is merged

## A fix in one file with its test

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-split-default` is linked to #91, and the workspace of #91
  is on it
- the work on #91 changes one line of `splitLine` in `src/parser/split.ts`,
  a wrong default separator, and adds no branch to the code; it changes one
  test of `splitLine` in `test/split.test.ts`
- each review reports no defect
- the security review reports no security hole
- the check passes on `fix/91-split-default`
When: the run ends the work on #91
Then:
- round 1 reads at level medium
- the person is told the reason for that level in one sentence
Never:
- a round reads at level low

## A change to the check of a session token

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-token-expiry` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes how `checkToken` in `src/auth/session.ts` checks
  the token of a session, and the tests of `checkToken`
- each review reports no defect
- the security review reports no security hole
- the check passes on `fix/91-token-expiry`
When: the run ends the work on #91
Then:
- round 1 reads at level xhigh
- the person is told the reason for that level in one sentence
Never:
- a round reads at level low, medium or high

## A change to documents only

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `docs/91-parser-guide` is linked to #91, and the workspace of #91
  is on it
- the work on #91 changes only `docs/parser.md`, on `docs/91-parser-guide`
- a review of the whole branch reports one defect: `docs/parser.md` says
  that `parseRows` keeps empty lines, and `parseRows` drops them
- the check passes on `docs/91-parser-guide`
When: the run ends the work on #91
Then:
- `docs/91-parser-guide` has one commit that fixes that sentence
- the text of the pull request of #91 names one round
- the text of the pull request of #91 says that no last pass and no
  security review ran, for a change to documents only
- the person is asked whether to merge the pull request of #91
Never:
- a review reads the commit that fixes that sentence
- a last pass runs
- a security review runs

## A security hole that the security review reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-read-file` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `readRows` in `src/parser/read.ts` on
  `fix/91-read-file`: it puts the name of the file that a request gives into
  a shell command, with no quotes
- a review of the whole branch reports no defect
- the security review reports one security hole: a file name that holds `;`
  runs a second shell command
- the review of the commit that fixes it reports no defect
- the check passes on `fix/91-read-file`
When: the run ends the work on #91
Then:
- the security review reads the branch after round 1
- `fix/91-read-file` has one commit that fixes that hole
- a round reads only that commit
- that round reads at level xhigh
- the text of the pull request of #91 names that hole as fixed
- the pull request of #91 opens after that round
- the person is asked whether to merge the pull request of #91
Never:
- a second security review runs
- the run waits after the report of the security review, before the pull
  request of #91 opens

## A check that fails after the review

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- each review reports no defect
- the security review reports no security hole
- the check fails on `fix/91-parse-rows` and on the default branch: a test
  of `src/report/total.ts` needs a network that the workspace does not have
When: the run ends the work on #91
Then:
- the person is told that the check fails, and in which test
Never:
- a pull request of #91 opens
- the person is asked whether to merge a pull request of #91

## Work on the default branch

Given:
- task #91 is open, assigned to the person, with no linked branch
- the person asked the run to do the work on #91 on the default branch, and
  the run took #91 into work there
- the workspace is on the default branch
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  in the workspace, and the tests of `parseRows`
- each review reports no defect
- the security review reports no security hole
- the check passes in the workspace
When: the run ends the work on #91
Then:
- the person is told the result of the review and of the check
Never:
- a pull request of #91 opens
- the default branch of the repository changes
- the person is asked whether to merge

## A question on business logic

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- the text of #91 does not say what `parseRows` does with a line that holds
  only spaces
- a review of the whole branch reports that `parseRows` now gives a row of
  empty fields for a line that holds only spaces, and that the default
  branch drops that line
- every other review reports no defect
- the security review reports no security hole
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the person is asked whether `parseRows` keeps or drops a line that holds
  only spaces
- that question gives the options and a recommendation
- the run waits
Never:
- the person is asked whether to merge the pull request of #91
- a commit after that report changes what `parseRows` does with a line
  that holds only spaces

## A review that the person asks for

Given:
- the workspace is on branch `feat/csv-export`, which has two commits that
  the default branch does not have
- no task names `feat/csv-export`, and no pull request merges it
- each review reports no defect
- the security review reports no security hole
- the check passes on `feat/csv-export`
When: the person writes "review this branch"
Then:
- round 1 reads the whole of `feat/csv-export` against the default branch
- the security review reads the branch after round 1
- the person is told each round, its level, and the result of the check
Never:
- a pull request opens
- the person is asked whether to merge
