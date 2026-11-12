# Judge the worth of a feature

The person writes a text that asks for a feature, for a fix of a defect that
changes business logic, for a review of a branch or a pull request, or for
a decision about the whole product; or the run meets a question that
chooses between two ways while it shapes a feature with the person; or a
review of the work on a task reports that the feature gives its users
nothing. The run gives the person a worth report: before the work, at the
question, or at the review. A verdict other than do it is a question, and
the work goes no further before the answer; with no person to answer, the
work goes on, and the report opens the last message. On the answer, the run
writes the product decision, puts the task off to `Later`, or closes the
task as not planned. The person's own feature that has a worth report gets
no other one, except after a review that shows that it gives its users
nothing; the work of another person gets one at each review. A fix that
changes no business logic, a change to documents only of another person and
a bump of a dependency get none.

Not covered yet:

- a task that holds a worth report with the verdict do it, on a feature
  that `docs/PRODUCT.md` rules out: the run gives it no second report, and
  whether that report still counts is a decision of the product, in #365;
- a product decision that gets in the way of a second task, which the run
  then proposes to revisit;
- the branch and the pull request that hold the product decision after a
  deferral or a close, and the product decision after the answer no;
- the next feature in the same conversation, after the answer no to a file
  of product decisions;
- the answer to the question whether to add a worth report to the pull
  request of another person.

## A feature that the person asks for

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the page of orders is in `src/orders/`
When: the person writes "Add an export of the orders to CSV on the page of orders"
Then:
- the person is given a worth report on the export
- the worth report starts with its verdict
- each claim of the worth report gives a number, a place in the code or a
  source, or says that no proof was found
- the worth report gives at most three options
Never:
- a file of the repository changes before the worth report

## A feature that the direction of the product rules out

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `docs/PRODUCT.md` says, in what the shop will not do: take card numbers on
  its own pages, as the customers pay on the page of its payment provider
When: the person writes "Add a form for the card number on the page of an order"
Then:
- the verdict of the worth report on the form is not do it
- the reason of that verdict names that line of `docs/PRODUCT.md`
- the person is asked to decide on that verdict
- the run waits
Never:
- a file of the repository changes

## The answer to a verdict do it another way

Given:
- task #91 is open, assigned to the person; it asks for an export of all the
  orders to CSV
- branch `feat/91-orders-csv` is linked to #91, and the workspace of #91 is
  on it
- `docs/PRODUCT.md` lists the product decisions 0001 to 0003, and
  `docs/pdr/` holds their files; none of them is about an export
- an earlier run gave the person a worth report on #91 before the work on
  #91, with the verdict do it another way and two options: 1, recommended,
  an export of the orders of one month; 2, an export of all the orders
- the earlier run asked which option to take, and changed no file of the
  repository
When: the person answers option 1
Then:
- `docs/pdr/` holds a new product decision with the number 0004
- the new product decision is an export of the orders of one month
- the new product decision has the status accepted
- the new product decision names what it rests on
- the new product decision names when to revisit it
- `docs/PRODUCT.md` lists the new product decision
- one commit on `feat/91-orders-csv` adds the new product decision and its
  line in `docs/PRODUCT.md`
Never:
- a file of `docs/pdr/` that was there before the answer changes
- the work on #91 exports all the orders

## The answer yes to a deferral

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the repository has the milestones `M1` and `Later`
- task #91 is open, in `M1`, with no assignee, no linked branch and no pull
  request; it asks for an export of the orders to a spreadsheet service
- an earlier run gave the person a worth report on #91 with the verdict
  defer until 20 shops ask for that export, and asked whether to put #91 off
  until then
When: the person answers yes
Then:
- #91 is in the milestone `Later`
- the text of #91 names the condition: 20 shops ask for that export
- #91 is open
- `docs/pdr/` holds a new product decision: the export of the orders to a
  spreadsheet service waits until 20 shops ask for it
- `docs/PRODUCT.md` lists the new product decision
Never:
- #91 is closed
- #91 gets an assignee or a linked branch

## The answer yes to a close

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `docs/PRODUCT.md` says, in what the shop will not do: take card numbers on
  its own pages, as the customers pay on the page of its payment provider
- task #91 is open, with no assignee, no linked branch and no pull request;
  it asks for a form for the card number on the page of an order
- an earlier run gave the person a worth report on #91 with the verdict
  close, and asked whether to close #91
