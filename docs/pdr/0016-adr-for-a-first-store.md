# 0016 The first data store of its kind gets an ADR for that alone

- Status: rejected
- Level: feature
- Date: 2026-11-24

## Decision

We will not add a fifth reason for an ADR to `skills/architecture/adrs.md`:
the first data store of its kind in a project. A store gets an ADR by the
four reasons, as every other decision: when it changes a quality goal, is
costly to undo, adds an external dependency or sets a pattern that later
code must follow. A small store, as the ids of 10 orders in one
`localStorage` key, is local and cheap to undo, and gets none. The `store`
task of `tests/architecture_eval.sh` measures a store that is a decision:
orders that work offline.

## Rests on

- The old `store` task of `tests/architecture_eval.sh`, recently viewed
  orders, in the arm `skill` on Opus: 0 of 4 runs wrote an ADR, and each
  run that said why gave the reason of the skill: one file, one key, easy to
  undo (#494).
- The four reasons already take a store that sets a pattern: 3 of the 4
  runs that kept a cart in `localStorage` wrote an ADR for it (PR #225).
- The new `store` task, orders that work offline, in the arm `skill` on
  Opus: 3 of 3 runs wrote one ADR with two options and a Confirmation. Each
  weighed `localStorage` against IndexedDB, and chose `localStorage` (#494).
- A reason for a case gets into the text of a skill only after it fails on
  the base text in at least 3 of 10 runs, and an eval that gives the failure
  is fixed instead (ADR 0009, steps 1 and 2).

## Revisit when

The `store` task, or another store that is costly to undo, gets no ADR in
at least 3 of 10 runs with the skill; or a real project has to migrate a
first store that got no ADR, twice.

## Options considered

- A fifth reason, "the first store of its kind": an ADR for each small
  first store, 10 runs on the base text and 10 after it first (about $80).
- The four reasons as they are, and a `store` task whose store is a
  decision: two lines of the eval, and 3 runs to show that the ADR comes
  (about $21).

## Links

#171, #494, PR #225, ADR 0009, PDR 0005
