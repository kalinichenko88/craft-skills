---
paths:
  - "scenarios/**"
---

# The text of a scenario

A file in `scenarios/` says what a flow does, as seen from outside. It is
the text that craft and each other implementation of the flow are checked
against (ADR 0008).

1. Before the edit, read `scenarios/README.md`, the shape of a scenario, and
   `scenarios/TERMS.md`, the words for the things.
2. Give each case one outcome: the paragraph at the top of the file, its
   row in the table of `scenarios/README.md` and each scenario that holds
   the case give it the same outcome.
3. A term means what its row in `TERMS.md` says, and nothing more. A word
   that a case turns on, and that is not a git word or a word in its plain
   meaning, gets its row before a scenario uses it.
4. After the edit, run `scenarios/check.md` by hand, as `CONTRIBUTING.md`
   says: it reads the scenarios against each other.
   `tests/scenarios_text_eval.sh` cannot fail on an edit of a scenario
   alone, as both of its sides read the scenario of the working tree.