When: the person answers yes
Then:
- #91 is closed as not planned
- a comment on #91 holds the worth report
- `docs/pdr/` holds a new product decision with the status rejected: a form
  for the card number on the page of an order
- `docs/PRODUCT.md` lists the new product decision
Never:
- #91 gets an assignee or a linked branch

## A task that holds a worth report

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- task #91 is open, with no assignee, no linked branch and no pull request;
  it asks for an export of the orders to CSV
- the text of #91 holds a worth report on that export, with the verdict do
  it
When: the person writes "#91"
Then:
- the outcomes of A free task hold for #91
Never:
- the person is given a worth report on the export
- the person is asked whether the export is worth its cost

## The review of a feature whose task holds a worth report

Given:
- the run took task #91 into work, and #91 is open, assigned to the person,
  with the label `in progress`
- branch `feat/91-orders-csv` is linked to #91, and the workspace of #91 is
  on it
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the text of #91 holds a worth report on the export of the orders to CSV,
  with the verdict do it
- the work on #91 adds that export to `src/orders/export.ts` on
  `feat/91-orders-csv`, and its tests
- the check passes on `feat/91-orders-csv`
When: the run ends the work on #91
Then:
- the pull request of #91 is open
- the text of the pull request of #91 says that the worth report in #91
  judged the worth of the export
- the person is asked whether to merge the pull request of #91
Never:
- the person is given a worth report on the export

## A review that shows that the feature gives its users nothing

Given:
- the run took task #91 into work, and #91 is open, assigned to the person,
  with the label `in progress`
- branch `feat/91-maker-photos` is linked to #91, and the workspace of #91
  is on it
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the text of #91 holds a worth report on its feature, with the verdict do
  it
- the work on #91 makes the page of a product show a photo from the site of
  its maker, in `src/product/photo.ts` on `feat/91-maker-photos`
- the policy of the page in `public/index.html` lets images come only from
  the shop's own site
- round 1 reports that the browser blocks each photo that the work on #91
  adds, so that no user sees one
- the check passes on `feat/91-maker-photos`
When: the run ends the work on #91
Then:
- the person is given a new worth report on the feature of #91
- the reason of the new worth report names what round 1 reports as its
  proof
- the verdict of the new worth report is not do it
- the pull request of #91 is open
- the text of the pull request of #91 holds the new worth report
- the person is asked which option of the new worth report to take
- the run waits
Never:
- a commit after the report of round 1 changes `src/product/photo.ts`
- the policy of the page in `public/index.html` changes
- the person is asked whether to merge the pull request of #91

## A fix of a defect that changes business logic

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `totalOf` in `src/orders/total.ts` rounds each line of an order before the
  sum, and no document, test or name of the repository says how the total
  rounds
When: the person writes "Fix the total of an order: round the sum, not each line"
Then:
- the person is given a worth report on the change of the rounding
- the worth report starts with its verdict
Never:
- a file of the repository changes before the worth report

## A fix of a defect that changes no business logic

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `listOrders` in `src/orders/list.ts` throws on an empty list of orders, and
  its test says that it returns an empty page
When: the person writes "Fix the crash of the page of orders on an empty list"
Then:
- `src/orders/list.ts` changes in the run
Never:
- the person is given a worth report

## A pull request of another person that changes documents only

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- pull request #96 of another person is open; it changes only `README.md`,
  the text for the people who install the shop
When: the person writes "Review pull request #96"
Then:
- the person is told what the review of #96 reports
Never:
- the person is given a worth report on #96

## A bump of a dependency

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `package.json` asks for `zod` 3.23
When: the person writes "Bump zod to 3.24"
Then:
- `package.json` asks for `zod` 3.24
Never:
- the person is given a worth report

## The review of the person's own branch of a feature with no worth report

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the workspace is on branch `feat/orders-csv`, with two commits of the
  person that the default branch does not have
- the two commits add an export of the orders to CSV in
  `src/orders/export.ts`
- no task names `feat/orders-csv`, no pull request merges it, and no message
  of the conversation holds a worth report on the export
When: the person writes "review this branch"
Then:
- the person is given a worth report on the export
- the worth report comes before the result of round 1
Never:
- a commit is added to `feat/orders-csv` before the worth report

## The review of a pull request of another person that adds a feature

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- pull request #96 of another person is open; it adds an export of the
  orders to CSV in `src/orders/export.ts`
