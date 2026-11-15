# The program of count.sh: one row per event, in the order of the records. A
# load of a SKILL.md, a compaction, a run of a script, a read of a .md file of
# a skill, the result of a tool call, and for a rule of $rules, the table of
# rules.json, by its number: the text that states it, its trace and its moment.

def text: if type == "string" then . else [.[]? | .text? // empty] | join("") end;
def skill: "/plugins/cache/[^/]+/(craft|kalinichenko)/[^/]+/skills/(?<skill>[a-z-]+)";
# A .md file at the top of a skill's folder as a trace of a rule: from the
# cache or from a checkout, since the text is the same; not from a folder
# claude/skills, as ~/.claude/skills or a copy of it, where a skill of the
# same name is another one.
def file: "(^|/)(?<!claude/)skills/(?<skill>[a-z-]+)/(?<rest>[^\\s\"'/]*[.]md)\\b";

# The rules that $text, the text of $from, states: rules.md or a SKILL.md, as
# github/SKILL.md. The rules whose text is $file, as github/take-in.md. The
# rules whose moment f finds, with the rule as its input: a rule with main is
# no moment in a subagent.
def given($from; $text):
  $rules[0] | to_entries[] | .value as $r | select($r.from == $from and ($text | test($r.says))) | .key + 1;
def traces($file): $rules[0] | to_entries[] | select(.value.text == $file) | .key + 1;
def moments($f; f):
  $rules[0] | to_entries[] | select((.value | f) and (.value.main != true or ($f | test("/subagents/") | not))) | .key + 1;

# The commands of a Bash call, in the order they end. It splits at ; & | and
# new lines, but not in quotes and not at the & of a redirection, as 2>&1. A
# command in $(...), <(...) or backquotes comes before the command around it,
# which runs after it. A heredoc body is no command.
def parts:
  gsub("<<-?[ \t]*['\"]?(?<w>[A-Za-z_]+)['\"]?(?<r>[^\n]*)\n[\\s\\S]*?\n[ \t]*\\k<w>(?=\n|$)"; "\(.r)")
  | [scan("'[^']*'|\"(?:\\\\.|[^\"\\\\$]|[$](?![(]))*\"|[0-9]*[<>]&[0-9-]*|[&]>{1,2}|[$<>][(]|[`;&|\n)]|[^'\"`;&|\n$<>)]+|[\\s\\S]")]
  | reduce .[] as $t ({out: [], stack: [{text: "", close: ""}]};
      if ($t | test("^[$<>][(]$")) or ($t == "`" and .stack[-1].close != "`") then
        .stack += [{text: "", close: (if $t == "`" then "`" else ")" end)}]
      elif $t == .stack[-1].close then .out += [.stack[-1].text] | .stack |= .[:-1]
      elif $t | test("^[;&|\n]$") then .out += [.stack[-1].text] | .stack[-1].text = ""
      else .stack[-1].text += $t end)
  | .out + [.stack[].text];
def subst($vars): reduce ($vars | to_entries[]) as $e (.; gsub("[$][{]?" + $e.key + "\\b[}]?"; $e.value));
def word: sub("^\\s+"; "") | sub("\\s+$"; "") | gsub("['\"]"; "");
def resolve($dir): sub("^[.]/"; "") | if test("^[/~$]") or $dir == "" then . else $dir + "/" + . end;

# The script of a skill that the last command of the call runs, with bash and
# its options or by its path, as [skill, script]; and the skill of the first
# command that names a .md file of a skill with cat, sed, head, tail, grep or
# awk. An assignment, a cd, an empty command, a comment, and done, fi or esac
# with their redirections are no last command. A
# variable takes its value from an assignment before it in the call, and a
# relative path takes the folder of a cd before it. And each command, with
# the .md files of skills that it reads, in cmds: so a read and a moment of
# one call keep their order. A gh -R <repo> before its group is gh.
# ponytail: a variable that $(...) sets stays empty, so f=$(ls <skill>/x.md);
# cat "$f" is no read: 4 of 2,645 calls on 2026-11-09. Resolve it when it
# grows.
def commands:
  reduce parts[] as $p ({vars: {}, dir: "", run: null, read: null, cmds: []};
    .vars as $v | .dir as $d
    | ($p | subst($v) | sub("^([\\s(){}!]|(do|then|else|time|if|while|until|export)\\s)*"; "")) as $q
    | if $q | test("^[A-Za-z_][A-Za-z0-9_]*=\\S*\\s*$") then
        .vars[$q | capture("^(?<k>[^=]+)").k] = ($q | sub("^[^=]+="; "") | word)
      elif $q | test("^cd\\s") then .dir = ($q | sub("^cd\\s+"; "") | word | resolve($d))
      elif $q | test("^(done|fi|esac)?(\\s*[0-9]*[<>]+&?\\s*[^\\s;&|]*)*\\s*(#.*)?$") then .
      else
        ($q | sub("^([A-Za-z_][A-Za-z0-9_]*=(\\S*|'[^']*'|\"[^\"]*\")\\s+|timeout\\s+\\S+\\s+|xargs(\\s+-\\S+)*\\s+)*"; "")
          | sub("^gh\\s+(-R|--repo)(=|\\s+)\\S+"; "gh")) as $q
        | (($q | capture("^(bash(\\s+-[A-Za-z]+)*\\s+)?[\"']?(?<p>[^\\s\"']*scripts/[a-z-]+[.]sh)\\b") | .p | resolve($d)) // null) as $r
        | (if $q | test("^(cat|sed|head|tail|grep|awk)\\s") then [$q | scan("[^\\s\"'=]*[.]md\\b") | resolve($d)] else [] end) as $m
        | .cmds += [{q: $q, reads: [$m[] | capture(file) | .skill + "/" + .rest]}]
        | if $r and ($r | test(skill + "/scripts/[a-z-]+[.]sh$")) then
            .run = [($r | capture(skill).skill), ($r | sub(".*/"; ""))]
          else .run = null | .read //= ([$m[] | capture(skill).skill] | first) end
      end);

input_filename as $f
| if .type == "system" and .subtype == "compact_boundary" then [$f, "compact"]
  elif .type == "attachment" then
    select(.attachment.hookEvent? // "" | test("^(SessionStart|SubagentStart)$"))
    | .attachment.stdout? // "" | strings | select(test("# Global instructions")) | given("rules.md"; .) as $n | [$f, "given", $n]
  elif .type == "user" and .isMeta == true then
    (.message.content | text) as $t
    | ($t | capture("^Base directory for this skill: [^\n]*" + skill + "\n")) | .skill as $s
    | [$f, "load", $s, ($t | length)], (traces($s + "/SKILL.md") as $n | [$f, "trace", $n]),
      (given($s + "/SKILL.md"; $t) as $n | [$f, "given", $n])
  elif .type == "assistant" then
    .timestamp as $t | .message.content[]? | select(.type == "tool_use") | .id as $id
    | if .name == "Read" then
        .input.file_path // "" | select(test("[.]md\\b"))
        | (capture(skill) | [$f, "read", $id, .skill]), (capture(file) | traces(.skill + "/" + .rest) as $n | [$f, "trace", $n])
      elif .name | test("^(Edit|Write|MultiEdit)$") then
        .input.file_path // "" | . as $p | moments($f; (.edit // empty) as $e | $p | test($e)) as $n | [$f, "moment", $n, $t]
      elif .name == "Skill" or .name == "Agent" then
        .input.skill // .input.subagent_type // "" | . as $c | moments($f; (.call // empty) as $e | $c | test($e)) as $n | [$f, "moment", $n, $t]
      elif .name == "Bash" then
        # A call has one output and one exit code, so a failure goes to the
        # script of its last command. ponytail: in a && b, the code is that of
        # a when a fails; 0 of 40 failed calls had a script before && on
        # 2026-11-09. The output is a read when a command reads, also when
        # another runs a script: in such calls the .md file is most of it.
        # A call that names no skills folder and no gh has no row; a variable
        # can hold the folder, as D=<cache>/skills; cat $D/github/x.md. Its
        # traces and moments come in the order of its commands.
        .input.command // "" | select(test("(^|[^-\\w])skills\\b|\\bgh\\b")) | commands
        | (.run // empty | [$f, "run", $id] + .), (.read // empty | [$f, "read", $id, .]),
          (.cmds[] | (.reads[] | traces(.) as $n | [$f, "trace", $n]),
            (.q as $q | moments($f; (.bash // empty) as $e | $q | test($e)) as $n | [$f, "moment", $n, $t]))
      else empty end
  elif .type == "user" then
    # An error with no exit code is a call that the harness, a hook or the
    # person stopped, or a Read that read nothing: it counts for no column.
    # The line with the exit code is no text of a file.
    .message.content | arrays | .[] | select(.type == "tool_result")
    | (.content | text) as $t | select(.is_error != true or ($t | startswith("Exit code")))
    | [$f, "result", .tool_use_id, ($t | sub("^Exit code [0-9]+\n?"; "") | length), (.is_error == true)]
  else empty end
| @tsv
