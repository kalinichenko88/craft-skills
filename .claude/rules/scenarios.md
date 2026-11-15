---
paths:
  - "scenarios/**"
---

# The text of a scenario

A file in `scenarios/` says what a flow does, as seen from outside, and the
skills are checked against it (ADR 0008).

1. Before the edit, read `scenarios/README.md`, the shape of a scenario, and
   `scenarios/TERMS.md`, the words for the things.
2. Give each case one outcome: the summary, the list of what the file does
   not cover and each scenario give one case the outcome that the skill
   gives.
3. A term means what its row in `TERMS.md` says, and nothing more: a row
   holds no rule of a flow. A word that decides a case gets its row before
   a scenario uses it.
4. After the edit, run `bash tests/scenarios_text_eval.sh <file>`. It gives
   no LOST item, or the edit is not done.
