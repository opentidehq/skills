# opentide object workflow

Use when authoring or reviewing **threat** (TVM), **objective** (DOM), or **rule** (MDR) YAML in opentide content repositories.

## Before you write

1. Read **`AGENTS.md`** — guardrails and communication protocol.
2. Confirm object type for this run (do not mix TVM + DOM + MDR in one pass unless the user explicitly requests it).

## Object types

| Type | Schema tag | Typical path |
|------|------------|--------------|
| Threat | `threat::…` | `objects/threats/*.yaml` (CoreTide-era: `Objects/Threat Vectors/`) |
| Objective | `objective::…` | `objects/objectives/*.yaml` |
| Rule | `rule::…` | `objects/rules/*.yaml` |

Resolve the current revision (for example `rule::1.1`) from `opentide://schemas/<family>` or `.opentide/schemas/`, not from this table.

**Filenames:** dash-case slugs derived from the object `name` (lowercase, hyphens — `slugify()` in opentide). The `name` field stays human-readable; generated docs mirror the slug.

## Workflow

1. **Analyse intelligence** — distinct TTPs only; stop if object type is unclear.
2. **Plan hierarchy** — TVMs first, then DOMs, then MDRs.
3. **Search existing objects** — update vs create; preserve UUIDs when updating.
4. **Load templates and schemas** — `opentide://templates/<family>` and `opentide://schemas/<family>`, or `.opentide/templates/` and `.opentide/schemas/` (`opentide generate` writes them).
5. **Generate UUIDs** with system tools (`uuidgen` / `[guid]::NewGuid()`).
6. **Author** — TVM → DOM → MDR; link relations correctly.
7. **Validate** with `opentide validate` or schema CI.

## Skills to load

| Phase | Skill path |
|-------|------------|
| TVM | `skills/opentide-threat/SKILL.md` |
| DOM | `skills/opentide-objective/SKILL.md` |
| MDR | `skills/opentide-rule/SKILL.md` |
| Visibility configuration (upstream of DOM data claims) | `skills/opentide-visibility/SKILL.md` |
| ATT&CK fields | `skills/mitre-attack/SKILL.md` |

## Platform keys (MDR `configurations.*`)

`sentinel`, `defender_for_endpoint`, `splunk`, `crowdstrike`, `carbon_black_cloud`, `sentinel_one`, `harfanglab`, `elastic`, `sysdig`, `bitdefender`, `graylog`, `exabeam`, `google_secops`. `opentide --json info` is authoritative; `coverage.json` maps each key to its platform skill.
