# ZCode as a third host: try the plugin unchanged first, and keep the review text that craft already has

Research of 2026-11-16, for the craft plugin. Sources: the documents and the source of ZCode, the licence files of three Anthropic repositories, and the project's own counts, which are marked as such. **Runs in ZCode on 2026-11-20 filled rows 1, 2, 3, 5, 6, 10 and 11 of *Measurements to make*. One task done in Claude Code and in ZCode on 2026-11-21 filled rows 7, 8, 9 and 14, and gave a first result for row 13: see *One task in two hosts*. The rest was written before any run.** Each statement about ZCode comes from its documents (D) or from its source at commit `fec9759` (S), and a real run can show a different result. The section *Measurements to make* lists what a run must record.

One user of the plugin asked whether craft works in ZCode, the coding agent of Z.ai for the GLM models. The project that this user works on allows no other agent. By its documents, ZCode reads the `.claude-plugin` manifest, the skills and the `SessionStart` hook of craft with no change. Four gaps need a repair: a subagent gets no `rules.md`, the model sees only the first 250 characters of a skill description, ZCode has no built-in reviewer, and an update needs a version that the Claude manifests do not have. Two smaller differences stay: the hook shows no line with the number and the title of an issue, and the model names in the text of the skills name no GLM model. The review prompts that are built into Claude Code cannot go into the plugin: no licence grants a copy, and no public file holds their text. The two prompts that Anthropic published under Apache-2.0 and MIT can be copied by the text of their licences, but the published code review is a different tool, and craft already has a base review prompt of its own with a recorded result. Two product readers gave the same verdict: run the unchanged plugin in ZCode first, then repair only what that run shows.

## What ZCode does with a plugin of Claude Code

