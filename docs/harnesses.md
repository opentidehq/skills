# Harness and plugin standards

OpenTide Skills targets **one canonical `skills/` tree** and layers harness-specific packaging on top without duplicating skill content.

## Standards map

| Standard | Format | Maintainer | This repo |
|----------|--------|------------|-----------|
| [Agent Skills](https://agentskills.io/specification) | `skills/<name>/SKILL.md` | agentskills.io / Anthropic | **Canonical** — `skills/` |
| [AGENTS.md](https://agents.md/) | Root `AGENTS.md` | AAIF / community | **Yes** — `AGENTS.md` |
| [MCP](https://modelcontextprotocol.io/) | `mcp.json`, tool servers | AAIF | Not bundled in this repo |
| **Kiro Power** | `POWER.md` + `steering/` | AWS Kiro | **Yes** — `POWER.md`, `steering/` |
| **Cursor plugin** | `.cursor-plugin/plugin.json` | Cursor | **Yes** |
| **Claude Code plugin** | `.claude-plugin/plugin.json` | Anthropic | **Yes** |
| **Codex plugin** | `.codex-plugin/plugin.json` | OpenAI | **Yes** |
| **Copilot / OpenPlugin** | `.plugin/plugin.json` | GitHub / VS Code | **Yes** |

## Tier 1 — Native plugin manifest (in this repo)

These read `./skills/` from the repository root at install time.

| Harness | Manifest | Marketplace |
|---------|----------|-------------|
| Cursor | `.cursor-plugin/plugin.json` | `.cursor-plugin/marketplace.json` |
| Claude Code | `.claude-plugin/plugin.json` | `.claude-plugin/marketplace.json` |
| OpenAI Codex | `.codex-plugin/plugin.json` | `.agents/plugins/marketplace.json` |
| GitHub Copilot / VS Code | `.plugin/plugin.json` | VS Code / Copilot marketplaces |
| Kiro | `POWER.md` | [kiro.dev/powers](https://kiro.dev/powers) (community) or GitHub import |

## Tier 2 — Agent Skills native (no extra manifest)

These discover `SKILL.md` files directly. Install by copying or `npx skills add`:

| Harness | Project path | Global path | Notes |
|---------|--------------|-------------|-------|
| **Cross-harness default** | `.agents/skills/` | `~/.agents/skills/` | Codex, Antigravity, many others |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` | Also reads `.agents/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` | Plugin namespace when installed as plugin |
| Kiro | `.kiro/skills/` | `~/.kiro/skills/` | Import per skill from GitHub |
| Gemini CLI | `.gemini/skills/` | `~/.gemini/skills/` | Also `.agents/skills/` |
| Antigravity CLI | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | Successor to Gemini CLI |
| OpenCode | `.opencode/skills/` or `.agents/skills/` | per [opencode docs](https://opencode.ai/docs/skills/) | |
| Roo Code | `.roo/skills/` | per [Roo docs](https://docs.roocode.com/features/skills) | |
| Goose | `.goose/skills/` | per [Goose docs](https://block.github.io/goose/) | |
| JetBrains Junie | `.junie/skills/` | [junie guidelines catalog](https://github.com/JetBrains/junie-guidelines) | Body of SKILL.md |
| Amp | reads `AGENTS.md` + skills paths | per [Amp manual](https://ampcode.com/manual#agent-skills) | |
| Factory CLI | per Factory docs | | |
| Cline, Continue, OpenHands, … | see [agentskills.io/clients](https://agentskills.io/clients) | | |

**No additional files required** in this repo for Tier 2 — `skills/` + `AGENTS.md` are sufficient.

## Tier 3 — Rules / steering only (no SKILL.md plugin format)

These use proprietary rule files. Skills remain portable; adapters generate rules if needed.

| Harness | Native format | Skill equivalent |
|---------|---------------|------------------|
| Windsurf | `.windsurf/rules/*.md` | Copy or generate from SKILL.md |
| Trae | `.trae/rules/` | Same |
| Cursor (always-on) | `.cursor/rules/*.mdc` | We ship `rules/opentide-detection-engineering.mdc` |

We do **not** maintain duplicate Windsurf/Trae rule trees unless there is demand — Tier 2 install is enough for most users.

## Kiro: Power vs Skills

Kiro has **two** extension mechanisms:

| Mechanism | File | Purpose |
|-----------|------|---------|
| **Agent Skills** | `skills/<name>/SKILL.md` | Portable expertise ([docs](https://kiro.dev/docs/skills/)) |
| **Powers** | `POWER.md` + `steering/` | Keyword activation, onboarding, workflow routing ([docs](https://kiro.dev/docs/powers/create/)) |

This repo provides both without duplication:

- **`skills/`** — canonical skill bodies (agentskills.io)
- **`POWER.md`** — Kiro activation layer; steering files **point at** `skills/*.md`, they do not copy them

Install the power: Powers panel → **Import power from GitHub** → `https://github.com/OpenTideHQ/skills`

## What we deliberately do not add

| Format | Reason |
|--------|--------|
| Per-harness copied `skills/` trees | Duplication; install cache handles distribution |
| `.windsurf/` / `.trae/` rule mirrors | Tier 2 skills install covers most cases |
| Separate Gemini/Antigravity manifest | No stable cross-repo `plugin.json` — use `.agents/skills/` |
| `mcp.json` in this repo | MCP servers are not bundled here |

## Future candidates

- **Guided MCP Power** — optional `mcp.json` for validate/generate tooling
- **Windsurf rule pack** — generated from SKILL.md if community requests it
- **OpenCode / Factory marketplace entry** — when publish paths stabilise
