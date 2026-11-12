# Put a task off to Later

The person decides, in the conversation, that a task can wait. The run moves
the task into the milestone `Later`, and makes that milestone when there is
none. When an open task outside `Later` waits on the task, the run moves
nothing: it names each such task with its title, and asks whether to put
those off too, or to remove their dependency on the task.

Not covered yet:

- a task outside `Later` that waits on the task through a chain of tasks;
- a task that is split into smaller tasks, and a smaller task with no
  milestone of its own, which goes into `Later` with it;
- a closed milestone `Later`;
- a task that comes back from `Later`;
- the answer no to the question.

## A task that the person puts off

Given:
- the repository has the milestones `M1 · First demo` and `Later`
- task #50 is open and free, in `M1 · First demo`
When: the person writes "Put #50 off to Later"
Then:
- #50 is in the milestone `Later`
- #50 is open
Never:
- #50 is closed

## A task put off when there is no milestone Later

Given:
- the repository has the milestone `M1 · First demo`, and no other
- task #50 is open and free, in `M1 · First demo`
When: the person writes "Put #50 off to Later"
Then:
- the repository has the milestone `Later`
- #50 is in the milestone `Later`
Never:
- #50 is closed

## A task that another task waits on

Given:
- the repository has the milestones `M1 · First demo` and `Later`
- task #50 is open and free, in `M1 · First demo`
- task #22 is open, in `M1 · First demo`, and waits on #50
When: the person writes "Put #50 off to Later"
Then:
- #50 is in `M1 · First demo`
- the person is told that #22 waits on #50
- the message gives the title of #22
- the person is asked whether to put #22 off too, or to remove the
  dependency of #22 on #50
- the run waits
Never:
- #50 is in the milestone `Later`
- #22 is in the milestone `Later`
- the dependency of #22 on #50 is removed

## The answer to put the waiting task off too

Given:
- the repository has the milestones `M1 · First demo` and `Later`
- task #50 is open, in `M1 · First demo`
- task #22 is open, in `M1 · First demo`, and waits on #50
- the person wrote "Put #50 off to Later", and an earlier run moved nothing,
  told the person that #22 waits on #50, and asked whether to put #22 off
  too, or to remove the dependency of #22 on #50
When: the person answers "Put #22 off too"
Then:
- #22 is in the milestone `Later`
- #50 is in the milestone `Later`
- #22 waits on #50
Never:
- #22 or #50 is closed

## The answer to remove the dependency

Given:
- the repository has the milestones `M1 · First demo` and `Later`
- task #50 is open, in `M1 · First demo`
- task #22 is open, in `M1 · First demo`, and waits on #50
- the person wrote "Put #50 off to Later", and an earlier run moved nothing,
  told the person that #22 waits on #50, and asked whether to put #22 off
  too, or to remove the dependency of #22 on #50
When: the person answers "Remove the dependency"
Then:
- #22 does not wait on #50
- #50 is in the milestone `Later`
- #22 is in `M1 · First demo`
Never:
- #22 is in the milestone `Later`
