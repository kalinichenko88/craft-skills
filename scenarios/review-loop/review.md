# Review a change

Reviews read the change on a branch in rounds: when the run ends the work on
a task, when the person asks for a review or for a pull request, when the
person asks the run to handle the review comments on the pull request, or
when the person answers a question that an earlier run asked. The run fixes
what the reviews report, and tells the person what they found. When the run
took a task into work, or the person asked for a pull request, the run then
opens the pull request and asks whether to merge it, in the same run. A spec
and a plan that the run writes get their own reads before the person gets
them. The scenarios of the second reader hold for an implementation that has
one.

Not covered yet:

- the question whether a feature is worth it, on a branch of another person,
  or on the person's own branch when its task holds no worth report:
  `product/worth.md` holds that question, in its own list;
- an implementation with no review for code that is not necessary, and a
  second reader that cannot run;
- an app that does not start, and no way to show the app;
- a change to documents only that changes a spec or the text of a skill,
  and one that gets no second reader;
- review comments on a change to documents only, and review comments
  before the pull request opens;
- a repository with no architecture file;
- a move that a script or a test proves unchanged.

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

## A review for code that is not necessary

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- the review for code that is not necessary reports one thing: the work
  adds `maxOf` to `src/parser/read.ts`, which does what `Math.max` does
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that removes `maxOf`
- round 1 reads the whole branch after that commit
- the text of the pull request of #91 names the review for code that is
  not necessary
- the person is asked whether to merge the pull request of #91
Never:
- the run waits between the report of the review for code that is not
  necessary and round 1

## A fix to a screen

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-rows-table` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 fixes `RowsTable` in `src/ui/rows-table.tsx`, which
  shows the rows of a CSV file on a screen of the app: it showed the header
  row twice; the work changes the tests of `RowsTable` too
- the README of the repository says how to start the app on test data, and
  how to start it on the data of its real users
- the test data holds a row whose first field has 300 characters
- after the work, on that screen, that field runs out of its cell and
  covers the next cell; on the default branch, it stays in its cell
- the check passes on `fix/91-rows-table`
When: the run ends the work on #91
Then:
- the run walks that screen in the app that it starts from the workspace
  of #91
- the walk comes before round 1
- `fix/91-rows-table` has one commit that keeps a field of 300 characters
  in its cell
- round 1 reads the whole branch after that commit
- the workspace of #91 holds no file that the walk wrote
- the text of the pull request of #91 names the walk
- the text of the pull request of #91 names the one thing that the walk
  found
- the person is asked whether to merge the pull request of #91
Never:
- the walk reads the data of the real users of the app
- a commit adds a test that drives the app in place of the walk
- the run waits between the walk and round 1

## A walk that cannot reach the screen

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-rows-table` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 fixes `RowsTable` in `src/ui/rows-table.tsx`, which
  shows the rows of a CSV file on a screen of the app behind a login: it
  showed the header row twice; the work changes the tests of `RowsTable` too
- the README of the repository says how to start the app on test data
- the repository has no test account for that login, and its README names
  none
- the check passes on `fix/91-rows-table`
When: the run ends the work on #91
Then:
- round 1 reads the whole branch
- the text of the pull request of #91 says that the walk did not reach the
  screen, because the login has no test account
- the workspace of #91 holds no file that the walk wrote
- the person is asked whether to merge the pull request of #91
Never:
- a commit adds a dependency to the repository
- a commit adds a test that drives the app in place of the walk

## A defect that the review of the architecture reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-rows-endpoint` is linked to #91, and the workspace of #91
  is on it
- the repository has an architecture file, `docs/ARCHITECTURE.md`, which
  says that only the code in `src/store/` reads the database
- the endpoint `GET /rows` gives the rows of a file in the order in which
  they were saved, and its documents say that it gives them by line number
- the work on #91 changes `readRows` in `src/api/rows.ts` and `loadRows` in
  `src/store/rows.ts`, so that `GET /rows` gives the rows by line number,
  and the tests of both
- the review of the architecture reports one defect: the work makes
  `readRows` in `src/api/rows.ts` read the database
- the check passes on `fix/91-rows-endpoint`
When: the run ends the work on #91
Then:
- the run gives round 1 level high
- the review of the architecture reads the same part of the branch as
  round 1
