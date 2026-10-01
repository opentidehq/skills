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

`npx skills add` is also the listing path for the [skills.sh leaderboard](https://skills.sh/OpenTideHQ/skills). The repository page groups come from [`skills.sh.json`](../skills.sh.json) on the default branch, refreshed when the CLI installs from this repo.

GitHub skill search (`gh skill search`) uses the repository topic `agent-skills`. Add that topic, or run `gh skill publish`, so this repository is included there as well.

## Agent Plugins

Root [`plugin.json`](../plugin.json) and [`mcp.json`](../mcp.json) follow [Agent Plugins 1.0.0](https://agent-plugins.org/specification). Clients discover skills from `skills/` and MCP servers only from `mcp.json`. The OpenTide server is:

```json
{
  "type": "stdio",
  "command": "opentide-mcp"
}
```

Install the server with `pip install 'opentide[mcp]'` so `opentide-mcp` is on `PATH`. When the client starts that process in this skills repository, point it at the detection content repository using the [OpenTide MCP configuration](https://github.com/OpenTideHQ/opentide/blob/development/docs/mcp/configuration.md).

Claude Code reads MCP servers from the harness manifest. [`.claude-plugin/plugin.json`](../.claude-plugin/plugin.json) sets `"mcpServers": "./mcp.json"` so it uses the same Agent Plugins entry. VS Code 1.140 selects the root `plugin.json` when `$schema` is the Agent Plugins 1.0.0 identifier, then loads `skills/` and `mcp.json`.

## Cursor

In Cursor chat:

```text
/add-plugin OpenTideHQ/skills
```

Manifest: [`.cursor-plugin/plugin.json`](../.cursor-plugin/plugin.json) → `"skills": "./skills/"`

Marketplace: [`.cursor-plugin/marketplace.json`](../.cursor-plugin/marketplace.json)

The public Cursor Marketplace listing is a separate submission at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish).

## Claude Code

```text
/plugin marketplace add OpenTideHQ/skills
/plugin install opentide-detection-skills@opentide
```

Manifest: [`.claude-plugin/plugin.json`](../.claude-plugin/plugin.json)

Skills are namespaced: `/opentide-detection-skills:<skill-name>`

Check the package with `claude plugin validate .` before a community catalogue submission at [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit).

## GitHub Copilot (VS Code / CLI)

**VS Code** — Command Palette → **Chat: Install Plugin From Source** → `OpenTideHQ/skills`. Enable `chat.plugins.enabled`.

**Copilot CLI:**

```bash
copilot plugin marketplace add OpenTideHQ/skills
copilot plugin install opentide-detection-skills@opentide
```

The legacy manifest is [`.plugin/plugin.json`](../.plugin/plugin.json). Copilot CLI reads the marketplace at [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json). A listing in the default Awesome Copilot marketplace is a pull request to [github/awesome-copilot](https://github.com/github/awesome-copilot).

## OpenAI Codex

Open this repository in Codex CLI, then:

```text
/plugins
```

Install **opentide-detection-skills** from the **opentide** marketplace.

Repo marketplace: [`.agents/plugins/marketplace.json`](../.agents/plugins/marketplace.json)

Manifest: [`.codex-plugin/plugin.json`](../.codex-plugin/plugin.json)

The shared ChatGPT and Codex public directory uses the submission flow in the [Codex plugins documentation](https://developers.openai.com/codex/plugins).

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
