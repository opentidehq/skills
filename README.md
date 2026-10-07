# opentide skills

<p align="center">
  <img src="docs/opentide-logo.svg" alt="opentide" width="280">
</p>

[![skills.sh](https://skills.sh/b/OpenTideHQ/skills)](https://skills.sh/OpenTideHQ/skills)

Canonical home for opentide detection skills. The plugin `opentide-detection-skills` teaches agents to model threats, define what to detect, and write the rules and queries. The machine-readable catalogue for `opentide setup skills` is [`manifest.json`](manifest.json).

## Install

Install the OpenTide MCP server once. The plugin starts it as `opentide-mcp` on `PATH`.

```bash
pip install 'opentide[mcp]'
```

Then use the command for your agent. Each one installs this repository.

| | Agent | Command |
| --- | --- | --- |
| <img src="docs/marketplace-skills-sh.png" width="36" height="36" alt="skills.sh"> | **skills.sh** | `npx skills add OpenTideHQ/skills` |
| <img src="docs/marketplace-cursor.svg" width="36" height="36" alt="Cursor"> | **Cursor** | `/add-plugin OpenTideHQ/skills` |
| <img src="docs/marketplace-claude.svg" width="36" height="36" alt="Claude Code"> | **Claude Code** | `/plugin marketplace add OpenTideHQ/skills` then `/plugin install opentide-detection-skills@opentide` |
| <img src="docs/marketplace-vscode.svg" width="36" height="36" alt="Visual Studio Code"> | **VS Code** | Command Palette → **Chat: Install Plugin From Source** → `OpenTideHQ/skills` |
| <img src="docs/marketplace-copilot.svg" width="36" height="36" alt="GitHub Copilot"> | **Copilot CLI** | `copilot plugin marketplace add OpenTideHQ/skills` then `copilot plugin install opentide-detection-skills@opentide` |
| <img src="docs/marketplace-codex.svg" width="36" height="36" alt="OpenAI Codex"> | **Codex** | In this repo, run `/plugins` and install **opentide-detection-skills** |
| <img src="docs/marketplace-kiro.svg" width="36" height="36" alt="Kiro"> | **Kiro** | Powers → **Add Custom Power** → **Import from GitHub** → `https://github.com/OpenTideHQ/skills` |

Copy [`AGENTS.md`](AGENTS.md) into a detection project when the agent reads project instructions from the workspace root.

VS Code needs `chat.plugins.enabled`. A conforming client starts `opentide-mcp` in this plugin root. Point the server at the detection content repository when that working directory is this skills repository. See the [OpenTide MCP configuration](https://github.com/OpenTideHQ/opentide/blob/development/docs/mcp/configuration.md).

[`skills.sh.json`](skills.sh.json) groups the [skills.sh repository page](https://skills.sh/OpenTideHQ/skills). skills.sh reads that file from the default branch on the next `npx skills add`.

Longer notes for each harness: [docs/install.md](docs/install.md).

## Architecture

Skills live once under `skills/`. Harness manifests at the repository root point at that tree.

```
plugin.json                      # Agent Plugins 1.0.0 manifest
mcp.json                         # OpenTide MCP server (opentide-mcp, stdio)
skills.sh.json                   # skills.sh repository page groups
skills/                          # Canonical skills (only copy in git)
AGENTS.md                        # Unified agents.md entrypoint
POWER.md                         # Kiro Power (legacy activation; plugin.json is preferred)
steering/                        # Kiro workflow routing (points at skills/)
.cursor-plugin/plugin.json       # Cursor compatibility manifest
.claude-plugin/plugin.json       # Claude Code manifest (mcpServers → ./mcp.json)
.codex-plugin/plugin.json        # OpenAI Codex compatibility manifest
.plugin/plugin.json              # Legacy OpenPlugin compatibility manifest
rules/                           # Cursor rules (optional)
```

Install-time caching may copy files into a local plugin cache on the user's machine. That cache is platform behaviour, and this repository keeps a single copy.

## Still to publish

These installs work from GitHub today. The remaining catalogue submissions are tracked in [#19](https://github.com/OpenTideHQ/skills/issues/19).

| Catalogue | What is left |
| --- | --- |
| [Cursor Marketplace](https://cursor.com/marketplace/publish) | Submit this repository. Listing is manually reviewed. The plugin icon is `docs/opentide-icon.svg`. |
| [Claude community](https://platform.claude.com/plugins/submit) | Run `claude plugin validate .`, then submit. The official Claude catalogue is invite-only. |
| [Awesome Copilot](https://github.com/github/awesome-copilot) | Open a pull request using that repository's contributing guide. |
| [ChatGPT / Codex directory](https://developers.openai.com/codex/plugins) | Submit the plugin for the shared public directory. |
| [Kiro Powers](https://kiro.dev/powers) | GitHub import works now. A curated registry listing still needs the Kiro submission path. |
| GitHub skill search | Add the repository topic `agent-skills`, then `gh skill publish`. |

The engine task for `opentide setup` installing this plugin is [opentide#431](https://github.com/OpenTideHQ/opentide/issues/431).

## Contributing

1. Edit skills under `skills/<skill-name>/SKILL.md`.
2. Run `./scripts/validate-skills.sh` (frontmatter checks and manifest drift gate).
3. Regenerate the catalogue: `./scripts/build-manifest.sh` (commits `manifest.json`).
4. Open a pull request.

`manifest.json` is the catalogue source for `opentide setup skills discover|show|install`. Harness plugin manifests at the repo root still point at `./skills/`.

See [`skills/README.md`](skills/README.md) for authoring conventions.

The OpenTide mark is copied from [OpenTideHQ/.github](https://github.com/OpenTideHQ/.github/tree/main/assets/svg) (`logo-normal.svg`, `icon-normal.svg`). Marketplace marks in this README identify install targets and belong to their respective owners.

## License

Licensed under the [European Union Public Licence v. 1.2](LICENSE) (EUPL-1.2).