- `fix/91-rows-endpoint` has one commit that moves that read of the
  database to `src/store/rows.ts`
- a round reads only that commit
- the text of the pull request of #91 names the defect that the review of
  the architecture reported, as fixed
Never:
- the review of the architecture reads the branch a second time

## A redundant test that the review of the tests reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-rows-endpoint` is linked to #91, and the workspace of #91
  is on it
- the endpoint `GET /rows` gives the rows of a file in the order in which
  they were saved, and its documents say that it gives them by line number
- the work on #91 changes `readRows` in `src/api/rows.ts` and `loadRows` in
  `src/store/rows.ts`, so that `GET /rows` gives the rows by line number,
  and the tests of both
- the review of the tests reports one thing: two tests of `loadRows` check
  the same case
- the check passes on `fix/91-rows-endpoint`
When: the run ends the work on #91
Then:
- the run gives round 1 level high
- the person is told the reason for that level in one sentence
- the review of the tests reads the tests of the whole branch after round 1
- `fix/91-rows-endpoint` has one commit that removes one of those two tests
- the text of the pull request of #91 names the review of the tests
Never:
- a round reads the commit that removes that test
- the review of the tests reads the tests a second time

## A defect that the second reader reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-token-expiry` is linked to #91, and the workspace of #91 is
  on it
- before the work on #91, `checkToken` in `src/auth/session.ts` accepts a
  session token that has expired
- the work on #91 makes `checkToken` refuse an expired session token, and
  changes the tests of `checkToken`
- the second reader reports one defect: `checkToken` accepts a session
  token that has no expiry time
- the check passes on `fix/91-token-expiry`
When: the run ends the work on #91
Then:
- the second reader reads the whole branch after round 1
- `fix/91-token-expiry` has one commit that makes `checkToken` refuse a
  session token that has no expiry time
- a round reads only that commit
- the run gives that round level xhigh
- the text of the pull request of #91 names the defect that the second
  reader reported, as fixed
Never:
- the second reader reads the branch a second time

## A defect in each of three rounds at level xhigh

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-token-expiry` is linked to #91, and the workspace of #91 is
  on it
- before the work on #91, `checkToken` in `src/auth/session.ts` accepts a
  session token that has expired
- the work on #91 makes `checkToken` refuse an expired session token, and
  changes the tests of `checkToken`
- round 1 reports one defect: `checkToken` accepts a session token that has
  no expiry time
- round 2 reports one defect in the fix of round 1: `checkToken` refuses a
  session token whose expiry time has no time zone
- round 3 reports one defect in the fix of round 2: `checkToken` reads an
  expiry time with no time zone as local time
- the second reader reports one defect: `checkToken` accepts a session
  token with an empty signature
- the check passes on `fix/91-token-expiry`
When: the run ends the work on #91
Then:
- the second reader reads the whole branch after round 3
- the text of the pull request of #91 names the defect of round 3 as not
  fixed
- the text of the pull request of #91 names the defect that the second
  reader reported as not fixed
- the person is asked whether to merge the pull request of #91
- the question has four answers: merge and remove the workspace of #91,
  merge only, do not merge, and up to three more rounds
Never:
- round 4 runs
- `fix/91-token-expiry` fixes the defect of round 3
- `fix/91-token-expiry` fixes the defect that the second reader reported
- a last pass runs
- the review of the tests runs

## A change to the words of an error message

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-error-words` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes the words of one error message of `parseRows` in
  `src/parser/read.ts`, and changes no test file
- the check passes on `fix/91-error-words`
When: the run ends the work on #91
Then:
- the run gives round 1 level low
- the person is told the reason for that level in one sentence
Never:
- the run gives a round level medium, high or xhigh

## A change to tests only

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `test/91-split-cases` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 adds two cases to the tests of `splitLine` in
  `test/split.test.ts`, and changes no other file
- the check passes on `test/91-split-cases`
When: the run ends the work on #91
Then:
- the run gives round 1 level medium
- the review of the tests reads the tests of the whole branch after round 1
- the text of the pull request of #91 names the review of the tests
- the security review reads the branch after the review of the tests
Never:
- the run gives a round level low

## A round that reads no file of its part of the branch

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- the first read of round 1 reports that it read no file of its part of
  the branch
