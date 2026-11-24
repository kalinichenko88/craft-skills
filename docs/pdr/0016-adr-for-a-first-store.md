# 0016 The first data store of its kind gets an ADR for that alone

- Status: rejected
- Level: feature
- Date: 2026-11-24

## Decision

We will not add a fifth reason for an ADR to `skills/architecture/adrs.md`:
the first data store of its kind in a project. A store gets an ADR by the
four reasons there, as every other decision. A small store, as the ids of
10 orders in one `localStorage` key, is local and cheap to undo, and gets
none. The `store` task of `tests/architecture_eval.sh` measures a store
that is a decision: orders that work offline.

## Rests on

- The old `store` task of `tests/architecture_eval.sh`, recently viewed
  orders, in the arm `skill` on Opus: 0 of 4 runs wrote an ADR, and each
  run that said why gave the reason of the skill: one file, one key, easy to
  undo (#494).
- The four reasons already give an ADR to a small store in other tasks: 3
  of the 4 runs that kept a cart in `localStorage` wrote one (PR #225).
- The new `store` task, orders that work offline, in the arm `skill` on
  Opus: 3 of 3 runs wrote one ADR with two options and a Confirmation. Each
  chose `localStorage`, and one gave as its reason that the first store on
  the device sets a pattern
  ([#494](https://github.com/kalinichenko88/craft-skills/issues/494#issuecomment-7145448388)).
- ADR 0009, step 2: "An eval or the text of a scenario gives the failure,
  not the skill: fix the eval or the scenario."

## Revisit when

The `store` task gets no ADR in at least 3 of 10 runs with the skill; or a
real project has to migrate a first store that got no ADR, twice.

## Options considered

- A fifth reason, "the first store of its kind": an ADR for each small
  first store, 10 runs on the base text and 10 after it first (about $55,
  at $2.61 to $2.93 a run of the old task).
- The four reasons as they are, and a `store` task whose store is a
  decision: two lines of the eval, and 3 runs to show that the ADR comes
  ($20.68).

## Links

#171, #494, PR #225, ADR 0009, PDR 0005
