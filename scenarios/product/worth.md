# Judge the worth of a feature

The person writes a text that asks for a feature, or a review of the work on
a task reports that the feature gives its users nothing. The run gives the
person a worth report on the feature: before the work, or after that review.
A verdict other than do it is a question, and the work waits for the answer.
On the answer, the run writes the product decision, puts the task off to
`Later`, or closes the task as not planned. A feature that has a worth report
gets no other one, except after a review that shows that it gives its users
nothing.

Not covered yet:

- a bug fix that changes business logic, and the changes that get no worth
  report: a bug fix that changes no business logic, a change to documents
  that are not the text of a skill or a prompt, and a dependency bump;
- the review of the person's own branch of a feature that has no worth
  report, and the review of a branch or a pull request of another person;
- a feature whose shape the run asks about before its worth report, a
  question that chooses between two ways while the person and the run shape
  a feature, and a decision about the whole product, as its licence or its
  prices;
- a repository that keeps no product decisions, the offer to start keeping
  them, and decisions that a repository keeps in a file of another form;
- a product decision that the task touches: what it rests on, its condition
  to revisit, and a task that has to go around it;
- the product decision that the run writes after a deferral or a close;
- a run with no person to answer;
- a deferral of a task that an open task outside `Later` waits on;
- the answer no to a deferral or a close, and the answer to do the feature as
  the person asked;
- a task that records a decision with its reasons, and holds no worth report.

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
Never:
- #91 is closed
- the work on #91 starts

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
Never:
- the work on #91 starts

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
- the work on #91 starts in the run
Never:
- the person is given a worth report on the export
- the person is asked whether the export is worth its cost

## The review of a feature whose task holds a worth report

Given:
- the run took task #91 into work, and #91 is open, assigned to the person
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
- the run took task #91 into work, and #91 is open, assigned to the person
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