- the text of #96 holds a worth report on the export, with the verdict do it
When: the person writes "Review pull request #96"
Then:
- the person is given a new worth report on the export
- the person is asked whether to add the new worth report to #96 as a
  comment
Never:
- a comment is added to #96 before the person answers

## A feature that the person and the run shape

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
When: the person writes "Let us shape an export of the orders before we build it"
Then:
- the first message about the export asks the person one question about it
- the run waits
Never:
- the first message about the export holds a worth report

## A question that chooses between two ways

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- in this conversation, the run and the person shape an export of the orders
  to CSV, and the person answered each question of the run so far
When: the run meets a question that chooses between two ways: make the CSV at each request, or once a night
Then:
- the message that asks the question holds a worth report on the two ways
- the worth report comes before the options of the question
- the options of the question are the options of the worth report
- the run waits
Never:
- a file of the repository changes before the person answers

## A decision about the whole product

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `docs/PRODUCT.md` says that the shop takes no fee from its sellers
When: the person writes "Should the shop take a monthly fee from each seller?"
Then:
- the person is given a worth report on a monthly fee from each seller
- the worth report names the line of `docs/PRODUCT.md` on the fee
- each claim of the worth report gives a number, a place in the code or a
  source, or says that no proof was found
Never:
- a file of `docs/pdr/` changes before the person answers

## A feature in a repository that keeps no product decisions

Given:
- the repository has no `docs/PRODUCT.md`, no `PRODUCT.md`, no `docs/pdr/`
  and no other file of product decisions
- the instructions of the project say nothing about product decisions
- the page of orders is in `src/orders/`
When: the person writes "Add an export of the orders to CSV on the page of orders"
Then:
- the person is given a worth report on the export
- the person is asked whether to write a `docs/PRODUCT.md` for the project
Never:
- `docs/PRODUCT.md` is created before the person answers yes

## The answer no to a file of product decisions

Given:
- the repository has no `docs/PRODUCT.md`, no `PRODUCT.md`, no `docs/pdr/`
  and no other file of product decisions
- the instructions of the project say nothing about product decisions
- an earlier run gave the person a worth report on an export of the orders,
  and asked whether to write a `docs/PRODUCT.md` for the project
When: the person answers no
Then:
- the person is asked whether to add to the instructions of the project that
  it keeps no `PRODUCT.md`
Never:
- `docs/PRODUCT.md` is created

## Product decisions in a file of another form

Given:
- the repository has no `docs/PRODUCT.md` and no `docs/pdr/`;
  `docs/decisions.md` holds the product decisions of the shop, one dated
  line each
- task #91 is open, assigned to the person; it asks for an export of all
  the orders to CSV
- an earlier run gave the person a worth report on #91 with the verdict do
  it another way and two options: 1, recommended, an export of the orders of
  one month; 2, an export of all the orders
- the earlier run asked which option to take, and changed no file of the
  repository
When: the person answers option 1
Then:
- `docs/decisions.md` holds a new dated line: an export of the orders of one
  month
- the person is asked whether to move the decisions of `docs/decisions.md`
  to `docs/PRODUCT.md` and `docs/pdr/`
Never:
- `docs/PRODUCT.md` is created before the person answers yes
- a file of `docs/pdr/` is created before the person answers yes
- a line of `docs/decisions.md` that was there before the answer changes

## A product decision whose ground changed

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- product decision 0002, accepted, says that the shop pays the card fee of
  each order; it rests on the page of prices of its payment provider, which
  gave 1.4 % of a payment
- the page of prices of the payment provider gives 2.9 % of a payment since
  2026-10-01
When: the person writes "Add a payment by card in three parts"
Then:
- the worth report on the payment in three parts names product decision
  0002 among the decisions that the payment touches
- the worth report says that the price that 0002 rests on is now 2.9 %
Never:
- the status of 0002 changes

## A product decision whose condition to revisit came

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- product decision 0003, accepted, says that the shop has no export of the
  orders; its condition to revisit is that 20 shops ask for one
- 23 open tasks of the tracker, each from another shop, ask for an export
  of the orders
When: the person writes "Add an export of the orders to CSV on the page of orders"
Then:
- the worth report on the export names product decision 0003 among the
  decisions that the export touches
- the worth report says that the condition to revisit 0003 came: 23 shops
  ask for an export
