#!/usr/bin/env bash
# Validate Agent Skills frontmatter against agentskills.io conventions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT}/skills"

# Frontmatter is parsed as real YAML, not scraped with a regex. A description
# containing an unquoted ": " is valid to a line-oriented reader and invalid
# YAML, so `gh skill publish` and downstream marketplace linters reject a skill
# this script used to pass. Prefer an interpreter that has PyYAML.
PY_BIN="python3"
for candidate in python3.12 python3.13 python3.11 python3; do
  if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" -c 'import yaml' 2>/dev/null; then
    PY_BIN="${candidate}"
    break
  fi
done

"${PY_BIN}" - "${SKILLS_DIR}" <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - depends on the host interpreter
    yaml = None

NAME_RE = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")
FM_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
# A top-level `key: value` whose value is unquoted and itself contains ": ".
HAZARD_RE = re.compile(r"^[A-Za-z0-9_-]+:[ \t]+(?![\"'|>])(?P<v>.*: .*)$")

skills_dir = Path(sys.argv[1])
errors = []

paths = sorted(skills_dir.glob("*/SKILL.md"))
for path in paths:
    where = path.relative_to(skills_dir.parent)
    text = path.read_text(encoding="utf-8")

    match = FM_RE.match(text)
    if not match:
        errors.append(f"{where}: missing or malformed frontmatter block")
        continue
    block = match.group(1)

    if yaml is not None:
        try:
            data = yaml.safe_load(block)
        except yaml.YAMLError as exc:
            errors.append(f"{where}: frontmatter is not valid YAML: {str(exc).splitlines()[0]}")
            continue
        if not isinstance(data, dict):
            errors.append(f"{where}: frontmatter parsed as {type(data).__name__}, expected a mapping")
            continue
    else:
        # No PyYAML: still catch the failure mode a regex reader misses.
        for line in block.splitlines():
            if HAZARD_RE.match(line):
                errors.append(
                    f"{where}: frontmatter value contains an unquoted ': ' and will "
                    f"fail a YAML parse — quote the value"
                )
                break
        data = {}
        for line in block.splitlines():
            if ":" in line and not line.startswith((" ", "\t", "#")):
                k, _, v = line.partition(":")
                data[k.strip()] = v.strip()

    name = data.get("name")
    description = data.get("description")

    if not name:
        errors.append(f"{where}: missing name")
    elif not isinstance(name, str):
        errors.append(f"{where}: name must be a string, got {type(name).__name__}")
    else:
        if name != path.parent.name:
            errors.append(f"{where}: name '{name}' does not match directory '{path.parent.name}'")
        if not NAME_RE.match(name):
            errors.append(f"{where}: invalid name '{name}'")
        if len(name) > 64:
            errors.append(f"{where}: name too long ({len(name)} > 64)")

    if not description:
        errors.append(f"{where}: missing description")
    elif not isinstance(description, str):
        errors.append(f"{where}: description must be a string, got {type(description).__name__}")
    elif len(description) > 1024:
        errors.append(f"{where}: description too long ({len(description)} > 1024)")

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    print(f"validation failed with {len(errors)} error(s)")
    sys.exit(1)

if yaml is None:
    print("WARNING: PyYAML unavailable — frontmatter checked structurally, not parsed")
print(f"validated {len(paths)} skills")
PY

python3 - "${ROOT}" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = 0

plugin_schema = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
mcp_schema = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"
name_re = re.compile(r"^(?!.*(?:--|\\.\\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$")
plugin_keys = {
    "$schema",
    "name",
    "version",
    "description",
    "author",
    "homepage",
    "repository",
    "license",
    "keywords",
    "extensions",
}
author_keys = {"name", "email", "url"}

def fail(message: str) -> None:
    global errors
    print(f"ERROR: {message}")
    errors += 1

def load(path: Path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"{path.name} is not valid JSON ({exc})")
        return None

plugin = load(root / "plugin.json")
mcp = load(root / "mcp.json")

if isinstance(plugin, dict):
    unknown = sorted(set(plugin) - plugin_keys)
    if unknown:
        fail("plugin.json has unknown fields: " + ", ".join(unknown))
    if plugin.get("$schema") != plugin_schema:
        fail("plugin.json $schema must be the Agent Plugins 1.0.0 identifier")
    name = plugin.get("name")
    if not isinstance(name, str) or not name_re.fullmatch(name) or not 1 <= len(name) <= 64:
        fail(f"plugin.json name {name!r} is not a valid Agent Plugins name")
    author = plugin.get("author")
    if author is not None:
        if not isinstance(author, dict) or set(author) - author_keys:
            fail("plugin.json author may only contain name, email, and url")
        elif any(not isinstance(value, str) for value in author.values()):
            fail("plugin.json author values must be strings")
    keywords = plugin.get("keywords")
    if keywords is not None and (
        not isinstance(keywords, list) or any(not isinstance(item, str) for item in keywords)
    ):
        fail("plugin.json keywords must be an array of strings")
