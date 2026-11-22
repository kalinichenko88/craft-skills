# A defect in this plugin

The global prompt says when a defect in this plugin becomes an issue; this
file says how. The plugin is the global prompt, the hooks, the
`craft:` skills and their scripts. The global prompt is `rules.md` and
the hooks are in `hooks/`, at the plugin root: two directories above this
skill's base directory. Its tracker is
`github.com/kalinichenko88/craft-skills`. Every `gh` call below names it with
its host, so the project's remote and `GH_HOST` do not matter. Only this
file and *Public repositories* in `SKILL.md` apply: `filing.md`,
`tracker.md` and their scripts work on the checkout's tracker. In a checkout
of `craft-skills` itself, only the next paragraph, *Make sure the plugin is
wrong* and *The session at the end* apply. There, a defect is a finding of
`filing.md`.

Claude Code's `SendFeedback` tool and its `/feedback` command send a draft to
Anthropic, not to this tracker. Make no `SendFeedback` draft for a defect in
this plugin: it goes here.

**Make sure the plugin is wrong.** Read the rule or the script again, all of
it. These are defects:

- A script fails, or prints a wrong result, on valid input.
- Two rules say opposite things for the same case.
- A rule, followed as written, gives a wrong result.
- A rule names a file, a script, a flag or a command that does not exist.
- A step of the plugin, in the global prompt or a `craft:` skill, that you
  skipped or read wrong, and the person had to point out. Do the step at
  once, and ask nothing: *The session at the end*, below, drafts it.

These are not defects:

- A step you skipped or read wrong, and found yourself. Go back and do it as
  written.
- A bug in the person's project.
- A bug in another plugin, in Claude Code or in Codex.

**A subagent files nothing.** It names the defect in its report. The agent that
sent it asks the person.

**Read the files on `main`.** The copy that runs can be older than `main`:

```bash
gh api --hostname github.com -H "Accept: application/vnd.github.raw" \
  repos/kalinichenko88/craft-skills/contents/<path>
```

When `gh` prints `HTTP 404`, `main` has no file at that path. Find the file
that holds the rule or the script now in this list, and read it there:

```bash
gh api --hostname github.com \
  "repos/kalinichenko88/craft-skills/git/trees/main?recursive=1" \
  --jq '.tree[].path'
```

When no file on `main` holds the rule or the script, `main` does not have the
defect. When the read fails in any other way, skip this step and the search,
and go on to *Write the issue*.

When `main` does not have the defect, file nothing. Tell the person that `main`
does not have the defect. Give the file and the line of the defect in the copy
that runs. Give the link
`https://github.com/kalinichenko88/craft-skills#update`, and say that it is for
an installed plugin, and that an update brings the fix only when a release
holds it.

**Search**, by the name of the script, the skill or the rule's heading:

```bash
gh issue list --repo github.com/kalinichenko88/craft-skills --state all \
  --limit 200 --search "<name>" --json number,title,state,stateReason
gh pr list --repo github.com/kalinichenko88/craft-skills --state all \
  --limit 200 --search "<name>" --json number,title,state
```

A title alone does not show whether the report is the same. Read the whole of
each issue that can match, with its comments, and the diff of each pull
request that can match:

```bash
gh issue view <n> --repo github.com/kalinichenko88/craft-skills \
  --json title,body,comments
gh pr diff <n> --repo github.com/kalinichenko88/craft-skills
```

- An open issue has the same report: file nothing. The same defect can be in
  another file of the plugin, or you can have a new reproduction. Then write
  it as a comment, as *Write the issue* below says. Ask before you write it,
  as *Ask the person* below says.
- An open pull request fixes it: file nothing. Give the person its number
  and its title.
- A pull request closed without a merge does not decide the case. Name it in
  the issue you file.
- A closed issue has the same report, and its `stateReason` is `NOT_PLANNED`:
  file nothing. It was decided. Give the person its number and its title.
- A closed issue with the `stateReason` `DUPLICATE`: judge the issue that it
  duplicates by these bullets instead. This call gives its repository,
  number, title and state:

  ```bash
  gh api --hostname github.com graphql -f query='{ repository(owner:
    "kalinichenko88", name: "craft-skills") { issue(number: <n>) {
    duplicateOf { number title state stateReason
    repository { nameWithOwner } } } } }'
  ```

  When `nameWithOwner` is not `kalinichenko88/craft-skills`, the report is in
  another tracker. File nothing. Give the person that issue's repository,
  number and title. When `duplicateOf` is `null`, or the call fails, the issue does
  not decide the case: name it in the issue you file.
