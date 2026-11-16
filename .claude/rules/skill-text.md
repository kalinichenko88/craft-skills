---
paths:
  - "skills/**/*.md"
  - "rules.md"
---

# The text of a skill

`rules.md`, each `SKILL.md` and each side file, a `.md` file beside a
`SKILL.md` that the skill sends the agent to read, are the product: a model
reads them in each run. A `README.md` is not one. These rules apply to each
edit of them. The sources and the measurements are in
`docs/research/2026-11-15-skill-text-breadth.md`. Before a run of an eval,
read `.claude/rules/evals.md`.

## When a case gets a sentence

ADR 0009 decides, and its text wins over this summary. The steps go in
order, and the first step that holds decides:

1. The failure shows in fewer than 3 of 10 runs on the base text, with the
   counter checked on a known positive: write nothing, and close. This step
   does not stop a case of data loss or of a security hole.
2. An eval or the text of a scenario gives the failure: fix it, not the
   skill.
3. The skill did not load, or its side file was not read: fix the trigger,
   the path or the step of reading, not the rule.
4. A machine can check the behaviour, and it has no exception: a script, a
   validator or a hook. Remove the prose about it.
5. The case is an input of a script: a test of the script, with no prose.
6. A rule covers the class but is unclear: rewrite that rule in place, with
   its trigger, action, result, scope or reason. No new sentence.
7. The behaviour depends on a condition: one condition on a sign that can
   be seen, in an ordered list, at the point of the decision, in the file of
   the moment where it occurs. Not a rule and an exception.
8. Else a new sentence, with a run that fails before it and a run that
   passes after it, no worse on the neighbouring cases, and a search for a
   sentence to remove in the same pull request.

A false fact, as a wrong path or a wrong number, is not a case: correct it
at once.

## Budgets

In characters, as `jq -Rs length` counts them (ADR 0009):

| Text | Budget |
| --- | --- |
| A `SKILL.md` | 20,000, the cap that `tests/rules_test.sh` checks; target 15,000 |
| A side file | 10,000 |
| `rules.md` | 6,000; each of its two parts under 10,000 (ADR 0004) |
| A flow: the files that one moment reads | No growth; its target is on its line in `tests/text_size.txt` |

Only the cap of 20,000 and the 10,000 of a part of `rules.md` fail a check.
The other numbers are targets: a text past its target fails nothing. Each
change of the size of a text, a cut too, changes its line in
`tests/text_size.txt` in the same pull request (ADR 0010).

## What Anthropic and OpenAI advise

- Write at the "right altitude": between "hardcoding complex, brittle
  logic" and "vague, high-level guidance"
  ([Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)).
- "Match the level of specificity to the task's fragility and variability":
  exact steps where one path is safe, a direction where many paths are good
  ([Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)).
- Give canonical examples, not a list of edge cases
  ([Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)).
  "Do not turn a particular example, past failure, or personal preference
  into a universal requirement"
  ([OpenAI](https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md)).
- A step with one correct result goes into a script
  ([Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)),
  and a rule that cannot bend into a hook
  ([Claude Code](https://code.claude.com/docs/en/best-practices)).
- Write no rule in capitals for emphasis, as "you MUST": "piling on
  emphasis mostly makes Claude over-apply the rule"
  ([Claude Code](https://code.claude.com/docs/en/best-practices)). Give an
  absolute rule its scope and its reason
  ([Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2)).
- Evals before text: "Create evaluations BEFORE writing extensive
  documentation"
  ([Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices));
  add a block "only when they fix a measured failure mode"
  ([OpenAI](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.4)).
- The rules of the whole task go at the top of a `SKILL.md`: after a
  compaction, the host keeps only the first 5,000 tokens of each skill that
  it keeps, about 20,000 characters (ADR 0006)
  ([Claude Code](https://code.claude.com/docs/en/skills)).