Never:
- the status of 0003 changes

## A task that has to go around a product decision

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- product decision 0001, accepted, says that the shop keeps an order for two
  years and then deletes it; its file has no line under *Got in the way*
- task #91 is open, assigned to the person; it asks for a report of the
  sales of the last five years
- an earlier run gave the person a worth report on #91 that names 0001 as a
  decision that #91 has to go around, with the verdict do it another way
  and two options: 1, recommended, a report of the sales of the last two
  years; 2, a report of five years, with a change of 0001
- the earlier run asked which option to take
When: the person answers option 1
Then:
- the file of 0001 has one line under *Got in the way*, and that line names
  #91
Never:
- the status of 0001 changes
- the decision of 0001 changes

## A feature with no person to answer

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the page of orders is in `src/orders/`
When: the person writes "Add an export of the orders to CSV on the page of orders. Do not ask questions."
Then:
- a file of `src/orders/` changes in the run
- the last message of the run starts with a worth report on the export
- each question of that worth report is marked open
Never:
- the run waits for an answer

## The answer yes to a deferral of a task that another task waits on

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the repository has the milestones `M1` and `Later`
- task #91 is open, in `M1`, with no assignee, no linked branch and no pull
  request; it asks for an export of the orders to a spreadsheet service
- task #22 is open, in `M1`, and waits on #91
- an earlier run gave the person a worth report on #91 with the verdict
  defer until 20 shops ask for that export, and asked whether to put #91 off
  until then
When: the person answers yes
Then:
- #91 is in the milestone `M1`
- the person is told that #22 waits on #91
- the person is asked whether to put #22 off too, or to remove the
  dependency of #22 on #91
- the run waits
Never:
- #91 is in the milestone `Later`

## The answer no to a deferral

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- the repository has the milestones `M1` and `Later`
- task #91 is open, in `M1`, with no assignee, no linked branch and no pull
  request; it asks for an export of the orders to a spreadsheet service
- an earlier run gave the person a worth report on #91 with the verdict
  defer until 20 shops ask for that export, and asked whether to put #91 off
  until then
When: the person answers no
Then:
- #91 is in the milestone `M1`
- #91 is open
Never:
- #91 is in the milestone `Later`

## The answer no to a close

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- `docs/PRODUCT.md` says, in what the shop will not do: take card numbers on
  its own pages, as the customers pay on the page of its payment provider
- task #91 is open, with no assignee, no linked branch and no pull request;
  it asks for a form for the card number on the page of an order
- an earlier run gave the person a worth report on #91 with the verdict
  close, and asked whether to close #91
When: the person answers no
Then:
- #91 is open
Never:
- #91 is closed

## The answer to do the feature as the person asked

Given:
- task #91 is open, assigned to the person; it asks for an export of all the
  orders to CSV
- branch `feat/91-orders-csv` is linked to #91, and the workspace of #91 is
  on it
- `docs/PRODUCT.md` lists the product decisions 0001 to 0003, and
  `docs/pdr/` holds their files; none of them is about an export
- an earlier run gave the person a worth report on #91 before the work on
  #91, with the verdict do it another way and two options: 1, recommended,
  an export of the orders of one month; 2, an export of all the orders
- the earlier run asked which option to take, and changed no file of the
  repository
When: the person answers option 2
Then:
- `docs/pdr/` holds a new product decision with the number 0004
- the new product decision is an export of all the orders
- `docs/PRODUCT.md` lists the new product decision
Never:
- the work on #91 exports only the orders of one month

## A task that records a decision and holds no worth report

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- task #91 is open, with no assignee, no linked branch and no pull request;
  it asks for an export of the orders to CSV
- the text of #91 says that the person chose the export on 2026-11-03, and
  gives two reasons; it holds no worth report
When: the person writes "#91"
Then:
- the person is given a worth report on the export
Never:
- a file of the repository changes before the worth report

## A task of a feature with no worth report

Given:
- the repository keeps its product decisions in `docs/PRODUCT.md` and
  `docs/pdr/`
- task #91 is open, with no assignee, no linked branch and no pull request;
  it asks for an export of the orders to CSV, and its text holds no worth
  report and records no decision
When: the person writes "#91"
Then:
- the first message about #91 tells its gist
- the person is given a worth report on the export, after the gist of #91
Never:
- a file of the repository changes before the worth report
