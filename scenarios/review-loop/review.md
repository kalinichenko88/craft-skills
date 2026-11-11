# Review a change

Reviews read the change on a branch in rounds: when the run ends the work on
a task, when the person asks for a review, or when the person answers the
question that an earlier run asked after a defect in round 3. The run fixes
what the reviews report, and tells the person what they found. When the run
took a task into work, the run then opens the pull request of the task and
asks whether to merge it, in the same run.

Not covered yet:

- the question whether a feature is worth it, on a branch of another person,
  or on the person's own branch when its task holds no worth report
  (`product/worth.md` covers the rest);
- the review for code that is not necessary, and the walk through a screen
  that the change alters;
- the review of the architecture, the review of the tests, and the second
  reader of a change at level xhigh;
- the levels low and high, and a change to tests only;
- a review that reads no file of its part of the branch;
- a report that needs an input that the real data does not hold, and a
  finding outside the task;
- what a person writes on the pull request about the change;
- a change to the text of a skill, a prompt or a spec, alone or with code;
- a change to documents only after which the person asks for more reviews;
- more rounds that the person asks for, whose third round reports a defect;
- a defect in round 1 and in round 2, and none in round 3;
- the answers merge and remove the workspace, and do not merge, after a
  defect in round 3;
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
- round 1 reports no defect, and two other things: the docstring of
  `parseRows` gives a wrong count of fields, and the name of a test does not
  say what it tests
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the docstring and the name
  of the test
- the security review reads the branch after that commit
- the pull request of #91 is open
- the text of the pull request of #91 names the level of round 1
- the text of the pull request of #91 names the part of the branch that
  round 1 read
- the text of the pull request of #91 gives the result of the security
  review
- the text of the pull request of #91 gives the result of the check
- the pull request of #91 opens after the security review
- the person is asked whether to merge the pull request of #91
- the run waits
Never:
- a round reads only the commit that fixes the docstring and the name of
  the test
- a last pass runs
- the run waits before the pull request of #91 opens

## A defect in the first round

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- round 1 reports one defect: `parseRows` drops the last field of a line
  that ends with a comma
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes that defect
- round 2 reads only that commit
- a last pass runs after round 2
- the text of the pull request of #91 names two rounds
- the text of the pull request of #91 names the last pass
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
- round 1 reports one defect: `parseRows` drops the last field of a line
  that ends with a comma
- the last pass reports one defect: `countFields` in `src/parser/read.ts`
  still gives the old count for a line that ends with a comma
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
- round 1 reports one defect: `parseRows` drops the last field of a line
  that ends with a comma
- round 2 reports one defect in the fix of round 1: `parseRows` gives one
  empty field for an empty line
- round 3 reports one defect in the fix of round 2: `parseRows` drops an
  empty line inside quotes
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the defect of round 1
- `fix/91-parse-rows` has one commit that fixes the defect of round 2
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

## The answer merge only after a defect in round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run ended the rounds on #96 at round 3, and round 3 reported
  a defect that is not fixed: `parseRows` drops an empty line inside quotes
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
- the text of the new task names `parseRows`
- the text of the new task says how the defect shows
- the new task has the label `bug`
- the last message names the new task with its id and its title
Never:
- a commit is added to `fix/91-parse-rows` after the answer

## The answer more rounds after a defect in round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run ended the rounds on #96 at round 3, and round 3 reported
  a defect that is not fixed: `parseRows` drops an empty line inside quotes
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
  a wrong default separator, and adds no logic; it changes one test of
  `splitLine` in `test/split.test.ts`
- the check passes on `fix/91-split-default`
When: the run ends the work on #91
Then:
- the run gives round 1 level medium
- the person is told the reason for that level in one sentence
Never:
- the run gives a round level low

## A fix to the expiry of a session token

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-token-expiry` is linked to #91, and the workspace of #91 is
  on it
- before the work on #91, `checkToken` in `src/auth/session.ts` accepts a
  session token that has expired
- the work on #91 makes `checkToken` refuse an expired session token, and
  changes the tests of `checkToken`
- the check passes on `fix/91-token-expiry`
When: the run ends the work on #91
Then:
- the run gives round 1 level xhigh
- the person is told the reason for that level in one sentence
Never:
- the run gives a round level low, medium or high

## A change to documents only

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `docs/91-parser-guide` is linked to #91, and the workspace of #91
  is on it
- the work on #91 changes only `docs/parser.md`, on `docs/91-parser-guide`
- round 1 reports one false sentence: `docs/parser.md` says that
  `parseRows` keeps empty lines, and `parseRows` drops them
- the check passes on `docs/91-parser-guide`
When: the run ends the work on #91
Then:
- `docs/91-parser-guide` has one commit that fixes that sentence
- the text of the pull request of #91 names one round
- the text of the pull request of #91 says that no last pass ran, for a
  change to documents only
- the text of the pull request of #91 says that no security review ran,
  for a change to documents only
- the person is asked whether to merge the pull request of #91
Never:
- a round reads only the commit that fixes that sentence
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
- the security review reports one security hole: a file name that holds `;`
  runs a second shell command
- the check passes on `fix/91-read-file`
When: the run ends the work on #91
Then:
- the security review reads the branch after round 1
- `fix/91-read-file` has one commit that fixes that hole
- a round reads only that commit
- the run gives that round level xhigh
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
- the check fails on `fix/91-parse-rows` and on the default branch: a test
  of `src/report/total.ts` needs a network that the workspace does not have
When: the run ends the work on #91
Then:
- the person is told which test of the check fails
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
- the check passes in the workspace
When: the run ends the work on #91
Then:
- the person is told the result of each round
- the person is told the result of the check
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
- round 1 reports that `parseRows` now gives a row of empty fields for a
  line that holds only spaces, and that the default branch drops that line
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the person is asked whether `parseRows` keeps or drops a line that holds
  only spaces
- that question gives the options
- that question gives a recommendation
- the run waits
Never:
- the person is asked whether to merge the pull request of #91
- a commit after that report changes what `parseRows` does with a line
  that holds only spaces

## A review that the person asks for

Given:
- the workspace is on branch `fix/csv-quotes`, which has two commits that
  the default branch does not have
- the two commits fix how `writeCsv` in `src/export/csv.ts` quotes a field
  that holds a comma, and change no business logic
- no task names `fix/csv-quotes`, and no pull request merges it
- the check passes on `fix/csv-quotes`
When: the person writes "review this branch"
Then:
- round 1 reads the whole of `fix/csv-quotes` against the default branch
- the security review reads the branch after round 1
- the person is told the level of each round
- the person is told the result of each round
- the person is told the result of the check
Never:
- a pull request opens
- the person is asked whether to merge