- the second read of round 1 reports no defect
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- round 1 reads the whole branch a second time
- the text of the pull request of #91 names one round
- the person is asked whether to merge the pull request of #91
Never:
- the pull request of #91 opens before the second read of round 1
- a last pass runs

## A defect on an input that the real data does not hold

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- `parseRows` reads the CSV files that the users of the product upload, and
  `data/samples/` holds 100 of them, as the users uploaded them
- round 1 reports one defect: `parseRows` splits a field that holds a line
  break inside quotes
- no file of `data/samples/` holds a line break inside quotes
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- the text of the pull request of #91 names that report as declined
- the text of the pull request of #91 gives the count of 0 of the 100
  files of `data/samples/` as the reason
- the text of the pull request of #91 names one round
- the person is asked whether to merge the pull request of #91
Never:
- a commit changes how `parseRows` reads a line break inside quotes
- round 2 runs

## A security hole on an input that the real data does not hold

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-read-file` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `readRows` in `src/parser/read.ts` on
  `fix/91-read-file`: it puts the name of the file that a request gives into
  a shell command, with no quotes
- `data/requests/` holds 100 requests that the users of the product sent,
  and no file name in them holds `;`
- round 1 reports one security hole: a file name that holds `;` runs a
  second shell command
- the check passes on `fix/91-read-file`
When: the run ends the work on #91
Then:
- `fix/91-read-file` has one commit that fixes that hole
- that commit adds a test with a file name that holds `;`
- a round reads only that commit
Never:
- the text of the pull request of #91 names that report as declined

## A finding outside the task that round 1 reports

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-parse-rows` is linked to #91, and the workspace of #91 is
  on it
- the work on #91 changes 40 lines of `parseRows` in `src/parser/read.ts`
  on `fix/91-parse-rows`, and the tests of `parseRows`
- `writeCsv` in `src/export/csv.ts` writes a field that holds a comma with
  no quotes; the work on #91 does not change `src/export/`
- no task names `writeCsv` or `src/export/csv.ts`
- round 1 reports one defect: `writeCsv` writes a field that holds a comma
  with no quotes
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- one new task is created for that defect
- the text of the new task names `writeCsv`
- the text of the pull request of #91 names the new task
- the pull request of #91 is open
Never:
- `fix/91-parse-rows` changes `src/export/csv.ts`
- the pull request of #91 closes the new task

## Review comments of another person on the pull request

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- the text of #96 gives the result of an earlier review, with round 1 at
  level medium
- `parseRows` on `fix/91-parse-rows` drops the last field of a line that
  ends with a comma, and keeps the first line of a text
- another person wrote two review comments on #96: the first says that
  `parseRows` drops the last field of a line that ends with a comma, and
  the second says that `parseRows` drops the first line of a text
- the check passes on `fix/91-parse-rows`
When: the person writes "handle the review comments on #96"
Then:
- #96 has one new commit that keeps the last field of a line that ends with
  a comma
- a round reads only that commit
- the run gives that round level medium
- a review comment under the first one names that commit
- the text of #96 names the second review comment as declined, because
  `parseRows` keeps the first line of a text
- the text of #96 names the round on that commit
- the person is asked whether to merge #96
Never:
- a commit changes what `parseRows` does with the first line of a text
- #96 is merged

