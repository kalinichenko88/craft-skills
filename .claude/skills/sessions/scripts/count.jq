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
# rules whose regex at $key, edit, call or bash, matches $s: a rule with main
# is no moment in a subagent.
def given($from; $text):
  $rules[0] | to_entries[] | .value as $r | select($r.from == $from and ($text | test($r.says))) | .key + 1;
def traces($file): $rules[0] | to_entries[] | select(.value.text == $file) | .key + 1;
def moments($f; $key; $s):
  $rules[0] | to_entries[]
  | select((.value[$key] // empty) as $e | ($s | test($e)) and (.value.main != true or ($f | test("/subagents/") | not)))
  | .key + 1;

# The commands of a Bash call, in the order they end, each with the sign
# that ends it, sep, which is = for the end of a $(...) that a variable
# takes, as x=$(...). It splits at ; & | and new lines, but not in quotes and
# not at the & of a redirection, as 2>&1. A command in $(...), <(...) or
# backquotes comes before the command around it, which runs after it. A
# heredoc body is no command.
def parts:
  gsub("<<-?[ \t]*['\"]?(?<w>[A-Za-z_]+)['\"]?(?<r>[^\n]*)\n[\\s\\S]*?\n[ \t]*\\k<w>(?=\n|$)"; "\(.r)")
  | [scan("'[^']*'|\"(?:\\\\.|[^\"\\\\$]|[$](?![(]))*\"|[0-9]*[<>]&[0-9-]*|[&]>{1,2}|[$<>][(]|[`;&|\n)]|[^'\"`;&|\n$<>)]+|[\\s\\S]")]
  | reduce .[] as $t ({out: [], stack: [{text: "", close: ""}]};
      if ($t | test("^[$<>][(]$")) or ($t == "`" and .stack[-1].close != "`") then
        .stack += [{text: "", close: (if $t == "`" then "`" else ")" end)}]
      elif $t == .stack[-1].close then
        .out += [{text: .stack[-1].text, sep: (if .stack[-2].text | test("[A-Za-z_][A-Za-z0-9_]*=[\"']?$") then "=" else $t end)}]
        | .stack |= .[:-1]
      elif $t | test("^[;&|\n]$") then .out += [{text: .stack[-1].text, sep: $t}] | .stack[-1].text = ""
      else .stack[-1].text += $t end)
  | .out + [.stack[] | {text, sep: ""}];
def subst($vars): reduce ($vars | to_entries[]) as $e (.; gsub("[$][{]?" + $e.key + "\\b[}]?"; $e.value));
def word: sub("^\\s+"; "") | sub("\\s+$"; "") | gsub("['\"]"; "");
def resolve($dir): sub("^[.]/"; "") | if test("^[/~$]") or $dir == "" then . else $dir + "/" + . end;

# The script of a skill that the last command of the call runs, with bash and
# its options or by its path, as [skill, script]; and the skill of the first
# command that names a .md file of a skill with cat, sed, head, tail, grep or
# awk. An assignment, a cd, an empty command, a comment, and done, fi or esac
# with their redirections are no last command. A
# variable takes its value from an assignment before it in the call, and a
# relative path takes the folder of a cd before it. Then each command, in
# cmds, and the .md files of skills that a command shows whole or in part, in
# reads: not sed -i, not a grep that counts or lists, not an awk with actions
# that print no line or field of the file and no pattern after them, and not
# a command with a > outside its quotes that does not follow a digit or &, as
# 2> does. A pipeline shows the output of its last command, so its reads
# count only when that command is no count, as wc, head -0 or a jq length,
# and sends no output to a file; and not in a $(...) whose output a variable
# takes. A gh -R <repo> before its command, as pr or
# issue, is gh, and a gh api --hostname <host> is gh api.
# ponytail: a variable that $(...) sets stays empty, so f=$(ls <skill>/x.md);
# cat "$f" is no read: 4 of 2,645 calls on 2026-11-09. Resolve it when it
# grows.
def commands:
  reduce parts[] as $p ({vars: {}, dir: "", run: null, read: null, cmds: [], reads: [], pipe: [], drop: false};
    .vars as $v | .dir as $d
    | ($p.text | subst($v) | sub("^([\\s(){}!]|(do|then|else|time|if|while|until|export)\\s)*"; "")) as $q
    | if $q | test("^[A-Za-z_][A-Za-z0-9_]*=\\S*\\s*$") then
        .vars[$q | capture("^(?<k>[^=]+)").k] = ($q | sub("^[^=]+="; "") | word)
      elif $q | test("^cd\\s") then .dir = ($q | sub("^cd\\s+"; "") | word | resolve($d))
      elif $q | test("^(done|fi|esac)?(\\s*[0-9]*[<>]+&?\\s*[^\\s;&|]*)*\\s*(#.*)?$") then .
      else
        ($q | sub("^([A-Za-z_][A-Za-z0-9_]*=(\\S*|'[^']*'|\"[^\"]*\")\\s+|timeout\\s+\\S+\\s+|xargs(\\s+-\\S+)*\\s+)*"; "")
          | sub("^gh\\s+(-R|--repo)(=|\\s+)\\S+"; "gh") | sub("^gh\\s+api\\s+--hostname(=|\\s+)\\S+"; "gh api")) as $q
        | (($q | capture("^(bash(\\s+-[A-Za-z]+)*\\s+)?[\"']?(?<p>[^\\s\"']*scripts/[a-z-]+[.]sh)\\b") | .p | resolve($d)) // null) as $r
        | (if $q | test("^(cat|sed|head|tail|grep|awk)\\s") then [$q | scan("[^\\s\"'=]*[.]md\\b") | resolve($d)] else [] end) as $m
        | ($q | gsub("'[^']*'|\"[^\"]*\""; "")) as $bare
        | (($bare | test("(^|[^0-9&])>")) or (($q | test("^sed\\s")) and ($bare | test("\\s(-[A-Za-z]*i|--in-place)\\b")))) as $writes
        | ($q | test("^awk\\s") and (gsub("\\s-(F|v)\\s*('[^']*'|\"[^\"]*\"|\\S+)"; "") | [scan("'[^']*'|\"[^\"]*\"")] | first // ""
            | test("[{]") and (test("}\\s*[^}\\s'\"]+\\s*['\"]$") | not) and (test("print(f)?\\s*($|[;}(]|[^;}]*[$])") | not))) as $blind
        | ($q | test("^grep\\s(.*\\s)?-[A-Za-z]*[clLq]")) as $counts
        | .cmds += [$q]
        | .pipe += (if $writes or $blind or $counts then [] else [$m[] | capture(file) | .skill + "/" + .rest] end)
        | .drop = ($writes or $counts or ($q | test("^(wc|cksum|md5|md5sum|sha[0-9]*sum|shasum)\\b|^head\\s+(-n\\s*)?-?0\\b|^jq\\s.*\\blength['\"]?(\\s+[0-9]*>\\S*)*\\s*$")))
        | if $r and ($r | test(skill + "/scripts/[a-z-]+[.]sh$")) then
            .run = [($r | capture(skill).skill), ($r | sub(".*/"; ""))]
          else .run = null | .read //= ([$m[] | capture(skill).skill] | first) end
      end
    | if $p.sep == "|" then .
      else (if .drop or $p.sep == "=" then . else .reads += .pipe end) | .pipe = [] | .drop = false end);

input_filename as $f
| if .type == "system" and .subtype == "compact_boundary" then [$f, "compact"]
  elif .type == "attachment" then
    select(.attachment.hookEvent? // "" | test("^(SessionStart|SubagentStart)$"))
    | .attachment.stdout? // "" | strings | select(test("# Global instructions")) | given("rules.md"; .) as $n | [$f, "given", $n]
  elif .type == "user" and .isMeta == true then
    # A load names the Skill call that made it, so its trace takes that
    # call's message. A load that the person typed has none.
    (.sourceToolUseID // "") as $src | (.message.content | text) as $t
    | ($t | capture("^Base directory for this skill: [^\n]*" + skill + "\n")) | .skill as $s
    | [$f, "load", $s, ($t | length)], (traces($s + "/SKILL.md") as $n | [$f, "trace", $n, "", $src]),
      (given($s + "/SKILL.md"; $t) as $n | [$f, "given", $n])
  elif .type == "assistant" then
    # The model writes every call of a message before it reads a result, so
    # a trace and a moment carry the message.
    .timestamp as $t | (.message.id // .uuid // "") as $msg
    | .message.content[]? | select(.type == "tool_use") | .id as $id
    | if .name == "Read" then
        .input.file_path // "" | select(test("[.]md\\b"))
        | (capture(skill) | [$f, "read", $id, .skill]), (capture(file) | traces(.skill + "/" + .rest) as $n | [$f, "trace", $n, $id, $msg])
      elif .name | test("^(Edit|Write|MultiEdit)$") then
        .input.file_path // "" | moments($f; "edit"; .) as $n | [$f, "moment", $n, $t, $msg]
      elif .name == "Skill" or .name == "Agent" then
        (select(.name == "Skill") | [$f, "skill", $id, $msg]),
        # A round or the security review of the review loop is an Agent call
        # whose prompt starts with the path of its lens file: the call takes
        # the name of that file.
        (.input.skill // (.input.prompt // "" | capture("^Read [^\n]*/(?<lens>(code|security)-lens[.]md) ").lens) // .input.subagent_type // ""
          | moments($f; "call"; .) as $n | [$f, "moment", $n, $t, $msg])
      elif .name == "Bash" then
        # A call has one output and one exit code, so a failure goes to the
        # script of its last command. ponytail: in a && b, the code is that of
        # a when a fails; 0 of 40 failed calls had a script before && on
        # 2026-11-09. The output is a read when a command reads, also when
        # another runs a script: in such calls the .md file is most of it.
        # A call that names no skills folder and no gh has no row; a variable
        # can hold the folder, as D=<cache>/skills; cat $D/github/x.md. A trace
        # of a Read or a Bash call names its call: its text reaches the context
        # with the result.
        .input.command // "" | select(test("(^|[^-\\w])skills\\b|\\bgh\\b")) | commands
        | (.run // empty | [$f, "run", $id] + .), (.read // empty | [$f, "read", $id, .]),
          (.reads[] | traces(.) as $n | [$f, "trace", $n, $id, $msg]),
          (.cmds[] | moments($f; "bash"; .) as $n | [$f, "moment", $n, $t, $msg])
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
