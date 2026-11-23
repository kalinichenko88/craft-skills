#!/usr/bin/env bash
# ZCode 4.0.0 has no SubagentStart, so no hook gives a subagent the rules
# (#465). On a call of its Agent tool, this hook puts a line first in the
# prompt that sends the subagent to read rules.md. Only ZCode sets
# ZCODE_PLUGIN_ROOT: in Claude Code and Codex the hook prints nothing. An
# Explore subagent only reads, so it gets no rules (PDR 0012). ADR 0012 says
# when to delete this hook.

[ -n "${ZCODE_PLUGIN_ROOT:-}" ] || exit 0
IFS= read -r -d '' input || true
[[ $input == *'"subagent_type":"Explore"'* ]] && exit 0
# ZCode gives one line of JSON that ends with the tool input between these
# two keys. JSON escapes each quote in a value, so no value holds a key.
# updatedInput replaces the whole input: a part that is not an object with a
# prompt gives no output, and the call runs as it is.
tool='"tool_input":' id=',"tool_use_id":' prompt='"prompt":"'
call=${input#*"$tool"}
call=${call%%"$id"*}
[[ $call == \{*"$prompt"*\} ]] || exit 0
line="Read $ZCODE_PLUGIN_ROOT/rules.md before you start: it holds the rules of this session."
line=${line//\\/\\\\}
line=${line//\"/\\\"}
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","updatedInput":%s%s%s\\n\\n%s}}\n' \
  "${call%%"$prompt"*}" "$prompt" "$line" "${call#*"$prompt"}"