| Fact | Source | What it means for craft |
| --- | --- | --- |
| The manifest is found in the order `.zcode-plugin/plugin.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`. | S: `docs/plugin-hooks-compat.md:13-17` | `.claude-plugin/plugin.json` wins. No ZCode manifest is necessary for the first run. |
| A marketplace is added as `owner/repo`, a Git URL or a local folder, in Settings → Plugins. The marketplace of Claude Code is loaded from the start. | D: Plugin | `kalinichenko88/craft-skills` is its own marketplace. |
| The latest version comes from the entry in `marketplace.json`, and the installed version from `plugin.json`, where a missing `version` is `0.0.0`. "If a marketplace entry ships without bumping its `version`, no update is offered even when the plugin code has changed." | D: Plugin | `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` have no `version`. An update of craft in ZCode can stay invisible. |
| A plugin bundles `skills/<name>/SKILL.md`, `commands/*.md`, `agents/*.md`, `hooks/hooks.json` and MCP servers. | D: Plugin | The layout of craft is the same. |
| The skills of the bundled superpowers plugin load as `superpowers:<skill>`, and the bare name is an alias. No document gives the scheme for another plugin. | S: `docs/plugin-hooks-compat.md:141` | `craft:github` in `rules.md` probably keeps its form. A run must show it. |
| The model sees the name of each skill and at most 250 characters of its description. A description over 1,024 characters drops the skill. A body over 100 KB is cut. | D: Skill | All 9 descriptions of craft are longer than 250 characters: from 270 (`typescript-conventions`) to 623 (`product`). None is over 1,024. The triggers after character 250 do not reach the model. |
| The documents do not say whether the model can read a side file or run a script next to `SKILL.md`. | D: Skill | Each flow of craft uses side files and `scripts/`. A run must show it. |
| Seven hook events: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `Stop`. `SubagentStart` and `SubagentStop` are a planned gap, priority P1, with no date. | D: Hooks; S: `docs/hooks-implementation-analysis.md:219` | `hooks/hooks.json:20` registers `SubagentStart` to give `rules.md` to a subagent. In ZCode a subagent gets none. |
| An unknown event in `hooks/hooks.json` gives a warning and does not stop the load of the plugin. | S: `docs/plugin-hooks-compat.md:36` | The `SubagentStart` entry is harmless. |
| `CLAUDE_PLUGIN_ROOT` is set. `additionalContext` is read from `hookSpecificOutput` and from the top level. The limit of one hook output is 32,768 bytes. | D: Hooks; S: `docs/hooks-runtime-contract.md:88` | Each part of `rules.md` is 3,048 and 3,080 bytes as hook output (project count). Both fit. |
| The `SessionStart` matcher reads `source`, and the hook of the bundled superpowers plugin uses `startup\|clear\|compact`. | S: `docs/plugin-hooks-compat.md:138` | The matcher of craft is the same string. |
| The hook input has `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, and `agent_type` when there is one. It names no `prompt_id` and no `turn_id`. | S: `docs/hooks-runtime-contract.md:120-143` | `hooks/session-title.sh:13` prints only for an input with `prompt_id`. In ZCode it prints nothing: no error, and no line with the number and the title of the issue (PDR 0014). |
| `systemMessage` is read only when the output has `decision: "block"`. | S: `apps/zcode-cli/packages/core/src/hooks/output.ts:37-46` | The `systemMessage` of `session-title.sh` would not show, also with the gate removed. |
| The current version has no separate trust switch for hooks, and no approval of hooks for each plugin. | S: `docs/plugin-hooks-compat.md:28` | Unlike Codex, no `/hooks` step after an install or an update. |
| Built-in subagents: `general-purpose` and a read-only `Explore`. A subagent file sets `model`, `tools` and `injectAgentsMd`. Subagents that start together run in parallel. A subagent cannot start a subagent. | D: Subagents; S: `docs/subagent-compatibility.md:110` | A review subagent with a lens file is possible. The `model: "haiku"`, `"opus"` and `"fable"` in the text of the skills name no GLM model. |
| No page that this research read names a `/code-review`, `/security-review` or `/review` command. ZCode ships the superpowers plugin as an official plugin, off by default, and that plugin has a `requesting-code-review` skill. | S: `docs/plugin-hooks-compat.md:131-158`, `apps/zcode-cli/packages/superpowers-plugin/skills/requesting-code-review/` | The code rounds of `craft:review-loop` name commands that ZCode does not have. The round for documents only, one subagent with `docs-lens.md`, has what it needs. |
| A headless run is `zcode --prompt`, with `--output-format stream-json`. | S: `apps/zcode-cli/docs/usage/02-cli-reference.md` (read by a product reader, not checked again) | An eval can drive ZCode, but the parser of its log is new work. |

The latest release on 2026-11-16 is v3.18.2. The repository was made on 2026-09-20.

## Where craft depends on its host

Project counts, from a search of the repository on 2026-11-16.

- **The hooks.** `hooks/hooks.json:20` `SubagentStart`; `hooks/rules.sh:18-25` reads `agent_type` and `turn_id` to skip an `Explore` subagent of Claude Code; `hooks/session-title.sh:13` gates on `prompt_id`, and `:44-45` prints `systemMessage` and `sessionTitle`.
- **The built-in reviewers.** `skills/review-loop/SKILL.md` names `/code-review`, `/security-review` or `/review` on 29 lines: the level table (`:46-61`), round 1 on `<base>..HEAD` (`:189`), the next rounds on `<sha>^..<sha>` (`:196`), the security review in a subagent (`:456-482`). `rules.md:72-73` names the same three.
- **The Codex CLI as a tool.** `skills/review-loop/scripts/codex-review.sh`: the second model at `xhigh`, and with `--docs` the one read of a change to the text of a skill, a prompt or a spec (`skills/review-loop/SKILL.md:393-402`). `skills/review-loop/SKILL.md:590`: the second reader of a spec. `skills/product/SKILL.md:154`: the panel. `skills/debt/SKILL.md:164`: the second reader. Each has a fallback, so none stops the skill.
- **Subagents with a model.** `model: "haiku"` in `rules.md:22`, `skills/roadmap/SKILL.md:108`, `skills/github/tracker.md:47`, `skills/github/plugin-defect.md:163` and `skills/architecture/SKILL.md:354`; `"fable"` in `skills/product/SKILL.md:144`, `skills/debt/SKILL.md:149`, `skills/review-loop/SKILL.md:581` and `skills/architecture/SKILL.md:355-356`; `"opus"` in `skills/review-loop/SKILL.md:264`.
- **Worktree tools.** `EnterWorktree`, `ExitWorktree`, `claude --worktree` and `.claude/worktrees/` in `skills/github/take-in.md`, `continue.md`, `merge.md` and `scripts/worktree.sh`.
- **Sentences for one host.** "In Claude Code" or "In Codex": 12 lines in `skills/review-loop/SKILL.md`, 2 or 3 each in `rules.md`, `skills/github/tracker.md`, `skills/github/plugin-defect.md`, `skills/github/merge.md` and `skills/debt/SKILL.md`.
- **The manifests.** Only `.codex-plugin/plugin.json` has a `version`, and `/release` moves it. No script keeps the manifests the same.
- **The evals.** All 12 `tests/*_eval.sh` call `claude -p`. No eval runs a GLM model.

`scenarios/` has no host word (ADR 0008, the `scenarios` target of the `Makefile`), so the scenarios can measure a third host as they are.

## The review prompts: what a licence allows, and what fits

This section quotes licence files. It gives no legal opinion: whether a copy is allowed is a question for a lawyer.

| Text | Licence | Fit for craft |
| --- | --- | --- |
| The `/code-review` and `/security-review` that are built into Claude Code | `LICENSE.md` of `anthropics/claude-code`: "© Anthropic PBC. All rights reserved. Use is subject to Anthropic's Commercial Terms of Service". Commercial Terms, D.4: the customer may not "reverse engineer or duplicate the Services". No public file holds the text. | Not taken. No grant of a copy was found, and there is no source to copy. |
| `plugins/code-review/commands/code-review.md` in `anthropics/claude-plugins-official`, 7,329 bytes | Apache-2.0, a `LICENSE` file in the folder of the plugin. Section 4 gives the conditions of a copy: the licence, a mark on each changed file, the notices. | A different tool. It reviews a pull request through `gh pr view` and `gh pr comment`, skips a draft and a pull request that Claude has commented on, starts haiku, sonnet and opus subagents, and checks `CLAUDE.md` files. It has no levels and reads no `<sha>^..<sha>` range. craft reviews a branch before its pull request. |
| `.claude/commands/security-review.md` in `anthropics/claude-code-security-review`, 10,837 bytes | MIT, "Copyright (c) 2025 Anthropic". The notice stays in each copy. | Its last sentence is "Your final reply must contain the markdown report and nothing else." The built-in command ends the same way, and so it runs in a subagent (`skills/review-loop/SKILL.md:478-482`). Whether the long prompt finds more than one sentence of instructions is not measured. |
| `skills/review-loop/scripts/codex-review.sh:123`, 5 sentences between the frame of `:112-113` | MIT, the project's own | The base review prompt that craft sends to Codex. The comment above it says that it "found three defects no /code-review round had reported, on three finished branches of this plugin (#59)". |
| `skills/review-loop/SKILL.md:278-279`, 1 sentence | MIT, the project's own | The security instructions that craft gives to `/review` in Codex. |
| `architecture-lens.md`, `docs-lens.md`, `tests-lens.md` in `skills/review-loop/` | MIT, the project's own | The pattern "one review subagent reads the range with a lens file" (`skills/review-loop/SKILL.md:63-71`). |

A fork lowers no dependency in Claude Code or Codex: there the reviewer is a part of the host, and it changes with each release of the host. The two published files together are 18,166 bytes, and `skills/review-loop/SKILL.md` is already over its limit of 20,000 characters (ADR 0006).

## The demand and the cost

Project counts on 2026-11-16 at 22:09 UTC.

- The tracker has 250 issues: 249 from the author and 1 from another person, not about ZCode. A search for "zcode" returns 0 issues.
- The repository has 2 stars and 0 forks. `docs/PRODUCT.md` says: "The first user is the author", and "The client: none".
- In 30 days, 49 of 200 commits on `main` touched `hooks/` or `skills/review-loop/`. Each such commit would change a third host with no eval.
- The current milestone, M3 · Skills hold in real runs, has 24 open issues and 21 closed.
- No measurement of how a GLM model follows a long rules file or a skill was found, in the repository or on the web.
- The cost of a review in GLM credits is not measured. Z.ai gives plan limits that change, and one engineering record of ZCode says that subagents caused 46 % of the sampled rate-limit refusals on 2026-10-20, before a correction. So the first design is one reviewer for each step.

## What the two product readers said

`craft:product` ran at the full depth: a Fable subagent and Codex, each with a web search, and neither saw the answer of the other.

Both gave **do it another way**:

- First run the unchanged plugin in the real ZCode release, and record what loads.
- Then repair only what the run shows.
- Do not take the built-in prompts of Claude Code.
- Do not fork the published `code-review.md`: its behaviour is against the rounds of craft.
- Until a measurement, the documents say "works, not measured", not "supported" (`docs/PRODUCT.md`: "A rule earns its place by a measured run, not by a guess").

They disagree about the review in ZCode:

- **Fable:** put it off until the user works with craft in ZCode and calls the review necessary, or a second person asks. Until then the user turns on the `requesting-code-review` of the bundled superpowers plugin. This way has a conflict that the reader did not name: `rules.md:78-79` says that `craft:review-loop` replaces that skill, so with craft on, the session goes to the review loop. The user starts the superpowers skill by name, or that sentence gets a branch for ZCode.
- **Codex:** put it into the first trial, with the review text that craft already has, one read-only reader for each step, and a limit of 4 hours for the discovery and 16 hours for the trial.

Both name the same decisions:

- PDR 0001 keeps its decision. Its rule of admission, a real project that asks, holds for ZCode. The hosts need a PDR of their own.
- PDR 0012 and PDR 0014 do not change for Claude Code. In ZCode no subagent gets the rules, and the hook shows no title.
- ADR 0008 gives the measure: the same scenarios, and a new reader of the ZCode log.

## The plan

Each stage after the first starts only from what the stage before it showed.

1. **Run the plugin unchanged.** Add the marketplace `kalinichenko88/craft-skills` in ZCode and do one task: take an issue, give an edit to a subagent, review the branch. Record rows 1 to 10 of *Measurements to make*. No line of code changes.
2. **Repair what the run shows.** The expected set: the main trigger of each description in its first 250 characters; the rules in the brief of a subagent that writes, because no hook gives them; a `version` for ZCode. ZCode takes the latest version from the entry in `marketplace.json` and the installed version from the manifest, and its plugin guide says to put the same version into both (S: `apps/zcode-cli/packages/plugin-creator-plugin/skills/plugin-creator/references/installing-and-updating.md`). So a `.zcode-plugin/plugin.json` alone is not enough: the entry in `.claude-plugin/marketplace.json`, which Claude Code reads too, needs a `version`, or ZCode needs a marketplace file of its own. Which files hold the version is a decision of this stage, and `/release` then moves each of them. Row 11 is recorded here.
3. **Review in ZCode with the project's own text.** Move the prompt of `codex-review.sh:123` into a lens file, and give each round to one `general-purpose` subagent with its range. The security review is the sentence of `SKILL.md:278-279`. The ZCode path calls no Codex CLI and no Claude Code, also when they are installed: the user's project does not allow them. The panel of `craft:product` is one reader there. Rows 13 and 14 are recorded here.
4. **Measure before the word "supported".** The scenarios of `scenarios/` are the measure. A GLM model can be measured apart from the host: the existing evals through `claude -p` with the Anthropic-compatible address of Z.ai. That measures the model, not ZCode. Rows 12 and 15 are recorded here.
5. **The documents.** A PDR about the hosts; an ADR for how a host with no built-in reviewer gets its review; *Two hosts* in `docs/ARCHITECTURE.md`, the README and `docs/PRODUCT.md`.

## Measurements to make

Fill the last two columns from real runs. Until then each row is an assumption.

| # | Question | How to measure | Expected by the documents | Result | Date, ZCode version, model |
| --- | --- | --- | --- | --- | --- |
| 1 | Does the plugin install from the repository as it is? | Add the marketplace, install `craft`. `zcode plugins validate <path> --json` | Yes, through `.claude-plugin` | Yes: `plugins marketplace add kalinichenko88/craft-skills`, then `plugins install craft@kalinichenko`. `validate` gives no diagnostic; the version is `0.0.0` | 2026-11-20, desktop 3.19.0, CLI 0.17.3 |
| 2 | Do all 9 skills load, and under which names? | `zcode skills list --json` | 9; probably as `craft:<name>` | 9, as `craft:<name>`. All 47 skills found are visible | 2026-11-20, desktop 3.19.0, CLI 0.17.3 |
| 3 | Do both parts of `rules.md` reach the session at its start? | Ask the session to quote one sentence of each part | Yes | No: each hook failed. The install gives each file the mode 0644, and `hooks/hooks.json` ran the script directly. Yes when each command runs it with `bash`: both sentences quoted word for word | 2026-11-20, desktop 3.19.0, GLM-5.3 |
| 4 | Do they come again after a compaction? | The same question after a compaction | Yes: `SessionStart` with `compact` | | |
| 5 | Does `SubagentStart` in `hooks/hooks.json` stop anything? | The log of the plugin load | A warning only | A warning only: `plugin_hook_unsupported_event` | 2026-11-20, desktop 3.19.0, CLI 0.17.3 |
| 6 | Does a subagent that writes get the rules? | Ask a subagent to quote a sentence of `rules.md` | No | No, in two runs: "No such section exists in my instructions" | 2026-11-20, desktop 3.19.0, GLM-5.3 |
| 7 | Does a skill load by its trigger, with no hint? | In the main session, 10 runs of a prompt that is an issue number alone (`craft:github`), and 10 runs of a TypeScript edit (`craft:typescript-conventions`). Count the runs that load the skill. `tests/skill_load_eval.sh` does not fit as it is: it has no task for the github skill, and it gives each task to a subagent, which gets no rules in ZCode | Unknown: the trigger can be after character 250 | Yes in 1 of 1 run each, not in 10: on the prompt `#5` alone, `craft:github` loaded first. Before the first write to a `.ts` file, `craft:typescript-conventions` loaded | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 8 | Does the model read a side file of a skill? | A take-in that needs `take-in.md` | Unknown | Yes: 6 side files, with the Read tool and their path in the plugin cache, from `take-in.md` to `plugin-defect.md`. ZCode lists each skill to the model with the path of its `SKILL.md` | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 9 | Does the model run a script of a skill with the right path? | A step that runs `bash <dir>/scripts/<name>.sh` | Unknown | Yes: 6 scripts of 4 skills, each as `bash <path in the plugin cache>/scripts/<name>.sh`, in the main session and in the subagents | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 10 | Does `session-title.sh` print anything, or fail? | A prompt that is an issue number alone | Nothing, no error | Nothing and no error. On the prompt `#5` alone, the title of the session stayed `#5`, its first input | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 11 | Is an update offered after a release? | Install, release a version, "Refresh this marketplace", then "Check for updates": the check reads the cached marketplace file | No: the Claude manifests have no `version` | No, through the CLI: after new commits on `main` and `plugins marketplace update kalinichenko`, `plugins update craft@kalinichenko` printed "already up to date (0.0.0)". Only `plugins uninstall --force` and `plugins install` copied the new code (#464) | 2026-11-20, desktop 3.19.0, CLI 0.17.3 |
| 12 | Does a GLM model keep the decisions of `rules.md`? | `tests/rules_decision_eval.sh` through `claude -p` on the Z.ai address | Unknown | | |
| 13 | Does one review subagent with the prompt of `codex-review.sh:123` find the known defects? | Branches with a known defect in code, in ZCode. No eval of the project has such cases for this prompt: `tests/review_loop_lens_eval.sh` checks `architecture-lens.md`. The three branches of the comment at `codex-review.sh:120-122` are a start | Unknown | Not measured with that prompt. With no `/code-review`, the agent sent a `general-purpose` subagent with a prompt that it wrote itself. That reviewer missed the one defect that `/code-review high` found on the same task in Claude Code (*One task in two hosts*, #466) | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 14 | What does one review round cost? | Credits and time of row 13 | Unknown | Round 1 of that run: 8 model calls, 156,595 input tokens (143,168 of them from the cache), 5,733 output tokens, 1 min 40 s. The credits were not recorded | 2026-11-21, desktop 3.19.0, GLM-5.3 |
| 15 | Do 5 real tasks of the user finish with no step of craft started again by hand? | The user's notes | Unknown | | |

The desktop release 3.19.0 differs from the source at `fec9759` in three facts above, on 2026-11-20:

- It bundles no superpowers plugin, and the official marketplace of ZCode, with 76 plugins, lists none.
- Its CLI 0.17.3 is `node /Applications/ZCode.app/Contents/Resources/glm/zcode.cjs`, not on `PATH`, and it has `--json` but no `--output-format`.
- A prompt through that CLI needs `ZCODE_BUILTIN_PROVIDER_CONFIG_FILE=/Applications/ZCode.app/Contents/Resources/config/provider/zcode-builtin.json`. With the login of the app, three tries stopped with "Select a model before sending a message". A community guide gives a profile with a Coding Plan API key ([cli-contract.md](https://github.com/gigio1023/gigio-skills/blob/HEAD/skills/additional/zcode-cli/references/cli-contract.md)), not tried here.

## One task in two hosts

On 2026-11-21 the same task ran in Claude Code and in ZCode: the public issue ai-digest #20, "ci: tsc does not typecheck tests/", in two private copies of that repository. Each host had craft at `13661b7` and no other plugin: Claude Code with `--setting-sources project --plugin-dir`. The prompt was the number of the issue in the copy alone, and the one question of each run got the same answer: merge and clean up.

| | Claude Code, Opus 5.5 | ZCode desktop 3.19.0, GLM-5.3 |
| --- | --- | --- |
| Time from the prompt to the end of *Cleanup* | 21 min | 21 min |
| Steps of craft | Take-in, worktree, review loop, pull request, merge, *Finishing*, *Cleanup* | The same |
| Rounds of the review | Round 1 found a defect; round 2 and the last pass found none | Round 1 found none |
| Reviews of the architecture, the tests and security | All three | All three |
| Model calls | 158 in the main session | 110 with the subagents |

Two results differ:

- **The review of the code** (#466). The first version of both branches replaced `tsc --noEmit` in CI with `tsc -p tsconfig.check.json`, whose `rootDir` is `"."`. CI then no longer checks the build config: a file in `src/` that imports from `tests/` passes CI and fails `npm run build` with TS6059. `/code-review high` found it in Claude Code, and the branch kept both checks. In ZCode, the reviewer that the agent wrote (row 13) named the same `rootDir` as a plus. On the merged `main` of the ZCode copy, such a file passes `tsc -p tsconfig.check.json` with exit 0, and `tsc --noEmit` gives TS6059.
- **The review of the tests** (#467). The same text of `tests-lens.md` read the same new config. Opus gave no finding. GLM-5.3 gave one Missing finding, and the agent added a test that asserts the text of the config and of the workflow.

One run in each host, with a different model in each, does not tell the host, the prompt and the model apart.

Two smaller differences in ZCode: the review of the tests started beside round 1, not after it, as `architecture-and-tests.md` says; and `model: "opus"` of the review of the architecture was dropped, so that subagent ran on GLM-5.3. All five subagents of the ZCode run only read, so the gap of row 6 (#465) had no effect.

## Not assessed

- The behaviour of ZCode with craft past the rows that a run filled. The source documents of ZCode are design records, and the desktop release 3.19.0 differs from them in the three facts under *Measurements to make*.
- How a GLM model follows `rules.md` and the skills past the one task of *One task in two hosts*.
- When ZCode adds `SubagentStart`.
- How long the user's project keeps its rule of ZCode only, and which GLM plan, shell tools and data terms it approves. craft needs bash and a logged-in `gh`.

## Sources

- ZCode documents: [Plugin](https://zcode.z.ai/en/docs/plugin), [Hooks](https://zcode.z.ai/en/docs/hooks), [Skill](https://zcode.z.ai/en/docs/skill), [Subagents](https://zcode.z.ai/en/docs/subagents)
- ZCode source, Apache-2.0, at commit `fec9759`: [plugin-hooks-compat.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/docs/plugin-hooks-compat.md), [hooks-implementation-analysis.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/docs/hooks-implementation-analysis.md), [hooks-runtime-contract.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/docs/hooks-runtime-contract.md), [output.ts](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/apps/zcode-cli/packages/core/src/hooks/output.ts), [subagent-compatibility.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/docs/subagent-compatibility.md), [concurrency.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/docs/dynamic-workflow/concurrency.md), [installing-and-updating.md](https://github.com/zai-org/ZCode/blob/fec975905a2abd4c07e35c40d51fa097a2258ec9/apps/zcode-cli/packages/plugin-creator-plugin/skills/plugin-creator/references/installing-and-updating.md)
- Z.ai: [Claude Code on the GLM models](https://docs.z.ai/devpack/tool/claude), [plans and credits](https://docs.z.ai/devpack/overview), [usage policy](https://docs.z.ai/devpack/usage-policy)
- Anthropic: [LICENSE.md of claude-code](https://github.com/anthropics/claude-code/blob/main/LICENSE.md), [Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms)
- The published code review: [code-review.md](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-review/commands/code-review.md), [its LICENSE](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-review/LICENSE), [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
- The published security review: [security-review.md](https://github.com/anthropics/claude-code-security-review/blob/main/.claude/commands/security-review.md), [its LICENSE](https://github.com/anthropics/claude-code-security-review/blob/main/LICENSE)
