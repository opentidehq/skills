#!/usr/bin/env bash
# Validate Agent Skills frontmatter against agentskills.io conventions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT}/skills"
errors=0

name_pattern='^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'

while IFS= read -r skill_md; do
  skill_dir="$(dirname "${skill_md}")"
  dir_name="$(basename "${skill_dir}")"

  if ! head -n 1 "${skill_md}" | grep -q '^---$'; then
    echo "ERROR: missing frontmatter in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  name="$(awk '/^---$/{if(++n==2) exit} n==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "${skill_md}")"
  description="$(awk '/^---$/{if(++n==2) exit} n==1 && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "${skill_md}")"

  if [[ -z "${name}" ]]; then
    echo "ERROR: missing name in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  if [[ -z "${description}" ]]; then
    echo "ERROR: missing description in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  if [[ "${name}" != "${dir_name}" ]]; then
    echo "ERROR: name '${name}' does not match directory '${dir_name}' (${skill_md})"
    errors=$((errors + 1))
  fi

  if [[ ! "${name}" =~ ${name_pattern} ]]; then
    echo "ERROR: invalid name '${name}' in ${skill_md}"
    errors=$((errors + 1))
  fi

  if [[ ${#name} -gt 64 ]]; then
    echo "ERROR: name too long in ${skill_md}"
    errors=$((errors + 1))
  fi

  if [[ ${#description} -gt 1024 ]]; then
    echo "ERROR: description too long in ${skill_md}"
    errors=$((errors + 1))
  fi
done < <(find "${SKILLS_DIR}" -name SKILL.md | sort)

if [[ "${errors}" -gt 0 ]]; then
  echo "validation failed with ${errors} error(s)"
  exit 1
fi

skill_count="$(find "${SKILLS_DIR}" -name SKILL.md | wc -l | tr -d ' ')"
echo "validated ${skill_count} skills"

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
