# OpenTide Skills

Canonical home for reusable [Agent Skills](https://agentskills.io/specification) for detection engineering — **27 skills**, one source tree, multi-harness plugin manifests.

## Architecture

This repository is a **single plugin root**. Skills live once under `skills/`; each agent harness reads the same files via its own manifest at the repo root. Nothing is copied or synced between directories.

```
skills/                          # Canonical skills (only copy in git)
AGENTS.md                        # Unified agents.md entrypoint
POWER.md                         # Kiro Power (steering + activation)
steering/                        # Kiro workflow routing (points at skills/)
.cursor-plugin/plugin.json       # Cursor
.claude-plugin/plugin.json       # Claude Code
.codex-plugin/plugin.json        # OpenAI Codex
.plugin/plugin.json              # GitHub Copilot (OpenPlugin)
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
2. Run `./scripts/validate-skills.sh`.
3. Open a pull request.

No sync step — manifests already point at `./skills/`.

See [`skills/README.md`](skills/README.md) for authoring conventions.

## License

Licensed under the [European Union Public Licence v. 1.2](LICENSE) (EUPL-1.2).