- `main` has the defect again, and a closed issue with `COMPLETED` or a
  merged pull request fixed it before: file a new issue. Its body starts
  `Regression of #12`.

**Write the issue.** The tracker is public. Take the person's project as a
private source, whatever its visibility, and apply *Public repositories* in
`SKILL.md` to it. Write the case again as the smallest reproduction, with
neutral names. Paths inside the plugin, as
`skills/github/scripts/collect.sh:42`, stay as they are. The title states the
problem and starts with the part of the plugin: the skill, as `github:`,
`rules:` for the global prompt, `hooks:` for a hook. The body says:

- The plugin version and its commit: one version holds the commits up to the
  next release. The plugin root is this skill's base directory without
  `/skills/github`. In Codex, the version is `version` in the root's
  `.codex-plugin/plugin.json`. When `<root>/.git` exists, as in Codex or with
  `claude --plugin-dir`, the commit is
  `git -C "<root>" rev-parse --short=12 HEAD`. Else, in Claude Code, the root
  ends in the version, as `2.5.1`, and the commit is the first 12 characters
  of `gitCommitSha` in the entry of `~/.claude/plugins/installed_plugins.json`
  whose `installPath` is the root; with no such entry, give the version
  alone. Write the version, not the path.
- The tool: Claude Code or Codex.
- The file and the line in the plugin, and what the rule or the script says.
- What happened, and what you expected.
- The steps that show it again.

Put no label on it and assign nobody: only a person with access to the
repository can set them.

**Ask the person** at the end of the task, or at once when the defect blocks
it. Show the full text: the title and the body of an issue, or the body of a
comment. Say that the repository is public. Write only after a yes for this
text: a changed text needs a new yes. A no, or no answer, writes nothing; put
the draft in the final report. After the yes, write the body, and the title of
an issue, with the file tool to two files outside every checkout, not with the
shell: a quote, a backtick or a `$(` in the text can run a command. Then run
one of:

```bash
gh issue create --repo github.com/kalinichenko88/craft-skills \
  --title "$(cat "$title_file")" --body-file "$body_file"
gh issue comment <n> --repo github.com/kalinichenko88/craft-skills \
  --body-file "$body_file"
```

When `gh` is not installed, `gh auth status --hostname github.com` fails or the
call fails, give the person the draft and the link: for an issue,
`https://github.com/kalinichenko88/craft-skills/issues/new`; for a comment,
`https://github.com/kalinichenko88/craft-skills/issues/<n>`.

List the issue number and its title in the final report.

**The session at the end.** *Finishing* in `merge.md` runs this step after the
merge. It finds the steps that the person pointed out during the work, and
the scripts of the plugin that failed.
In Claude Code, send one `Agent` call with `subagent_type: "Explore"`,
`model: "haiku"` and this prompt, with the plugin root and the value of
`$CLAUDE_CODE_SESSION_ID` in it:

```
Read the transcript of a Claude Code session,
~/.claude/projects/*/<session id>.jsonl, with your file and search tools.
Change nothing, and file nothing. Write no file, not even in /tmp: use pipes.
Return two lists:

1. Corrections: each message in which the person says that the agent skipped
   a step, did it wrong or did it out of order. The person's words are in the
   records with "type":"user" whose message.content is a string, in the
   "prompt" of each attachment with "type":"queued_command" (a message sent
   while the agent worked), and in the tool results of AskUserQuestion.
   Search each of the three. A text that starts with <task-notification>,
   <command-, <local-command- or "This session is being continued" is not
   the person's.
2. Failed calls: each tool result with "is_error":true whose tool_use, the
   one with the same id, runs a file under <plugin root>.

For each item: its timestamp, the person's words or the command, and the
first three lines of the error. Write "none" for an empty list.
```

Each item is a candidate, not a defect. A correction is a defect only when the
step is a step of the plugin. A failed call is a defect only by *Make sure the
plugin is wrong*: a wrong call by the agent, a guard of Claude Code or a bug of
the project is not. For each defect, go on from *Read the files on `main`*,
and show all the drafts in one question by *Ask the person*. In a checkout of
`craft-skills`, file each one as a finding of `filing.md` instead. The
Boy Scout check does not apply to them: the merged pull request takes no more
fixes.
Codex keeps its sessions as compressed files, and has no subagent with a
model: there, take the corrections and the failed calls from your own
context.
