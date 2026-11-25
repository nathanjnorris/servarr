import json
import os
import subprocess
import sys
import unittest

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "permission-policy.py")
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def decide(event):
    raw = event if isinstance(event, str) else json.dumps(event)
    r = subprocess.run([sys.executable, HOOK], input=raw, capture_output=True, text=True, timeout=20)
    assert r.returncode == 0, r.stderr
    return json.loads(r.stdout).get("permissionDecision")


def bash(cmd):
    return decide({"tool_name": "Bash", "tool_input": {"command": cmd}})


class Bash(unittest.TestCase):
    def test_allowed_read_only(self):
        self.assertEqual(bash("git status --short"), "allow")
        self.assertEqual(bash("bash .claude/skills/servarr-doctor/scripts/doctor.sh --quick"), "allow")

    def test_compound_gets_no_auto_allow(self):
        self.assertIsNone(bash("git status; rm -rf x"))
        self.assertIsNone(bash("gh pr view 1 | jq ."))

    def test_denied(self):
        for cmd in ["git add -A", "cd x && git add -A", "git push origin x --force-with-lease",
                    "git push -f origin x", "git push origin +main", "npx renovate --dry-run",
                    "sudo tailscale up --ssh"]:
            self.assertEqual(bash(cmd), "deny", cmd)

    def test_not_denied(self):
        self.assertIsNone(bash("git add README.md"))
        self.assertIsNone(bash("git push -u origin feat/x"))

    def test_shell_wrappers_denied(self):
        for cmd in ["bash -c 'git add -A'", 'sh -c "git add -A"', "zsh -lc 'git add -A'", "eval 'git add -A'",
                    "env FOO=1 git add -A", "sudo -A git add -A", "command git add -A", "nohup git add -A",
                    "bash -c 'cd x && git add -A'", "xargs git add -A </dev/null", "git add '-A'",
                    "time bash -c \"tailscale up\""]:
            self.assertEqual(bash(cmd), "deny", cmd)

    def test_package_runners_denied(self):
        for cmd in ["npx --yes renovate --dry-run", "npx -y renovate@latest", "npx -p renovate renovate",
                    "npm exec -- renovate", "npm x renovate", "pnpm dlx renovate", "pnpm exec renovate",
                    "yarn dlx renovate", "bunx renovate", "/usr/local/bin/renovate --dry-run",
                    "./node_modules/.bin/renovate", "env -i npx --yes renovate"]:
            self.assertEqual(bash(cmd), "deny", cmd)

    def test_other_npx_tools_not_denied(self):
        self.assertIsNone(bash("npx --yes prettier --check ."))

    def test_camel_case_string_args(self):
        self.assertEqual(decide({"toolName": "Bash", "toolArgs": "{\"command\":\"git log --oneline -3\"}"}), "allow")

    def test_quoted_text_is_not_a_command(self):
        self.assertIsNone(bash('git commit -q -m "build(renovate): track pins"'))
        self.assertIsNone(bash("gh pr create --title 'fix: (renovate) x' --body 'npx renovate is banned'"))

    def test_command_substitution_denied(self):
        for cmd in ['echo "$(git add -A)"', "echo `git add -A`", 'bash -c "echo hi; git add -A"',
                    "git commit -m \"$(npx renovate --dry-run)\""]:
            self.assertEqual(bash(cmd), "deny", cmd)


class Paths(unittest.TestCase):
    def test_env_reads_denied(self):
        self.assertEqual(decide({"tool_name": "Read", "tool_input": {"path": os.path.join(ROOT, ".env")}}), "deny")
        self.assertEqual(decide({"tool_name": "Read", "tool_input": {"path": ".env.prod"}}), "deny")
        self.assertEqual(decide({"tool_name": "Grep", "tool_input": {"pattern": "x", "paths": [".env"]}}), "deny")

    def test_glob_pattern_denied(self):
        self.assertEqual(decide({"tool_name": "Glob", "tool_input": {"pattern": "./.env.*"}}), "deny")
        self.assertEqual(decide({"tool_name": "Glob", "tool_input": {"pattern": ".env"}}), "deny")

    def test_grep_regex_pattern_is_not_a_path(self):
        self.assertIsNone(decide({"tool_name": "Grep", "tool_input": {"pattern": ".env", "paths": ["README.md"]}}))

    def test_readme_not_denied(self):
        self.assertIsNone(decide({"tool_name": "Read", "tool_input": {"path": os.path.join(ROOT, "README.md")}}))


class ToolAliases(unittest.TestCase):
    def test_shell_aliases(self):
        for name in ["bash", "execute", "shell", "powershell", "Execute"]:
            self.assertEqual(decide({"tool_name": name, "tool_input": {"command": "git add -A"}}), "deny", name)

    def test_read_aliases(self):
        for name in ["view", "read", "Read"]:
            self.assertEqual(decide({"tool_name": name, "tool_input": {"path": ".env"}}), "deny", name)
        for name in ["rg", "grep", "search"]:
            self.assertEqual(decide({"tool_name": name, "tool_input": {"pattern": "x", "paths": [".env"]}}), "deny",
                             name)
        self.assertEqual(decide({"tool_name": "glob", "tool_input": {"pattern": ".env*"}}), "deny")

    def test_camel_case_runtime_name(self):
        self.assertEqual(decide({"toolName": "bash", "toolArgs": {"command": "git add -A"}}), "deny")


class Mcp(unittest.TestCase):
    def test_renovate(self):
        self.assertEqual(decide({"tool_name": "renovate-validate_config", "tool_input": {}}), "allow")
        self.assertIsNone(decide({"tool_name": "renovate-write_config", "tool_input": {}}))

    def test_terraform(self):
        ws = {"terraform_org_name": "nathanjnorris-org", "workspace_name": "servarr"}
        self.assertEqual(decide({"tool_name": "terraform-search_providers", "tool_input": {}}), "allow")
        self.assertEqual(decide({"tool_name": "terraform-create_run", "tool_input": ws}), "deny")
        self.assertIsNone(decide({"tool_name": "terraform-update_workspace", "tool_input": ws}))
        self.assertEqual(decide({"tool_name": "terraform-update_workspace",
                                 "tool_input": {**ws, "workspace_name": "tfc-agent"}}), "deny")
        self.assertEqual(decide({"tool_name": "terraform-update_workspace", "tool_input": {**ws, "new_name": "x"}}),
                         "deny")
        self.assertEqual(decide({"tool_name": "mcp__plugin_terraform_terraform__create_workspace",
                                 "tool_input": {"terraform_org_name": "evil"}}), "deny")


class Errors(unittest.TestCase):
    def test_malformed_input_fails_closed(self):
        self.assertEqual(decide('{"tool_name":"terraform-update_workspace",'), "deny")
        self.assertEqual(decide('{"tool_name":"Bash",'), "deny")


if __name__ == "__main__":
    unittest.main()
