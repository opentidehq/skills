# OpenTide Skills

Canonical home for reusable [Agent Skills](https://agentskills.io/specification) for detection engineering — **27 skills**, one source tree, multi-harness plugin manifests. The machine-readable catalogue for `opentide setup skills` is [`manifest.json`](manifest.json) at the repo root (generated from skill frontmatter).

## Architecture

This repository is a **single plugin root**. Skills live once under `skills/`; each agent harness reads the same files via its own manifest at the repo root. Nothing is copied or synced between directories.

```
plugin.json                      # Agent Plugins 1.0.0 manifest
mcp.json                         # OpenTide MCP server (opentide-mcp, stdio)
skills/                          # Canonical skills (only copy in git)
AGENTS.md                        # Unified agents.md entrypoint
POWER.md                         # Kiro Power (legacy activation; plugin.json is preferred)
steering/                        # Kiro workflow routing (points at skills/)
.cursor-plugin/plugin.json       # Cursor compatibility manifest
.claude-plugin/plugin.json       # Claude Code compatibility manifest
.codex-plugin/plugin.json        # OpenAI Codex compatibility manifest
.plugin/plugin.json              # GitHub Copilot (OpenPlugin) compatibility manifest
rules/                           # Cursor rules (optional)
```

Install-time caching (Claude Code, Cursor marketplace) may copy files into a local plugin cache on the user's machine — that is expected platform behaviour, not duplication in this repository.

## Quick install

### Cross-harness (recommended)

```bash
npx skills add OpenTideHQ/skills
cp AGENTS.md /path/to/your/project/
```

Or copy manually into `.agents/skills/` (works with Cursor, Copilot, Codex, Kiro, Gemini CLI, and other [spec-compatible agents](https://agentskills.io/clients)).

### Agent plugin

Clients that implement [Agent Plugins 1.0.0](https://agent-plugins.org/specification) install this repository as one plugin. Skills load from `skills/`. [`mcp.json`](mcp.json) starts the OpenTide MCP server.

```bash
pip install 'opentide[mcp]'
```

The server entry is the bare executable `opentide-mcp` on `PATH` (stdio), the same command as [`opentide setup mcp`](https://github.com/OpenTideHQ/opentide/blob/development/docs/mcp/configuration.md). This file does not set `OPENTIDE_REPO_ROOT`. The server resolves the detection repository from its working directory. A conforming client starts that process in the plugin root, which is this skills repository. Point the server at a content repository when the host's working directory is not that repository.

Harness manifests under `.cursor-plugin/`, `.claude-plugin/`, `.codex-plugin/`, and `.plugin/` remain for clients that do not read the portable `plugin.json` yet.

### Harness-specific plugins

| Harness | Install | Manifest |
|---------|---------|----------|
| **Cursor** | Marketplace or clone + load from repo root | `.cursor-plugin/plugin.json` |
| **Claude Code** | `/plugin marketplace add OpenTideHQ/skills` then `/plugin install opentide-detection-skills@opentide` | `.claude-plugin/plugin.json` |
| **GitHub Copilot** | VS Code Extensions → Agent Plugins, or Copilot CLI | `.plugin/plugin.json` |
| **OpenAI Codex** | `/plugins` → install from repo marketplace | `.codex-plugin/plugin.json` |
| **Kiro Power** | Powers panel → Import from GitHub → `OpenTideHQ/skills` | `POWER.md` + `steering/` |
| **Kiro Skills** | Import `skills/<name>/` or copy to `.kiro/skills/` | [Agent Skills](https://kiro.dev/docs/skills/) |

See [docs/install.md](docs/install.md) and [docs/harnesses.md](docs/harnesses.md) for the full standards matrix.

## Contributing

1. Edit skills under `skills/<skill-name>/SKILL.md`.
2. Run `./scripts/validate-skills.sh` (frontmatter checks and manifest drift gate).
3. Regenerate the catalogue: `./scripts/build-manifest.sh` (commits `manifest.json`).
4. Open a pull request.

`manifest.json` is the catalogue source for `opentide setup skills discover|show|install`. Harness plugin manifests at the repo root still point at `./skills/` — no separate sync step for those.

See [`skills/README.md`](skills/README.md) for authoring conventions.

## License

Licensed under the [European Union Public Licence v. 1.2](LICENSE) (EUPL-1.2).
