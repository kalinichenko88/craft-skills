# 0005 The architecture skill stays whole

- Status: accepted
- Level: feature
- Date: 2026-11-08

## Decision

We will keep `craft:architecture` with its decision steps, its rules of
decomposition and its rules of ADRs. It does not shrink to the ADR rules,
and it does not go. This answers Q-1 of `PRODUCT.md`.

## Rests on

- The full run of `tests/architecture_eval.sh` at `e7b8855`, 5 runs for each
  arm and task, 60 Opus sessions
  ([#87](https://github.com/kalinichenko88/craft-skills/issues/87#issuecomment-6446132028)).
  The split of a file past its limit, in a commit of its own before the
  feature: 0 of 5 with no file and no skill, 0 of 5 with the architecture
  file alone, 5 of 5 with the skill, 5 of 5 with the skill and the
  `CLAUDE.md` line.
- By the rules of #99, *What the numbers decide*: the arm with no file and no
  skill was not as good as the others, so the skill does not go; the arm with
  the file alone was not as good as the arm with the skill and the line, so
  the skill does not shrink to the ADR rules.
- In the same run, the description alone loaded the skill before the first
  write in 15 of 15 runs.

## Revisit when

A run of `tests/architecture_eval.sh` gives an arm with no skill the same
count as the arms with the skill on each task.

## Options considered

- Remove the skill: the split came in 0 of 5 runs with no skill.
- Keep only the ADR rules and the template: the split came in 0 of 5 runs
  with the architecture file alone.
- Keep it whole: the split came in 5 of 5 runs with the skill.

## Links

#87, #99, PR #169, #170, #171
