# Take the next task, or run tasks in parallel

The person asks what to take now, what the priority is, or what can run in
parallel. The three questions get one answer from the plan in the tracker:
the path to the goal, with the top bug beside it, in at most three lanes. The
goal is the first current milestone, and lane 1 holds the tasks that its
`Done when` needs. No task of one lane changes a function that a task of
another lane, or a busy task, changes. For "what can I take now", the run
gives one task. The run changes nothing in the tracker or in the repository.

Not covered yet:

- the question what the priority is, which gets the answer of parallel work;
- the person's own busy tasks, which the answer shows beside the lanes;
- a task of the goal that is split into smaller tasks, and a smaller task
  with no milestone of its own;
- a task in `Later` that a task outside `Later` waits on;
- a first current milestone with no free task that its `Done when` needs,
  when the next milestone becomes the goal;
- a repository with no milestone, where the path goes to the goal in the
  documents of the product;
- a task whose text waits on a decision;
- five bugs, or five other tasks, that each change a function of a lane.

## The next task on the path to the goal

Given:
- `M1 · First demo` is the current milestone; its `Done when` has one
  outcome, a new user signs up, with task #21
- task #21 is open and free, in `M1 · First demo`; it adds the sign-up form
  in `src/auth/signup.ts`
- task #30 is open and free, in `M1 · First demo`, and older than #21; it
  sets up a test environment in `ci/`
- tasks #31, #32 and #33 are open, in `M1 · First demo`, and wait on #30
When: the person writes "What can I take now?"
Then:
- the person is told that #21 is the task to take, with its title
- the message names `M1 · First demo` as the milestone of #21
- the message names the outcome that needs #21: a new user signs up
Never:
- #30 is given as the task to take
- a label, an assignee or the milestone of a task changes
- a branch is created

## Three lanes for parallel work

Given:
- `M1 · First demo` is the current milestone, and `M2 · Payments` comes
  after it
- the `Done when` of `M1 · First demo` has one outcome, a new user signs up,
  with tasks #21 and #22
- task #21 is open and free, in `M1 · First demo`; it adds the sign-up form
  in `src/auth/signup.ts`
- task #22 is open and free, in `M1 · First demo`, and newer than #21; it
  adds the welcome mail in `src/mail/welcome.ts`
- task #40 is open and free, in `M1 · First demo`, with the label `bug`; it
  reports that a session ends after one minute, in `src/session/timer.ts`
- task #41 is open and free, in `M2 · Payments`, with the label `bug`; it
  reports a wrong sum in `src/cart/total.ts`
- task #50 is open and free, in `M1 · First demo`; it renames the helpers of
  `src/log/format.ts`
When: the person writes "What can run in parallel?"
Then:
- the person is given three lanes
- lane 1 starts with #21
- lane 2 starts with #40
- lane 3 starts with #22
- the person is told that #41 waits, and what holds it
- the person is told that #50 waits, and what holds it
Never:
- a lane holds #41
- a lane holds #50
- a label, an assignee or the milestone of a task changes

## A task that changes the function of another person's work

Given:
- `M1 · First demo` is the current milestone; its `Done when` has one
  outcome, a new user signs up, with tasks #21 and #22
- task #21 is open and free, in `M1 · First demo`; it changes the function
  `signUp` in `src/auth/signup.ts`
- task #22 is open and free, in `M1 · First demo`, and newer than #21; it
  adds the welcome mail in `src/mail/welcome.ts`
- task #25 is open, in `M1 · First demo`, assigned to another person
- pull request #96 of another person is open, closes #25, and changes the
  function `signUp` in `src/auth/signup.ts`
When: the person writes "What can run in parallel?"
Then:
- lane 1 starts with #22
- the person is told that #21 waits, and that #96 changes `signUp` in
  `src/auth/signup.ts`
Never:
- a lane holds #21
- a lane holds #25

## Two tasks of the goal that change one function

Given:
- `M1 · First demo` is the current milestone; its `Done when` has one
  outcome, a new user signs up, with tasks #21 and #22
- task #21 is open and free, in `M1 · First demo`; it adds the sign-up form
  to the function `signUp` in `src/auth/signup.ts`
- task #22 is open and free, in `M1 · First demo`, and newer than #21; it
  checks the e-mail address in the function `signUp` in
  `src/auth/signup.ts`
- task #40 is open and free, in `M1 · First demo`, with the label `bug`; it
  reports that a session ends after one minute, in `src/session/timer.ts`
When: the person writes "What can run in parallel?"
Then:
- lane 1 holds #21, then #22
- lane 2 starts with #40
- the person is told that #21 and #22 both change `signUp` in
  `src/auth/signup.ts`
Never:
- #21 and #22 are in two lanes

## A task of the goal that waits on another task

Given:
- `M1 · First demo` is the current milestone; its `Done when` has two
  outcomes: a new user signs up, with task #21, and the user sees an empty
  dashboard, with task #23
- task #21 is open and free, in `M1 · First demo`; it adds the sign-up form
  in `src/auth/signup.ts`
- task #23 is open, in `M1 · First demo`, and waits on #21; it shows an
  empty dashboard in `src/dashboard/empty.ts`
When: the person writes "What can run in parallel?"
Then:
- lane 1 starts with #21
- the person is told that #23 waits on #21
Never:
- a lane holds #23

## A goal whose Done when names no task

Given:
- `M1 · First demo` is the current milestone; its `Done when` has one
  outcome, a new user signs up, with no task
- task #21 is open and free, in `M1 · First demo`; it adds the sign-up form
  in `src/auth/signup.ts`
When: the person writes "What can I take now?"
Then:
- the person is told that #21 is the task to take
- the person is told that the `Done when` of `M1 · First demo` names no
  task
- the person is asked whether to plan `M1 · First demo` again
Never:
- the text of `M1 · First demo` changes
