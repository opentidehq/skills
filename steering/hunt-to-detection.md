# Hunt to detection

Use when converting hunts to production rules, planning multi-phase detection work, or reviewing PR scope across OpenTide objects.

## Primary skill

Read **`skills/detection-engineering/SKILL.md`** — OpenTide TVM → DOM → MDR sequencing, 7-step hunt-to-rule conversion, platform pairing matrix, maturity progression, PR discipline.

## Supporting skills

| Situation | Skill path |
|-----------|------------|
| Hypothesis design, ABLE framework | `skills/threat-hunting/SKILL.md` |
| Technique selection / coverage gaps | `skills/mitre-attack/SKILL.md` |
| Microsoft KQL (any surface) | `skills/kusto-query-language/SKILL.md` + platform skill |
| Splunk SPL | `skills/splunk-spl-processing/SKILL.md` |
| Endpoint XDR consoles | Vendor skill (`crowdstrike-falcon`, `sentinelone-singularity`, `carbon-black-cloud`, `harfanglab`) |

## Platform pairing reminder

| Stack | Language skill | Platform skill |
|-------|----------------|----------------|
| Sentinel / Log Analytics | `kusto-query-language` | `microsoft-sentinel` |
| Defender Advanced Hunting | `kusto-query-language` | `microsoft-defender-endpoint` |
| Splunk Enterprise / ES | `splunk-spl-processing` | (included in SPL skill) |
| CrowdStrike Falcon | — | `crowdstrike-falcon` |

Never invent vendor syntax — use skill references and in-repo samples.
