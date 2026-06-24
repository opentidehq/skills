---
name: "opentide-detection"
displayName: "OpenTide Detection Engineering"
description: "Detection-as-code expertise for OpenTide — TVM/DOM/MDR authoring, threat hunting, MITRE ATT&CK mapping, KQL/SPL/FQL platform knowledge, and defensive internals across Sentinel, Defender, Splunk, CrowdStrike, and more."
keywords:
  - opentide
  - detection engineering
  - detection-as-code
  - threat hunting
  - threat vector
  - detection objective
  - detection rule
  - mitre attack
  - att&ck
  - kql
  - kusto
  - spl
  - splunk
  - sentinel
  - microsoft sentinel
  - defender
  - defender for endpoint
  - crowdstrike
  - falcon
  - carbon black
  - sentinelone
  - harfanglab
  - sigma
  - dom
  - tvm
  - mdr
  - yaml
author: "OpenTideHQ"
---

# OpenTide Detection Engineering

Knowledge Base Power for OpenTide detection-as-code work. This repository bundles **27 portable Agent Skills** (`skills/`) and cross-cutting agent instructions (`AGENTS.md`) — steering files route you to the right `SKILL.md` on demand.

## Onboarding

### Step 1: Confirm context

Determine whether you are editing **skill content in this repository** or **detection YAML objects in a content repository**. If unclear — ask the user before creating paths.

### Step 2: Load entrypoint

Read **`AGENTS.md`** at the repository root for prime directives, guardrails, object workflow, and the full skills index.

### Step 3: Agent Skills (optional in Kiro)

Skills follow the open [agentskills.io](https://agentskills.io/specification) format under `skills/<skill-name>/SKILL.md`.

To register them in Kiro IDE:

1. **Agent Steering & Skills** → **Import a skill**
2. GitHub URL per skill, e.g. `https://github.com/OpenTideHQ/skills/tree/main/skills/kusto-query-language`
3. Or copy `skills/*` into the project's `.kiro/skills/`

The power works without importing every skill — steering routes you to read the relevant `SKILL.md` from this repo when needed.

### Step 4: Validation CLI (optional)

If an OpenTide validation CLI is available in the workspace, use it to check objects before commit.

## When to load steering files

Load steering on demand — do not read everything upfront.

| Task | Steering file |
|------|----------------|
| Creating or updating TVM, DOM, or MDR YAML | `opentide-object-workflow.md` |
| Hunt → alert, PR scope, platform pairing | `hunt-to-detection.md` |
| Which skill to load for a query or platform | `skills-routing.md` |

## Quick routing

| User mentions | Read first |
|---------------|------------|
| Threat intelligence → TVM | `skills/opentide-threat-vector/SKILL.md` |
| Detection objective / signals | `skills/opentide-detection-objective/SKILL.md` |
| Detection rule / platform config | `skills/opentide-detection-rule/SKILL.md` |
| KQL (any Microsoft surface) | `skills/kusto-query-language/SKILL.md` + platform skill |
| Sentinel / Log Analytics | `skills/microsoft-sentinel/SKILL.md` |
| Defender Advanced Hunting | `skills/microsoft-defender-endpoint/SKILL.md` |
| Splunk / SPL | `skills/splunk-spl-processing/SKILL.md` |
| ATT&CK mapping | `skills/mitre-attack/SKILL.md` |
| Threat hunt / hypothesis | `skills/threat-hunting/SKILL.md` |
| Cross-object lifecycle | `skills/detection-engineering/SKILL.md` |

Always pair **`kusto-query-language`** with the relevant Microsoft platform skill. Load the **narrowest** skill first; escalate when coordination is required.

## Guardrails (summary)

Full rules are in `AGENTS.md`. Non-negotiable:

- One object type per run (TVM → DOM → MDR); do not mix without explicit user approval
- Validate against JSON schemas; never tamper with schemas/templates unless instructed
- Use provided intelligence only — do not hallucinate CTI or vendor syntax
- Generate fresh UUIDs; never reuse across objects
- British English by default

## Repository layout

```
skills/           # 27 Agent Skills (canonical, agentskills.io)
AGENTS.md         # Cross-harness entrypoint (agents.md standard)
POWER.md          # This Kiro Power
steering/         # Workflow routing (this power)
```

Harness plugin manifests (Cursor, Claude Code, Copilot, Codex) live at the repo root — see `docs/harnesses.md`.
