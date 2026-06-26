# OpenTide object workflow

Use when authoring or reviewing **Threat Vector (TVM)**, **Detection Objective (DOM)**, or **Detection Rule (MDR)** YAML in OpenTide content repositories.

## Before you write

1. Read **`AGENTS.md`** — guardrails and communication protocol.
2. Confirm object type for this run (do not mix TVM + DOM + MDR in one pass unless the user explicitly requests it).

## Object types

| Type | Schema tag | Typical path |
|------|------------|--------------|
| Threat Vector | `tvm::…` / `threat::1.0` | `objects/threats/*.yaml` (library) or `Objects/Threat Vectors/*.yaml` (legacy) |
| Detection Objective | `dom::…` / `objective::1.0` | `objects/objectives/*.yaml` |
| Detection Rule | `mdr::…` / `rule::1.0` | `objects/rules/*.yaml` |

**Filenames:** dash-case slugs derived from the object `name` (lowercase, hyphens — `slugify()` in opentide). The `name` field stays human-readable; generated docs mirror the slug.

## Workflow

1. **Analyse intelligence** — distinct TTPs only; stop if object type is unclear.
2. **Plan hierarchy** — TVMs first, then DOMs, then MDRs.
3. **Search existing objects** — update vs create; preserve UUIDs when updating.
4. **Load templates and schemas** from the content repo's `Schemas/` tree.
5. **Generate UUIDs** with system tools (`uuidgen` / `[guid]::NewGuid()`).
6. **Author** — TVM → DOM → MDR; link relations correctly.
7. **Validate** with `opentide validate` or schema CI.

## Skills to load

| Phase | Skill path |
|-------|------------|
| TVM | `skills/opentide-threat-vector/SKILL.md` |
| DOM | `skills/opentide-detection-objective/SKILL.md` |
| MDR | `skills/opentide-detection-rule/SKILL.md` |
| ATT&CK fields | `skills/mitre-attack/SKILL.md` |

## Platform keys (MDR `configurations.*`)

Common surfaces: `sentinel`, `defender_for_endpoint`, `splunk`, `crowdstrike`, `carbon_black_cloud`, `sentinel_one`. Consult active meta-schema release notes before adding others.
