---
paths:
  - "tests/*_eval.sh"
  - "tests/fixtures/**"
  - "tests/scenarios_take_in.sh"
  - "tests/scenarios_take_in/**"
  - "tests/fake_gh.sh"
---

# Evals

An eval calls the model, and one run proves neither a failure nor a fix.
A result counts only against a control that ran in the same way.

1. Run an eval alone, with no review or other eval in the same session: a
   skill-load eval beside `/code-review` loaded the skill in fewer runs.
2. Before a zero counts, run the counter on a known positive: a regex that
   stops early counts zero too.
3. Run a control on the base text with the same number of runs as the
   variant. ADR 0009 asks for 10 runs before a case gets a sentence.
4. Do not edit a skill while a batch runs: `tests/scenarios_eval.sh` reads
   the text of the checkout in each round.
