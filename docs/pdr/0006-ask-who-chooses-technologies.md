# 0006 The agent asks once whether the person chooses the technologies

- Status: accepted
- Level: feature
- Date: 2026-11-09

## Decision

We will have the agent ask the person one question at the start of a work
that needs a new technology, as an external dependency, a framework, a build
tool or a data store: do you want to choose the technologies yourself? After
a no, the agent chooses them, asks nothing more about them, and does not show
its choice afterwards. After a yes, each choice goes to the person as a
question with its options, before the first edit that uses it.

## Rests on

- In a real session, the agent chose a build tool and a router itself, and
  the person stopped it after the code started
  ([#266](https://github.com/kalinichenko88/craft-skills/issues/266)).
- The person's decision on #266, 2026-11-09: a person who said no does not
  need to see the choice.

## Revisit when

A person who answered no stops the agent over a technology that it chose, or
a person who answered yes calls a question about a technology too small to
ask.

## Options considered

- The agent always chooses, as before: the person learns of the choice after
  the code starts (#266).
- A question at each choice: a person who does not want to choose gets
  questions all the same.
- Ask first, and after a no show the choice at the end, as information:
  rejected by the person, because a person who said no does not need it.
- Ask first, and after a no say nothing more: chosen.

## Links

#266, `skills/architecture/SKILL.md` *Who chooses the technologies*
