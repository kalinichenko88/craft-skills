# 0015 An update of craft reaches each host at a release, not at a push

- Status: accepted
- Level: project
- Date: 2026-11-22

## Decision

We will give the plugin one `version`, the same in `.claude-plugin/plugin.json`,
in the plugin's entry of `.claude-plugin/marketplace.json` and in
`.codex-plugin/plugin.json`, and only `/release` moves it. Claude Code, Codex
and ZCode then update craft at a release. A push to `main` with no release
reaches no install, in Claude Code too, where each push was an update before.
`make check` fails when the three fields differ.

## Rests on

- ZCode offers an update only when the `version` of the marketplace entry is
  above the version of the installed manifest, and a manifest with no
  `version` is `0.0.0` (S: `zai-org/ZCode` at `fec9759`,
  `apps/zcode-cli/packages/adapters/src/plugins/version-compare.ts` and
  `marketplace.ts:2393-2440`). ZCode reads no marketplace file of its own
  before `.claude-plugin/marketplace.json` (`marketplace.ts:2380-2385`).
- With no `version`, ZCode CLI 0.17.3 printed "already up to date (0.0.0)"
  after new commits, through GitHub on 2026-11-20 and through a local folder
  on 2026-11-22. With the three fields at 2.5.1 and then 2.5.2 in a local
  folder, it printed "Updated plugin craft@kalinichenko from 2.5.1 to 2.5.2",
  and the install held the new code (row 11 of
  `docs/research/2026-11-16-zcode-third-host.md`).
- Claude Code takes the `version` of the manifest, then the one of the
  marketplace entry, and the commit SHA only when neither is set
  ([Versions and updates](https://code.claude.com/docs/en/plugins/loading.md#versions-and-updates)).
  So no form gives ZCode a version and keeps each push for Claude Code.
- A release came every 1 to 4 days: 19 tags from 2026-10-22 to 2026-11-19.
- One user asked for craft in ZCode, as that user's project allows no other
  agent (the research doc, *The demand and the cost*).

## Revisit when

A fix waits on `main` for more than 7 days with no release, twice; or a
person asks for the update of each push in Claude Code.

## Options considered

- One `version` in the three fields, moved by `/release`: chosen.
- No `version` in the Claude manifests, and a reinstall in ZCode after each
  release: Claude Code keeps each push, and a ZCode user runs
  `plugins uninstall --force` and `plugins install` by hand.
- A `version` in the marketplace entry only: Claude Code stops at the
  version too, and ZCode compares the entry with `0.0.0` at each check.
- A branch for ZCode alone that carries the versions: a branch outside the
  ruleset of `main`, a second install command, and ZCode CLI 0.17.3 kept the
  `#ref` of a GitHub source but cloned the default branch on 2026-11-22.

## Links

#464, #463, M7 · The skills work in ZCode,
`docs/research/2026-11-16-zcode-third-host.md`
