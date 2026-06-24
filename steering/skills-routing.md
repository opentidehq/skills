# Skills routing index

All paths are relative to this repository root. Each skill is a `skills/<name>/SKILL.md` file ([agentskills.io](https://agentskills.io/specification)).

## OpenTide authoring

| Skill | When to load |
|-------|--------------|
| `opentide-threat-vector` | TVM from intelligence, TTP modelling, chaining |
| `opentide-detection-objective` | DOM signals, methodology, data contracts |
| `opentide-detection-rule` | MDR platform `configurations.*`, deployment payloads |

## Practice

| Skill | When to load |
|-------|--------------|
| `detection-engineering` | Lifecycle, hunt-to-rule, PR scope, platform matrix |
| `threat-hunting` | Hypotheses, ABLE, hunt → content conversion |
| `mitre-attack` | ATT&CK mapping, v19 baseline, coverage analysis |

## Languages and platforms

| Skill | When to load |
|-------|--------------|
| `kusto-query-language` | Any KQL — pair with a Microsoft platform skill |
| `microsoft-sentinel` | Sentinel tables, NRT, ASIM, TI |
| `microsoft-defender-endpoint` | Advanced Hunting, Device* schemas |
| `entra-id` | Entra identity telemetry, ResultType, OAuth |
| `windows-event-logs` | Native Windows event IDs, audit policy |
| `splunk-spl-processing` | SPL, ES, tstats, correlation searches |
| `crowdstrike-falcon` | FQL, CQL, Custom IOA, Storyline |
| `carbon-black-cloud` | Watchlists, process_guid, Live Response |
| `sentinelone-singularity` | DVQL, STAR, Storyline (not Microsoft Sentinel) |
| `harfanglab` | Sigma, RHQL, YARA |
| `okta-identity` | Okta System Log, impersonation, session theft |
| `amazon-web-services` | CloudTrail, IAM, GuardDuty |
| `microsoft-azure` | Activity Log, ARM, RBAC, Key Vault |
| `google-cloud-platform` | Cloud Audit Logs, Chronicle mapping |

## Defensive internals

| Skill | When to load |
|-------|--------------|
| `windows-internals` | Process chain, tokens, ETW, registry |
| `active-directory` | Kerberos, delegation, AD CS, GPO |
| `identity-providers` | OAuth/OIDC, SAML, PRT, federation |
| `network-protocols` | DNS, TLS, SMB, HTTP C2, RDP |
| `email-and-collaboration` | Exchange, M365 mail, Teams, Purview |
| `linux-internals` | Capabilities, auditd, eBPF, containers |
| `macos-internals` | launchd, TCC, Gatekeeper, Endpoint Security |

## Rule

Load the **narrowest** skill first. For KQL, always pair `kusto-query-language` with the relevant Microsoft platform skill.