## A change to the text of a prompt only

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-summary-prompt` is linked to #91, and the workspace of #91
  is on it
- #91 reports that the summary that the product writes gives more than
  five points, and its text asks for at most five
- the work on #91 changes only `prompts/summary.md`, the text of a prompt
  that the product sends to a model
- round 1 reports one defect: one sentence of `prompts/summary.md` asks for
  at most five points, and another for at most three
- the check passes on `fix/91-summary-prompt`
When: the run ends the work on #91
Then:
- `fix/91-summary-prompt` has one commit that fixes that defect
- the second reader reads the whole branch after that commit
- the text of the pull request of #91 names one round
- the text of the pull request of #91 names the second reader
- the text of the pull request of #91 says that no last pass ran, for a
  change to documents only
- the text of the pull request of #91 says that no security review ran,
  for a change to documents only
Never:
- a round reads only the commit that fixes that defect
- a last pass runs
- a security review runs

## A change to the text of a prompt with code

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
- branch `fix/91-summary-date` is linked to #91, and the workspace of #91 is
  on it
- #91 reports that the summary that the product writes has no date, and its
  text asks that the model gives the date in digits
- the work on #91 changes `prompts/summary.md`, the text of a prompt that
  the product sends to a model, and 20 lines of `sendSummary` in
  `src/summary/send.ts`, which reads the answer of the model, and the tests
  of `sendSummary`
- the review of text of round 1 reports one defect: `prompts/summary.md`
  asks the model for a date in words, and `sendSummary` reads a date in
  digits
- the check passes on `fix/91-summary-date`
When: the run ends the work on #91
Then:
- a review of the code reads `src/summary/send.ts` in round 1
- a review of text reads `prompts/summary.md` in round 1
- `fix/91-summary-date` has one commit that fixes that defect in
  `prompts/summary.md`
- a review of text reads only that commit
Never:
- a review of the code reads only the commit that fixes that defect

## More reviews that the person asks for after a change to documents only

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `docs/91-parser-guide`
- pull request #96 of the person is open, merges `docs/91-parser-guide`
  into the default branch, and closes #91
- the work on #91 changes only `docs/parser.md`
- an earlier run gave #96 one round, and asked whether to merge #96, with
  three answers: merge and remove the workspace of #91, merge only, and do
  not merge
- the last pass reports one false sentence: `docs/parser.md` says that
  `parseRows` keeps empty lines, and `parseRows` drops them
- the check passes on `docs/91-parser-guide`
When: the person writes "run a last pass and a security review on #96"
Then:
- a last pass reads the whole of `docs/91-parser-guide` against the default
  branch
- `docs/91-parser-guide` has one commit that fixes that sentence
- the security review reads the branch after that commit
- the text of #96 names the last pass
- the text of #96 names the security review
- the person is asked again whether to merge #96
Never:
- a round reads only the commit that fixes that sentence
- #96 is merged
- a second last pass runs

## Three more rounds whose third round reports a defect

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run ended the rounds on #96 at round 3, and round 3 reported
  a defect that is not fixed: `parseRows` drops an empty line inside quotes
- the earlier run asked whether to merge #96, with four answers: merge and
  remove the workspace of #91, merge only, do not merge, and up to three
  more rounds
- round 4 reports one defect in the fix of round 3: `parseRows` keeps the
  quotes of a field that holds a line break
- round 5 reports one defect in the fix of round 4: `parseRows` drops a
  quote that a field doubles
- round 6 reports one defect in the fix of round 5: `parseRows` reads a
  doubled quote at the end of a field as the end of the field
- the check passes on `fix/91-parse-rows`
When: the person answers up to three more rounds
Then:
- #96 has a commit that fixes the defect of round 3
- #96 has a commit that fixes the defect of round 4
- #96 has a commit that fixes the defect of round 5
- the text of #96 names the defect of round 6 as not fixed
- the person is asked again whether to merge #96
- the question has four answers: merge and remove the workspace of #91,
  merge only, do not merge, and up to three more rounds
- the run waits
Never:
- round 7 runs
- `fix/91-parse-rows` fixes the defect of round 6
- a last pass runs
- #96 is merged

## A defect in round 1 and in round 2, and none in round 3

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
- the check passes on `fix/91-parse-rows`
When: the run ends the work on #91
Then:
- `fix/91-parse-rows` has one commit that fixes the defect of round 1
- `fix/91-parse-rows` has one commit that fixes the defect of round 2
- round 3 reads only the commit that fixes the defect of round 2
- a last pass runs after round 3
- the text of the pull request of #91 names three rounds
- the text of the pull request of #91 names the last pass
- the person is asked whether to merge the pull request of #91
- the question has three answers: merge and remove the workspace of #91,
  merge only, and do not merge
Never:
- round 4 runs

## The answer merge and remove the workspace after a defect in round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- `fix/91-parse-rows` has the same last commit in the repository and in the
  workspace of #91
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run ended the rounds on #96 at round 3, and round 3 reported
  a defect that is not fixed: `parseRows` drops an empty line inside quotes
- the text of #96 names that defect as not fixed
- the repository has the labels `bug` and `docs`
- the earlier run asked whether to merge #96, with four answers: merge and
  remove the workspace of #91, merge only, do not merge, and up to three
  more rounds
When: the person answers merge and remove the workspace of #91
Then:
- the outcomes of The answer merge only after a defect in round 3 hold
- the workspace of #91 is removed
- the workspace has no branch `fix/91-parse-rows`
Never:
- the workspace of #91 is removed before the new task is created

## The answer do not merge after a defect in round 3

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- an earlier run ended the rounds on #96 at round 3, and round 3 reported
  a defect that is not fixed: `parseRows` drops an empty line inside quotes
- the text of #96 names that defect as not fixed
- the earlier run asked whether to merge #96, with four answers: merge and
  remove the workspace of #91, merge only, do not merge, and up to three
  more rounds
When: the person answers do not merge
Then:
- #96 is open
- the text of #96 names the defect of round 3 as not fixed
- the workspace of #91 is on `fix/91-parse-rows`
Never:
- #96 is merged
- a task is created for the defect of round 3
- a commit is added to `fix/91-parse-rows` after the answer

## The answer to a question on business logic that needs a fix

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- `parseRows` on `fix/91-parse-rows` gives a row of empty fields for a line
  that holds only spaces, and the default branch drops that line
- the text of #96 gives one open question on business logic: whether
  `parseRows` keeps or drops a line that holds only spaces
- an earlier run asked the person that question, with the options and a
  recommendation
- the check passes on `fix/91-parse-rows`
When: the person answers drop it
Then:
- #96 has a new commit that makes `parseRows` drop a line that holds only
  spaces
- a round reads only that commit
- the text of #96 gives the answer of the person
- the person is asked whether to merge #96
- the question comes after #96 has that commit
Never:
- #96 is merged

## The answer to a question on business logic that needs no fix

Given:
- task #91 is open, assigned to the person
- the workspace of #91 is on branch `fix/91-parse-rows`
- pull request #96 of the person is open, merges `fix/91-parse-rows` into
  the default branch, and closes #91
- `parseRows` on `fix/91-parse-rows` gives a row of empty fields for a line
  that holds only spaces, and the default branch drops that line
- the text of #96 gives one open question on business logic: whether
  `parseRows` keeps or drops a line that holds only spaces
- an earlier run asked the person that question, with the options and a
  recommendation
- the check passes on `fix/91-parse-rows`
When: the person answers keep it as a row of empty fields
Then:
- the text of #96 gives the answer of the person
- the person is asked whether to merge #96
Never:
- a commit is added to `fix/91-parse-rows` after the answer
- #96 is merged

## A pull request that the person asks for, with no task

Given:
- the workspace is on branch `fix/csv-quotes`, which has two commits that
  the default branch does not have
- the two commits fix how `writeCsv` in `src/export/csv.ts` quotes a field
  that holds a comma, and change no business logic
- no task names `fix/csv-quotes`, and no pull request merges it
- the check passes on `fix/csv-quotes`
When: the person writes "review this branch and open a pull request"
Then:
- round 1 reads the whole of `fix/csv-quotes` against the default branch
- the security review reads the branch after round 1
- a pull request of the person opens, and merges `fix/csv-quotes` into the
  default branch
- that pull request opens after the security review
- the text of that pull request gives the result of each round
- the person is asked whether to merge that pull request
Never:
- that pull request closes a task
- a task is created for `fix/csv-quotes`

## The reads of a spec

Given:
- the person and the run shaped a feature: the export of the rows of a
  table as a CSV file
- the person got a worth report on the export, with the verdict do it
- the run wrote the spec of that feature in `docs/specs/csv-export.md`
When: the run ends the spec of the export
Then:
- the second reader reads the spec
- one more reader reads the spec, of the kind that reads the rounds
- both readers read the spec before the person gets it
Never:
- a round reads the spec
- a security review runs

## The read of a plan against its spec

Given:
- the spec of the export of the rows of a table as a CSV file is in
  `docs/specs/csv-export.md`, and asks that the export quotes a field that
  holds a comma
- the run wrote the plan of the work on that spec in
  `docs/plans/csv-export.md`, and no step of the plan quotes a field that
  holds a comma
When: the run ends the plan of the export
Then:
- a reader that did not write the plan reads the spec and the plan
- the plan has a step that quotes a field that holds a comma
- that step is in the plan before the person gets the plan
Never:
- a round reads the plan
- a security review runs
