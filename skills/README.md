# Skills directory

Canonical skill content for OpenTide. Each skill is a folder containing a required `SKILL.md` file following the [Agent Skills specification](https://agentskills.io/specification).

## Structure

```
<skill-name>/
├── SKILL.md
├── references/     # optional — loaded on demand
├── scripts/        # optional
└── assets/         # optional
```

## SKILL.md frontmatter

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description of what this skill does and when to use it
license: EUPL-1.2
metadata:
  author: OpenTideHQ
---
```

The `name` must match the parent directory name (lowercase, hyphens, max 64 characters).

## Skills index

### OpenTide content authoring
| Skill | Purpose |
|---|---|
| `opentide-threat-vector` | TVM authoring |
| `opentide-detection-objective` | DOM authoring |
| `opentide-detection-rule` | MDR authoring |

### Detection-engineering practice
| Skill | Purpose |
|---|---|
| `detection-engineering` | Hunt-to-rule lifecycle, platform pairing |
| `threat-hunting` | ABLE hypothesis framework, hunt conversion |
| `mitre-attack` | ATT&CK mapping discipline (v19 baseline) |

### Languages & platforms (14)
`kusto-query-language`, `microsoft-sentinel`, `microsoft-defender-endpoint`, `entra-id`, `windows-event-logs`, `splunk-spl-processing`, `crowdstrike-falcon`, `carbon-black-cloud`, `sentinelone-singularity`, `harfanglab`, `okta-identity`, `amazon-web-services`, `microsoft-azure`, `google-cloud-platform`

### Defensive internals (7)
`windows-internals`, `active-directory`, `identity-providers`, `network-protocols`, `email-and-collaboration`, `linux-internals`, `macos-internals`

Full descriptions: [`AGENTS.md`](../AGENTS.md#skills-index-skills).

## Adding or editing a skill

1. Create or edit `skills/<skill-name>/SKILL.md`.
2. Run `../scripts/validate-skills.sh`.
3. Run `../scripts/build-manifest.sh` and commit the updated root `manifest.json`.
4. Open a pull request.

Harness plugin manifests at the repo root reference `./skills/` automatically — no sync or copy step for those. The OpenTide CLI reads `manifest.json` for discover/show/install.
