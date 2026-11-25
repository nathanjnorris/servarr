#!/usr/bin/env python3
"""GitHub Copilot PreToolUse hook: applies the permission rules in .claude/settings.json to Copilot sessions.

Copilot has no repository-level allow/deny list, so the rules Claude Code enforces natively are enforced here, from the
same file (single source of truth):
  - deny rules always win: Bash(...) command rules, Read(...) path rules (also applied to Grep/Glob), mcp__... rules;
  - Terraform MCP calls (Copilot names them terraform-<tool>) then go through .claude/hooks/tfc-workspace-guard.sh;
  - allow rules auto-approve a call, but a shell command only when it has no shell operators (no chaining, pipes,
    substitution or redirection), so an approved prefix can't smuggle a second command in.
Anything else gets no decision and falls through to Copilot's normal permission flow.

Registered as the PascalCase "PreToolUse" event in .github/hooks/servarr.json, so the input uses Claude-style field
and tool names (tool_name "Bash"/"Read"/..., tool_input). MCP tools keep Copilot's <server>-<tool> runtime name.
Errors (malformed input, unreadable settings, a crash) deny the call: the hook fails closed, like Claude Code.
"""
import fnmatch
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SETTINGS = os.path.join(ROOT, ".claude", "settings.json")
GUARD = os.path.join(ROOT, ".claude", "hooks", "tfc-workspace-guard.sh")
RULE = re.compile(r"^([A-Za-z_][\w-]*)(?:\((.*)\))?$", re.S)
SHELL_SPLIT = re.compile(r"&&|\|\||\$\(|[;&|\n`()]")
SHELL_OPERATORS = re.compile(r"[;&|`<>\n\r]|\$\(")
# Leading words that run the rest of the segment as a command: "bash -c 'git add -A'" must still hit the deny rules.
WRAPPER = re.compile(r"^(?:(?:ba|z|da|k)?sh\s+(?:-\w+\s+)*|eval\s+|exec\s+|command\s+|nohup\s+|time\s+"
                     r"|xargs\s+(?:-\S+\s+)*|sudo\s+(?:-\S+\s+)*|env\s+(?:-\S+\s+)*|\w+=\S*\s+)")
READ_LIKE = ("Read", "Grep", "Glob")


def emit(decision=None, reason=""):
    print(json.dumps({"permissionDecision": decision, "permissionDecisionReason": reason} if decision else {}))
    sys.exit(0)


def mcp_runtime_name(rule):
    """mcp__<server>__<tool> or mcp__plugin_<plugin>_<server>__<tool> -> Copilot's <server>-<tool>."""
    m = re.match(r"^mcp__(.+?)__(.+)$", rule)
    if not m:
        return None
    server, tool = m.groups()
    if server.startswith("plugin_"):
        server = server.rsplit("_", 1)[-1]
    return f"{server}-{tool}"


def bash_matches(pattern, command):
    command = command.strip()
    if pattern.endswith(":*"):
        prefix = pattern[:-2]
        return command == prefix or command.startswith(prefix + " ")
    if "*" in pattern:
        return re.fullmatch(".*".join(re.escape(p) for p in pattern.split("*")), command, re.S) is not None
    return command == pattern


def segments(command):
    return [s.strip() for s in SHELL_SPLIT.split(command) if s.strip()]


def unwrapped_segments(command):
    """Segments with quotes removed and wrapper words (bash -c, eval, sudo, env, ...) stripped from the front."""
    out = []
    for seg in segments(re.sub(r"[\"'\\]", "", command)):
        while (m := WRAPPER.match(seg)) and m.end() < len(seg):
            seg = seg[m.end():].lstrip()
        out.append(seg)
    return out


def path_matches(pattern, path, glob=False):
    rel = os.path.relpath(os.path.realpath(os.path.join(ROOT, path)), os.path.realpath(ROOT))
    pattern = pattern[2:] if pattern.startswith("./") else pattern
    # A Glob pattern is itself a wildcard: it is denied if it could match a denied path, e.g. ".env*" vs ".env".
    return fnmatch.fnmatchcase(rel, pattern) or (glob and fnmatch.fnmatchcase(pattern, rel))


def tool_paths(tool, args):
    paths = [args.get("file_path"), args.get("path")]
    extra = args.get("paths")
    paths += extra if isinstance(extra, list) else [extra]
    if tool == "Glob":
        paths.append(args.get("pattern"))
    return [p for p in paths if isinstance(p, str) and p]


def denied(rule, tool, args):
    m = RULE.match(rule)
    if not m:
        return False
    kind, content = m.groups()
    if kind.startswith("mcp__"):
        return tool in (kind, mcp_runtime_name(kind))
    if kind == "Read" and tool in READ_LIKE:
        return content is None or any(path_matches(content, p, tool == "Glob") for p in tool_paths(tool, args))
    if kind != tool:
        return False
    if content is None:
        return True
    if tool == "Bash":
        command = str(args.get("command", ""))
        candidates = [command, *segments(command), *unwrapped_segments(command)]
        return any(bash_matches(content, c) for c in candidates)
    if tool in READ_LIKE:
        return any(path_matches(content, p, tool == "Glob") for p in tool_paths(tool, args))
    return False


def allowed(rule, tool, args):
    m = RULE.match(rule)
    if not m:
        return False
    kind, content = m.groups()
    if kind.startswith("mcp__"):
        return tool in (kind, mcp_runtime_name(kind))
    if kind != tool or content is None:
        return False
    if tool == "Bash":
        command = str(args.get("command", ""))
        return not SHELL_OPERATORS.search(command) and bash_matches(content, command)
    if tool in READ_LIKE:
        paths = tool_paths(tool, args)
        return bool(paths) and all(path_matches(content, p) for p in paths)
    return False


def main(raw):
    event = json.loads(raw)
    tool = event.get("tool_name") or event.get("toolName") or ""
    args = event.get("tool_input", event.get("toolArgs")) or {}
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except ValueError:
            args = {"command": args}
    if not isinstance(args, dict):
        args = {}
    with open(SETTINGS) as f:
        perms = json.load(f).get("permissions", {})

    for rule in perms.get("deny", []):
        if denied(rule, tool, args):
            emit("deny", f"Denied by the .claude/settings.json rule {rule} (CLAUDE.md hard rules).")

    if tool.startswith("terraform-"):
        payload = json.dumps({"tool_name": tool, "tool_input": args})
        r = subprocess.run(["bash", GUARD], input=payload, capture_output=True, text=True, timeout=8, check=False)
        if r.returncode != 0:
            emit("deny", r.stderr.strip() or "tfc-workspace-guard blocked this call")

    for rule in perms.get("allow", []):
        if allowed(rule, tool, args):
            emit("allow", f"Allowed by the .claude/settings.json rule {rule}.")
    emit()


if __name__ == "__main__":
    raw = sys.stdin.read()
    try:
        main(raw)
    except Exception as e:  # noqa: BLE001 - any failure denies, like Claude Code's own deny rules would
        print(f"permission-policy: {type(e).__name__}: {e}", file=sys.stderr)
        emit("deny", f"permission-policy hook error ({type(e).__name__}); failing closed. Fix .github/hooks or "
                     ".claude/settings.json before continuing.")