else:
    fail("plugin.json must be a JSON object")

if isinstance(mcp, dict):
    if set(mcp) != {"$schema", "mcpServers"}:
        fail("mcp.json may only contain $schema and mcpServers")
    if mcp.get("$schema") != mcp_schema:
        fail("mcp.json $schema must be the Agent Plugins 1.0.0 MCP identifier")
    servers = mcp.get("mcpServers")
    if not isinstance(servers, dict) or "opentide" not in servers:
        fail("mcp.json must define the opentide server")
    else:
        server = servers["opentide"]
        if not isinstance(server, dict):
            fail("mcp.json opentide entry must be an object")
        elif (
            server.get("type") != "stdio"
            or server.get("command") != "opentide"
            or server.get("args") != ["mcp", "start"]
        ):
            fail(
                'mcp.json opentide server must be stdio command opentide '
                'with args ["mcp", "start"]'
            )
        elif set(server) - {"type", "command", "args", "env", "cwd"}:
            fail("mcp.json opentide server has unknown fields")
else:
    fail("mcp.json must be a JSON object")

claude_plugin = load(root / ".claude-plugin" / "plugin.json")
if isinstance(claude_plugin, dict) and claude_plugin.get("mcpServers") != "./mcp.json":
    fail(".claude-plugin/plugin.json must set mcpServers to ./mcp.json so Claude Code loads the Agent Plugins MCP entry")

cursor_market = load(root / ".cursor-plugin" / "marketplace.json")
cursor_plugin_keys = {"name", "source", "description", "minClientVersions"}
if isinstance(cursor_market, dict):
    owner = cursor_market.get("owner")
    if not isinstance(owner, dict) or not isinstance(owner.get("name"), str) or not owner["name"].strip():
        fail(".cursor-plugin/marketplace.json requires owner.name")
    elif set(owner) - {"name", "email"}:
        fail(".cursor-plugin/marketplace.json owner may only contain name and email")
    entries = cursor_market.get("plugins")
    if not isinstance(entries, list) or not entries:
        fail(".cursor-plugin/marketplace.json plugins must be a non-empty array")
    else:
        names = []
        for entry in entries:
            if not isinstance(entry, dict):
                fail(".cursor-plugin/marketplace.json plugin entry must be an object")
                continue
            extra = sorted(set(entry) - cursor_plugin_keys)
            if extra:
                fail(
                    ".cursor-plugin/marketplace.json plugin entry has fields the Cursor schema rejects: "
                    + ", ".join(extra)
                )
            if isinstance(entry.get("name"), str):
                names.append(entry["name"])
        plugin_name = plugin.get("name") if isinstance(plugin, dict) else None
        if plugin_name and plugin_name not in names:
            fail(".cursor-plugin/marketplace.json must list " + str(plugin_name))
else:
    fail(".cursor-plugin/marketplace.json must be a JSON object")

skills_schema = "https://skills.sh/schemas/skills.sh.schema.json"
skills_config = load(root / "skills.sh.json")
if isinstance(skills_config, dict):
    if skills_config.get("$schema") != skills_schema:
        fail("skills.sh.json $schema must be the skills.sh repository page identifier")
    skill_names = {path.parent.name for path in (root / "skills").glob("*/SKILL.md")}
    groupings = skills_config.get("groupings")
    seen = []
    if not isinstance(groupings, list) or not groupings:
        fail("skills.sh.json groupings must be a non-empty array")
    else:
        for group in groupings:
            title = group.get("title") if isinstance(group, dict) else None
            names = group.get("skills") if isinstance(group, dict) else None
            if not isinstance(title, str) or not title.strip():
                fail("skills.sh.json group is missing a title")
                continue
            if not isinstance(names, list) or not names:
                fail(f"skills.sh.json group '{title}' has no skills")
                continue
            for name in names:
                if name not in skill_names:
                    fail(f"skills.sh.json lists unknown skill '{name}' in '{title}'")
                elif name in seen:
                    fail(f"skills.sh.json lists '{name}' more than once")
                else:
                    seen.append(name)
        missing = sorted(skill_names - set(seen))
        if missing:
            fail("skills missing from skills.sh.json: " + ", ".join(missing))
else:
    fail("skills.sh.json must be a JSON object")

if errors:
    sys.exit(1)

print("validated plugin.json and mcp.json")
print(f"validated skills.sh.json ({len(seen)} skills)")
PY

"${ROOT}/scripts/build-manifest.sh" --check
