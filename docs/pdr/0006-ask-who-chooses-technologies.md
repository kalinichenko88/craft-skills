# 0006 The agent asks once whether the person chooses the technologies

- Status: accepted
- Level: feature
- Date: 2026-11-09

## Decision

We will have the agent ask the person one question when the work needs a new
technology, as an external dependency, a framework, a build tool or a data
store, before it chooses the first one: do you want to choose the
technologies yourself? After a no, the agent chooses them, asks nothing more
about them, and does not tell the person its choice afterwards; the ADR and
the pull request still record it. After a yes, each choice goes to the
person as a question with its options, before the first edit that uses it.
With no person, the answer is no.

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

## Checked

- 2026-11-09 8 Opus runs of `claude -p` on a web-app task in
  `tests/fixtures/architecture/repo`, 3 on the text before and 5 on the new
  text: 0 of 8 asked. `claude -p` gives no question tool, and the runs wrote
  that no one can answer, so they took the answer no, as the decision says
  for a run with no person. The branch with a person is not measured.
