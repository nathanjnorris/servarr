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
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SETTINGS = os.path.join(ROOT, ".claude", "settings.json")
GUARD = os.path.join(ROOT, ".claude", "hooks", "tfc-workspace-guard.sh")
RULE = re.compile(r"^([A-Za-z_][\w-]*)(?:\((.*)\))?$", re.S)
SHELL_SPLIT = re.compile(r"&&|\|\||\$\(|[;&|\n`()]")
SHELL_OPERATORS = re.compile(r"[;&|`<>\n\r]|\$\(")
SUBSTITUTION = re.compile(r"\$\(([^()]*)\)|`([^`]*)`")
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
PASS_THROUGH = {"exec", "command", "nohup", "time", "builtin"}
FLAG_ARGS = {"sudo": {"-u", "-g", "-C", "-h", "-p", "-D", "-r", "-t", "-U"},
             "xargs": {"-I", "-n", "-L", "-P", "-d", "-s", "-E", "-a"},
             "env": {"-u", "-C", "-S"},
             "npx": {"-p", "--package", "--cache", "--userconfig"},
             "bunx": {"-p", "--package"}}
# Package runners: "<runner> <sub> [flags] <tool>" runs <tool>, so "pnpm dlx renovate" is a renovate command.
RUNNER_SUBCOMMANDS = {"npm": {"exec", "x"}, "pnpm": {"dlx", "exec"}, "yarn": {"dlx", "exec"}}
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


def _strip_wrappers(words, depth):
    """Drop leading words that just run the rest (sudo, env, VAR=x, xargs, ...). A shell -c or eval string is parsed
    as its own command line. Returns (remaining words, nested commands)."""
    nested = []
    while words:
        w = os.path.basename(words[0])
        if w in SHELLS:
            i = 1
            while i < len(words) and words[i].startswith("-"):
                if "c" in words[i][1:] and i + 1 < len(words):
                    return [], nested + executed_commands(words[i + 1], depth + 1)
                i += 1
            words = words[i:]
        elif w == "eval":
            return [], nested + executed_commands(" ".join(words[1:]), depth + 1)
        elif w in ("npx", "bunx") and "-c" in words[1:2]:
            return [], nested + executed_commands(" ".join(words[2:]), depth + 1)
        elif w in RUNNER_SUBCOMMANDS and len(words) > 1 and words[1] in RUNNER_SUBCOMMANDS[w]:
            words = ["npx"] + words[2:]
        elif w == "--":
            words = words[1:]
        elif w in PASS_THROUGH:
            words = words[1:]
        elif w in FLAG_ARGS:
            i = 1
            while i < len(words) and (words[i].startswith("-") or (w == "env" and "=" in words[i])):
                i += 2 if words[i] in FLAG_ARGS[w] else 1
            words = words[i:]
        elif re.match(r"^[A-Za-z_]\w*=", words[0]):
            words = words[1:]
        else:
            break
    return words, nested


def executed_commands(command, depth=0):
    """Every simple command the shell would run, as space-joined words: quoted text stays one word (so a commit
    message mentioning "renovate" is not a renovate command), while sh -c / eval strings, $(...) and `...` are parsed
    too. Falls back to the quote-blind splitter if the line can't be tokenised."""
    if depth > 5:
        return []
    out = []
    for m in SUBSTITUTION.finditer(command):
        out += executed_commands(m.group(1) if m.group(1) is not None else m.group(2), depth + 1)
    try:
        lex = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
        lex.whitespace_split = True
        tokens = list(lex)
    except ValueError:
        return out + segments(re.sub(r"[\"'\\]", "", command))
    current = []
    for tok in tokens + [";"]:
        if tok and set(tok) <= set(";&|()"):
            words, nested = _strip_wrappers(current, depth)
            out += nested
            if words:
                # "/usr/local/bin/renovate" and "renovate@latest" are the renovate command too.
                head = re.sub(r"^((?:@[^/@]+/)?[^@]+)@.*$", r"\1", os.path.basename(words[0]))
                out.append(" ".join([head, *words[1:]]))
            current = []
        else:
            current.append(tok)
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
        candidates = [command, *executed_commands(command)]
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
