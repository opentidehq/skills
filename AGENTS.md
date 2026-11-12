# AGENTS.md — Unified agent entrypoint (opentide)

Canonical instructions for autonomous coding assistants working across **opentide content** repositories. Pair with granular skills under **`skills/<skill-name>/SKILL.md`** (or harness-specific install paths — see [README.md](README.md)) following the [Agent Skills specification](https://agentskills.io/specification) — each `SKILL.md` carries YAML frontmatter (`name`, `description`) for discovery, with optional `references/`, `assets/`, and `scripts/` subdirectories.

---

When unclear which corpus you are editing — ask **before creating paths**.

---

## Prime directives

- **Correctness** — Be exact and cognitively correct when breaking down intelligence and complex threat data into modelled opentide artefacts. Treat intelligence fidelity and analytic literalness seriously.
- **Consistency** — Maintain a coherent repository. Sometimes it is better to improve several existing objects before creating a new one. Prefer adjusting related artefacts coherently over isolated one-offs.
- **Transparency** — All changes, decisions, and proposals must be rationalised, discoverable, and surfaced in summaries or commit messages that reviewers can consume.
- **Critical thinking** — No vague conclusions. All modelling decisions must be critical. Challenge weak analytic leaps — politely. You are allowed to disagree with the user when reasoning is poor.
- **Autonomy when safe** — Drive tasks end-to-end when scope permits. As much as possible, aim at performing complete changes autonomously.

---

## Guardrails

### Content integrity
- **NEVER** tamper with schemas or templates unless explicitly instructed.
- **DO NOT** change configuration files except when explicitly directed.
- **NEVER** create new folders or restructure the repository without explicit request.
- **ALWAYS** validate files against JSON schemas before saving.
- **ALWAYS** use templates as a guide for object structure.

### Top-down enforcement
- Given threat intelligence → create threat object(s) (TVM).
- Given threat objects → create detection objective(s) (DOM).
- Given objective(s) → create detection rule(s) (MDR).
- Per run, avoid mixing object types. Always generate the correct object type, and if prompted to mix, ask whether doing it in a separate PR (after the first objects are merged) is preferable. **Mixing object types is not the intended workflow.**

### Intelligence sourcing
- **DO** use provided intelligence and repository content as your primary source.
- **DO NOT** rely on pre-training data for threat intelligence or TTPs.
- **DO** search and reference existing objects when relevant.
- **DO NOT** hallucinate or invent threat intelligence.
- When there is not enough data from the intelligence presented, you may propose alternatives but **STOP** before proceeding — wait for user acceptance.

---

## opentide framework essentials

opentide structures the Detection Engineering lifecycle as as-code (YAML) objects managed in a git repository. There are three core object types:

| Type | Schema family | Location | Responsibility |
|------|---------------|----------|----------------|
| **Threat** (TVM) | `threat::…` | `objects/threats/*.yaml` | Atomically defined TTPs at a low level, directly generated from threat intelligence. Supports bi-directional chaining to represent attack paths. |
| **Objective** (DOM) | `objective::…` | `objects/objectives/*.yaml` | Detection capabilities for identified threats. Supports 1:N and N:1 relations with threats. Composed of signals (atomic detection rule ideas) that rules reference. |
| **Rule** (MDR) | `rule::…` | `objects/rules/*.yaml` | Detection-as-Code files for deployment. Directly linked to objectives, indirectly to threats. **`configurations.*` blocks keyed by detection platform.** |

The structural revision (`metadata.schema`, e.g. `rule::1.1`) moves with the engine: resolve it from the opentide MCP resources (`opentide://schemas/<family>`, `opentide://templates/<family>`) or the generated `.opentide/schemas/` and `.opentide/templates/`, never from memory. A CoreTide-era corpus still uses `Objects/Threat Vectors/`, `Objects/Detection Objectives/` and `Objects/Detection Rules/`; `opentide migrate objects` moves it forward, and that is the repository owner's decision.

opentide deploys to thirteen platforms, each a `configurations.<key>`: `sentinel`, `defender_for_endpoint`, `splunk`, `crowdstrike`, `carbon_black_cloud`, `sentinel_one`, `harfanglab`, `elastic`, `sysdig`, `bitdefender`, `graylog`, `exabeam`, `google_secops`. [`coverage.json`](coverage.json) maps each key to its skills; `opentide --json info` lists the platforms the installed engine knows and whether each can deploy, validate (`--live`) and query.

---

## Default workflow

1. **TVM intake & modelling** — analyse intelligence, identify distinct TTPs, map relationships
2. **DOM signalisation** — define which signals realise coverage, establish data contracts
3. **MDR platform binding(s)** — deploy detection payloads per connected stack

Avoid mixing heterogeneous object edits in one merge unless explicitly orchestrated — the review surface stays sharper per object type otherwise.

### When creating objects from intelligence

1. **Analyse the intelligence** — review thoroughly, identify distinct TTPs and detection opportunities, map relationships. Avoid inferring from intuition knowledge not present in the source. **STOP** and ask for precision if unsure which object types to create.
2. **Plan the object hierarchy** — determine which TVMs need creating (and chaining opportunities), identify corresponding DOMs, plan MDRs if applicable.
3. **Check for existing content** — search the repository for related objects. Determine if updates to existing files are more appropriate than creating new ones. If updating, preserve coherency, existing UUIDs, and relations.
4. **Consult templates and schemas** — load the template for the object's family (`opentide://templates/<family>` or `.opentide/templates/`; `opentide generate` writes them), reference the matching JSON Schema for field requirements, understand required vs. optional fields.
5. **Generate UUIDs** — use system tools (`uuidgen` on Unix/macOS, `[guid]::NewGuid()` on PowerShell). **NEVER reuse UUIDs from existing objects.** If unable to generate, clearly instruct the user to add them manually.
6. **Create objects** — start with TVMs (foundational), then DOMs (link to TVMs), finally MDRs (link to DOMs). Place files in the correct folders per project structure.
7. **Validate** — check for schema validation errors, verify all required fields are populated, confirm UUIDs are unique, review relationships between objects.

---

## Query & platform skill routing

Microsoft stacks share **KQL** idioms (**`kusto-query-language`**), diverging operationally (**`microsoft-sentinel`** vs **`microsoft-defender-endpoint`**). Splunk adopts **SPL** (**`splunk-spl-processing`**). Other SIEMs each carry their own language skill: **`elastic-security`** (Kuery, Lucene, EQL, ES|QL), **`graylog`** (Graylog search), **`exabeam-siem`** (Exabeam Query Language — not Elastic's EQL) and **`google-secops`** (YARA-L 2.0). Endpoint / XDR / runtime integrations each carry authored guardrails (**`crowdstrike-falcon`**, **`sentinelone-singularity`**, **`carbon-black-cloud`**, **`harfanglab`**, **`bitdefender-gravityzone`**, **`sysdig-secure`**). Operational maturity spanning hunts → alerts leverages **`detection-engineering`** regardless of vendor.

| `configurations.<key>` | Skill(s) |
|---|---|
| `sentinel` | `microsoft-sentinel` + `kusto-query-language` |
| `defender_for_endpoint` | `microsoft-defender-endpoint` + `kusto-query-language` |
| `splunk` | `splunk-spl-processing` |
| `crowdstrike` | `crowdstrike-falcon` |
| `carbon_black_cloud` | `carbon-black-cloud` |
| `sentinel_one` | `sentinelone-singularity` |
| `harfanglab` | `harfanglab` |
| `elastic` | `elastic-security` |
| `sysdig` | `sysdig-secure` (+ `linux-internals`) |
| `bitdefender` | `bitdefender-gravityzone` |
| `graylog` | `graylog` |
| `exabeam` | `exabeam-siem` |
| `google_secops` | `google-secops` |

Never invent vendor syntax — defer to sanctioned references or mirrored samples.

---

## Critical constraints

### Schema compliance
- ✅ Always validate against JSON schemas.
- ✅ Use templates to understand structure before consulting full schemas.
- ✅ Search schemas for specific field requirements (schemas may be too large to load entirely).
- ❌ Never generate objects without understanding the schema requirements.

### UUID management
- ✅ Generate unique UUIDs using system tools.
- ✅ Clearly indicate when users must add UUIDs manually.
- ❌ Never reuse existing UUIDs.
- ❌ Never fabricate or hardcode UUIDs.

### File management
- ✅ Respect the existing folder structure.
- ✅ Place files in the correct `objects/` subdirectory (or the layout the repository's path configuration declares).
- ❌ Do not create new folders without explicit user request.
- ❌ Do not modify configuration or schema files without user approval.

### Authoring
- ✅ Use British English by default consistently.
- ✅ Focus on one object type per run unless the user explicitly requests a more complex operation.
- ❌ Do not create extremely long `terrain` sections in TVMs — keep them coherent, well documented, and relatively concise.
- ❌ Do not overassume when generating detection rule queries. If confidence is low, generate the object without the query and propose pseudocode as a comment, mentioning your reasoning to the user.

---

## Content repository guardrails

Unless explicitly commissioned:

- **Do not hand-edit schema templates/meta-registries blindly.**
- **Do not restructure authoritative folder layouts.**
- **Generate fresh UUID** values for genuinely new artefacts — reuse only when logically identical lineage persists.
- Prefer **British English** unless policy overrides downstream.

---

## Communication protocol

### When starting a task
1. Acknowledge the task.
2. Outline your understanding and approach.
3. Ask clarifying questions if needed.
4. Create a plan and to-dos.

### During task execution
1. Explain what you are doing at each major step.
2. Highlight any decisions or assumptions made.

### When completing a task
1. Summarise what was created or modified.
2. Explain the relationships between objects.
3. Provide any necessary next steps or manual actions required.
4. Confirm all files are in the correct locations.
5. If you focused on one object type and already identified opportunities for additional object type creation, propose a follow-up operation explicitly.

---

## Skills index (`skills/`)

### opentide content authoring
| Skill | Purpose |
|---|---|
| `opentide-threat` | TVM authoring — Phase A intelligence structuring + Phase B schema-backed YAML |
| `opentide-objective` | DOM authoring — signals, methodology, data contracts |
| `opentide-rule` | MDR authoring + platform `configurations.*` bridging |
| `opentide-visibility` | Visibility configuration — assets, collected log sources, external detectors; upstream of DOM data claims |

### Detection-engineering practice
| Skill | Purpose |
|---|---|
| `detection-engineering` | Cross-object sequencing, hunt-to-rule conversion (7-step), platform pairing matrix, maturity progression, PR scope discipline |
| `threat-hunting` | Hypothesis discipline (ABLE), confidence/relevance/priority scoring, archetypes, data-gap analysis, hunt → opentide content conversion |
| `mitre-attack` | ATT&CK technique/sub-technique selection, tactic assignment, version pinning, revocation handling, coverage analysis |

### Languages & platforms
| Skill | Purpose |
|---|---|
| `kusto-query-language` | Vendor-neutral KQL — operator hierarchy, joins, FP engineering, anti-patterns (+ `references/Best-Practices.md`, `references/Hypothesis-Anti-Patterns.md`) |
| `microsoft-sentinel` | Sentinel / Log Analytics specifics — table domain matrix, ResultType codes, NRT vs scheduled rules, ASIM, TI patterns (+ `references/Anti-Patterns.md`) |
| `microsoft-defender-endpoint` | Defender Advanced Hunting specifics — Device*/Email* schemas, mandatory output columns, FileProfile, AdditionalFields, NRT constraints (+ `references/Anti-Patterns.md`) |
| `entra-id` | Microsoft Entra ID — identity platform internals, telemetry surfaces, SKU gating, ResultType codes, directory roles, PIM, token mechanics, OAuth/consent, attack patterns (+ `references/ResultType-Codes.md`) |
| `windows-event-logs` | Windows native event IDs (Security/Sysmon/PowerShell), audit policy prerequisites, platform table mapping (+ `references/Audit-Policy-Matrix.md`) |
| `splunk-spl-processing` | SPL for Splunk Enterprise / ES — index/sourcetype discipline, stats vs tstats vs mstats, accelerated DMs, ES correlation searches, RBA (+ `references/Anti-Patterns.md`) |
| `crowdstrike-falcon` | Falcon surface map (Insight FQL, NG-SIEM CQL, Custom IOA/IOC, Fusion, RTR), Storyline ID correlation, sensor coverage (+ `references/FQL-Field-Reference.md`) |
| `carbon-black-cloud` | Carbon Black Cloud Enterprise EDR — Watchlist Reports, scheduled searches, process_guid correlation, Live Response |
| `sentinelone-singularity` | SentinelOne Singularity (NOT Microsoft Sentinel) — STAR Custom Logic, DVQL, PowerQuery / SDL, Storyline ID, exclusion discipline (+ `references/DVQL-Field-Reference.md`) |
| `harfanglab` | HarfangLab orb — Sigma rule packs, RHQL hunting, YARA, custom detection rules |
| `elastic-security` | Elastic Security detection rules — Kuery, Lucene, EQL sequences, ES\|QL, threshold / new terms / indicator match, ECS, suppression and exceptions |
| `sysdig-secure` | Sysdig Secure runtime rules and the Falco rule language — conditions, macros, lists, exceptions, event sources, container and Kubernetes context |
| `bitdefender-gravityzone` | Bitdefender GravityZone custom detection rules — criteria, YARA under the bitdefender profile, Incidents API deployment |
| `graylog` | Graylog event definitions — Filter & Aggregation, Graylog search syntax, streams, GIM fields, 6.3–7.2 differences |
| `exabeam-siem` | Exabeam New-Scale SIEM correlation rules — Exabeam Query Language, sequences, CIM fields |
| `google-secops` | Google Security Operations (Chronicle) — YARA-L 2.0 rules, UDM, match windows, outcomes, reference lists |
| `okta-identity` | Okta System Log event schema, authentication flows, cross-tenant impersonation, session theft, admin API abuse |
| `amazon-web-services` | CloudTrail events, IAM mechanics, GuardDuty findings, S3/EC2 exfiltration, cross-account access |
| `microsoft-azure` | Activity Log, ARM operations, RBAC/PIM, managed identities, Key Vault, VM extensions |
| `google-cloud-platform` | Cloud Audit Logs, IAM/service accounts, workload identity; pair with `google-secops` for YARA-L rules |

### Defensive internals
| Skill | Purpose |
|---|---|
| `windows-internals` | Process creation chain, access tokens/privileges, DLL loading, SCM, COM/WMI, named pipes, ETW, AMSI, registry |
| `active-directory` | Kerberos/NTLM flows, DCSync/DCShadow, delegation abuse, AD CS (ESC1-ESC13), GPO, LDAP reconnaissance |
| `identity-providers` | OAuth2/OIDC flows, SAML/Golden SAML, PRT mechanics, refresh token binding, federation chains, MFA ceremonies |
| `network-protocols` | DNS tunnelling/DGA, TLS anomalies, SMB coercion, HTTP/S C2 beaconing, LDAP, RDP, WinRM, SMTP headers |
| `email-and-collaboration` | Exchange Online mail flow, mailbox forwarding, OAuth app permissions, MailItemsAccessed, SharePoint, Teams, Purview UAL |
| `linux-internals` | Process model, capabilities, auditd, eBPF/Falco/Tetragon, systemd, PAM, SSH, container isolation |
| `macos-internals` | launchd/XPC, TCC framework, Gatekeeper/notarisation, code signing, persistence locations, Keychain, Endpoint Security |

Load the **narrowest** skill first — escalate outward when coordination demands. For any KQL surface always pair `kusto-query-language` with the relevant Microsoft platform skill.

---

## Keeping skills in step with opentide

These skills describe a framework that releases often. A skill that names a platform opentide no longer ships, misses one it does, or promises a capability (live validation, `opentide query`) the engine lacks, misleads every agent that loads it. Treat skill drift as a defect.

**The contract**

- [`coverage.json`](coverage.json) maps every opentide platform key to its skills and records the engine capabilities (`can_deploy`, `can_validate`, `can_query`) they were written against, plus `reviewed_against`: the last opentide release reviewed for skill impact.
- `./scripts/check-opentide-coverage.sh` runs offline inside `validate-skills.sh`: every skill it names exists, and each platform's first skill names its `configurations.<key>`.
- `./scripts/check-opentide-coverage.sh --engine` compares it with `opentide --json info` from the installed release. CI runs it on every pull request and daily against the latest PyPI release; the daily run is `--strict`, so an unreviewed release fails it and opens a *Review skills against opentide X* issue.

**On each opentide release** (or when that issue opens), read the release's `CHANGELOG.md` entries and act on each that applies:

| opentide change | Skill work |
|---|---|
| New platform | Add `skills/<vendor-product>/SKILL.md` naming `configurations.<key>`; add it to `coverage.json`, `skills.sh.json`, this file's routing table and index, `skills/README.md`, `steering/skills-routing.md`, `detection-engineering` §1, and the plugin keywords |
| A platform gains or loses `--live` validation, `opentide query` or deploy | Update that platform skill's opentide section and its flags in `coverage.json` |
| A platform's deploy behaviour, rule types, query languages or offline engine profile change | Update that platform skill |
| A platform is renamed or removed | Rename or retire its skill and every index entry; say so in the release |
| Object model, schema revision, vocabulary or repository layout | Check `opentide-threat`, `opentide-objective`, `opentide-rule`, `opentide-visibility`: they resolve structure from the engine, so fix only examples and wording that now mislead |
| CLI command, flag or MCP tool/resource renamed or removed | `grep -rn` the old name across `skills/`, `steering/`, `AGENTS.md`, `POWER.md` and replace it |
| Nothing above | Bump `reviewed_against` only |

Then bump `reviewed_against`, and bump the plugin `version` (minor for a new skill, patch for corrections) in every manifest — `validate-skills.sh` fails when they disagree.

**From the opentide side**, a pull request that adds a platform or changes one of the rows above is not done until a companion pull request is open here; opentide's own `AGENTS.md` and release checklist say the same.

## Git expectations

Skill and harness changes land through **approved pull requests** against `main` on `opentidehq/skills` so reviewers can deliberate without surprise history rewriting. Run `./scripts/validate-skills.sh` (and `./scripts/check-opentide-coverage.sh --engine` with the latest opentide installed) before opening one.
