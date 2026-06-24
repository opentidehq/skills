# Installation guide

This repository ships **one** skill tree and **multiple harness manifests** at the repo root. Pick the method for your agent.

## Universal — `.agents/skills/`

Works across Cursor, Copilot, Codex, Kiro, Claude Code, Gemini CLI, and other [Agent Skills clients](https://agentskills.io/clients).

```bash
git clone https://github.com/OpenTideHQ/skills.git
cd skills
mkdir -p /path/to/project/.agents/skills
cp -r skills/* /path/to/project/.agents/skills/
cp AGENTS.md /path/to/project/
```

Or:

```bash
cd /path/to/project
npx skills add OpenTideHQ/skills
cp AGENTS.md .
```

## Cursor

**Plugin** (skills + rules):

```bash
git clone https://github.com/OpenTideHQ/skills.git
# Load repo root as a local plugin, or install from marketplace when published
```

Manifest: [`.cursor-plugin/plugin.json`](../.cursor-plugin/plugin.json) → `"skills": "./skills/"`

Marketplace: [`.cursor-plugin/marketplace.json`](../.cursor-plugin/marketplace.json)

## Claude Code

```text
/plugin marketplace add OpenTideHQ/skills
/plugin install opentide-detection-skills@opentide
```

Manifest: [`.claude-plugin/plugin.json`](../.claude-plugin/plugin.json)

Skills are namespaced: `/opentide-detection-skills:<skill-name>`

## GitHub Copilot (VS Code / CLI)

Uses the [OpenPlugin](https://code.visualstudio.com/docs/copilot/customization/agent-plugins) manifest at [`.plugin/plugin.json`](../.plugin/plugin.json).

Install via VS Code **Extensions → Agent Plugins** when the marketplace is registered, or point Copilot CLI at this repository.

## OpenAI Codex

Repo marketplace: [`.agents/plugins/marketplace.json`](../.agents/plugins/marketplace.json)

```text
/plugins
# Install opentide-detection-skills from the opentide marketplace
```

Manifest: [`.codex-plugin/plugin.json`](../.codex-plugin/plugin.json)

## Kiro

Kiro has two complementary mechanisms — both supported from this repo without duplicating skill content.

### Kiro Power (recommended)

A **Knowledge Base Power** activates on detection-engineering keywords and routes workflows via `steering/` files that point at canonical `skills/`.

1. Kiro IDE → **Powers** panel (👻⚡) → **Add Custom Power**
2. **Import power from GitHub** → `https://github.com/OpenTideHQ/skills`
3. Requires `POWER.md` at the repository root (included)

Docs: [Create powers](https://kiro.dev/docs/powers/create/) · [Install powers](https://kiro.dev/docs/powers/installation/)

### Kiro Agent Skills (à la carte)

Import individual skills from GitHub URLs:

`https://github.com/OpenTideHQ/skills/tree/main/skills/kusto-query-language`

Or copy into the project:

```bash
mkdir -p .kiro/skills
cp -r skills/* .kiro/skills/   # from cloned repo root
cp AGENTS.md .
```

Kiro also reads `AGENTS.md` from the workspace root.

## More harnesses

Tools without a native plugin manifest (Gemini CLI, Antigravity, OpenCode, Junie, Roo Code, Goose, Amp, and [40+ others](https://agentskills.io/clients)) use **Tier 2** install: `.agents/skills/` + `AGENTS.md`. See [docs/harnesses.md](harnesses.md).

## Why one tree?

Agent platforms copy plugins into a local cache on install. They cannot reliably reference files outside the plugin root (`../` paths are rejected). The standard pattern is:

1. **One canonical `skills/` directory** in git (this repo).
2. **Harness manifests** at the same root, each with `"skills": "./skills/"`.
3. **No per-harness copies** in the repository — platforms handle caching at install time.

See also: [Claude Code plugin caching](https://code.claude.com/docs/en/plugins-reference#plugin-caching-and-file-resolution), [Cursor plugins reference](https://cursor.com/docs/reference/plugins).
