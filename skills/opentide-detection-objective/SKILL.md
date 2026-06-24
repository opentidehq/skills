---
name: opentide-detection-objective
description: Authors OpenTide Detection Objective (DOM) YAML -- priorities, compositions, ATT&CK cross-links, signal contracts with methodology/severity/effort/entities/data requirements, and traceability toward linked Threat Vectors. Covers signal decomposition principles, composition strategies, data availability modelling, entity taxonomy, and anti-patterns distilled from production corpora. Use whenever creating or refactoring files under Detection Objectives or structuring coverage intents before Detection Rules attach.
---

# OpenTide Detection Objective (DOM)

A DOM bridges the gap between threat modelling (TVM) and deployable detection rules (MDR). It answers: **"What signals would tell us this threat is happening, and what data do we need to detect them?"**

---

## Preconditions

1. Load **`Schemas/Templates`** for DOM (e.g. `dom::1.0` — always check the live template for the current version) and authoritative JSON schemas.
2. Identify related **TVM UUIDs**. Update rather than duplicate when coverage shifts.
3. Review existing DOMs in the corpus to avoid overlapping coverage.

---

## Complete field reference

### Top-level

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | Yes | Verb-noun phrase describing the detection goal. Filename = `{name}.yaml`. |
| `references` | object | Optional | `public` (numbered), `internal` (alpha). Same convention as TVMs. |
| `metadata` | object | Yes | Same structure as TVM metadata. Schema: e.g. `dom::1.0` — verify against live template. |
| `objective` | object | Yes | Core detection content. |

### `objective` fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `priority` | enum | Yes | `Low`, `Medium`, `High`, `Critical`. Align with TVM criticality. |
| `type` | enum | Yes | `Threat` (requires `threats` array) or `Supportive` (infrastructure/methodology objectives). |
| `threats` | array[UUID] | Conditional | TVM UUIDs. Required when `type: Threat`. A single DOM can cover many TVMs. |
| `att&ck` | array[string] | Optional | Override TVM-inherited techniques. Only populate when the DOM narrows ATT&CK scope. |
| `investment` | string | Optional | Broader effort assessment than signal-level `effort`. |
| `description` | string | Yes | High-level narrative: what are we detecting, why it matters, which platforms are relevant. 3-5 sentences. NOT a signal-level technical spec. |
| `composition` | object | Yes | How signals relate. See composition section. |
| `signals` | array | Yes | At least one signal. See signal section. |

---

## Signals — the core of a DOM

Each signal represents a **distinct detection opportunity** — a specific observable that, when triggered, indicates the threat behaviour described by the parent DOM.

### Signal fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | Yes | Write as an **alert title** an analyst would see. "SAM database dump detection", not "Signal 1". |
| `uuid` | UUIDv4 | Yes | Unique per signal. Referenced by MDR `configurations.*` blocks. |
| `description` | string | Yes | Detailed technical spec: specific log fields, Event IDs, registry paths, API calls, tuning considerations. This is the **MDR specification**. |
| `severity` | enum | Yes | `Low`, `Medium`, `High`, `Critical`. Maps to expected alert severity. |
| `effort` | number (1-10) | Recommended | Implementation difficulty. 1 = trivial pattern match; 10 = complex ML pipeline. |
| `methodology` | string | Yes | Detection approach: `Pattern Matching`, `Event Search`, `Anomaly Detection`, `Threshold`, `Correlation`. |
| `data` | object | Yes | Data availability modelling. See below. |
| `entities` | array[string] | Yes | Entity types the signal correlates on. Format: `domain::type`. |
| `detectors` | array | Optional | Existing vendor detections covering this signal. |
| `examples` | array | Optional | Community detection examples (Sigma rules, KQL queries, SPL searches). |

### Signal `data` block

| Field | Type | Required | Notes |
|---|---|---|---|
| `availability` | enum | Yes | `Complete` (logs collected and validated), `Partial` (gaps exist), `Unknown` (not assessed). |
| `requirements` | string | Yes | Separate "Data collection" (agent/connector) from "Data sources" (table/event type). |
| `logsources` | array | Optional | Specific log source identifiers. |

### Entity taxonomy

Entities follow `domain::type` format:

| Domain | Types |
|---|---|
| `host` | `Process`, `File`, `Command Line`, `Registry Key/Value`, `Account`, `Domain`, `Service` |
| `cloud` | `Authentication`, `Resource`, `Application`, `Tenant` |
| `network` | `IP Address`, `Network Connection`, `DNS`, `URL` |
| `email` | `Message`, `Attachment`, `Sender` |

Include **all** entity types the signal correlates on — multiple entities enable better alert grouping and incident correlation.

---

## Signal decomposition — the most important design decision

The quality of a DOM is determined by how well it decomposes a threat into distinct, independently detectable signals.

### Decomposition principles

1. **By detection surface** — Endpoint signals, network signals, and cloud signals are separate. A web shell detection should have separate signals for HTTP-layer anomaly, host-layer file creation, and process spawning.
2. **By data dependency** — Different log sources = different signals. A signal requiring Sysmon EID 10 is separate from one requiring SecurityEvent 4688.
3. **By methodology** — Pattern matching, anomaly detection, and threshold-based detection are separate signals even if they target the same behaviour.
4. **By analyst action** — If two detections require different triage workflows, they are separate signals.

### Quality spectrum

| Quality | Pattern | Example |
|---|---|---|
| **Excellent** | 7 signals covering SAM dump, registry events, LSASS memory, shadow credentials, registry access, password reading, Kerberoasting | "Credential dumping on a local Windows endpoint" |
| **Good** | 3 signals covering device code auth, FIDO2 provisioning, and MFA bypass | "Entra ID Authentication Bypass" |
| **Mediocre** | Single signal for a broad topic that should decompose into 3+ signals | "Web Shell Attacks" — one signal mixing network, host, and process detection |
| **Bad** | Single signal with a laundry list of detection ideas crammed into one description | "Suspicious OAuth applications" |

### Signal description quality

The signal `description` is the **specification that MDR rules implement**. It must include:

- **Specific log fields** or Event IDs (e.g. `authenticationProtocol: "deviceCode"`, `EventID 4657`)
- **Registry paths**, API calls, or command patterns where applicable
- **Tuning guidance** (conditional access policies, AAGUID restrictions, threshold recommendations)
- **False positive scenarios** and how to distinguish them

---

## Composition strategies

The `composition` block models how signals relate to each other:

| Strategy | When to use |
|---|---|
| `Independent` | Each signal fires alone; no correlation needed. Most common. |
| `Synergetic` | Signals must combine for meaningful detection (e.g. credential spray + subsequent privilege escalation). |
| `Correlated` | Signals from different data sources must be correlated temporally. |

**Current gap**: Production corpora overwhelmingly use `Independent` with boilerplate descriptions. When authoring DOMs for multi-stage attacks, actively consider whether `Synergetic` or `Correlated` strategies would produce better detection outcomes.

---

## Linking DOMs to TVMs and MDRs

### Upstream: DOM -> TVM

- `objective.threats[]` contains TVM UUIDs.
- A single DOM can cover **many TVMs** (credential dumping DOM links to 14 TVMs).
- ATT&CK techniques are **inherited from TVMs** unless `objective.att&ck` explicitly overrides.

### Downstream: DOM -> MDR

- Signal UUIDs (`objective.signals[].uuid`) are referenced by MDR objects.
- The signal `description` serves as the **specification** that MDR detection rules implement.
- `detectors[]` and `examples[]` blocks bridge to existing vendor/community detections — populate these to accelerate MDR authoring.

### Type: Supportive

`type: Supportive` DOMs (e.g. "Risk Based Alerting Framework") have **no `threats` array**. They support detection infrastructure rather than covering specific threat vectors.

---

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| **Single-signal catch-all** | Decompose by detection surface, data dependency, methodology |
| **`availability: Unknown` everywhere** | Investigate data availability before authoring. `Unknown` defeats the purpose of data modelling. |
| **Boilerplate composition** | Think about whether signals should correlate. Don't copy-paste "Each signal triggers independently" without consideration. |
| **Wrong entity types** | Cloud-native detections should use `cloud::Authentication`, not `host::Process`. Match entities to the actual data domain. |
| **Empty `detectors` and `examples`** | Populate when vendor detections or community rules exist. Critical for coverage gap analysis. |
| **CDM migration artefacts** | Rethink migrated content for the DOM schema. Don't just paste old CDM text. |
| **Missing `effort` scores** | Populate the 1-10 scale. Investment planning depends on it. |
| **Description as unstructured prose** | Use the signal description as a technical spec, not a paragraph of prose. |
| **Overlapping DOM coverage** | Check existing DOMs before creating new ones. Update rather than duplicate. |

---

## Quality checklist

- [ ] `name` is a verb-noun phrase describing the detection goal.
- [ ] `objective.priority` aligns with TVM criticality.
- [ ] `objective.threats` lists all relevant TVM UUIDs (for `type: Threat`).
- [ ] Signals are decomposed by detection surface, data dependency, and methodology.
- [ ] Each signal `name` reads as an alert title an analyst would see.
- [ ] Each signal `description` includes specific log fields, Event IDs, tuning guidance.
- [ ] Each signal `severity` matches expected alert severity.
- [ ] `data.availability` is honestly assessed (not defaulting to `Unknown`).
- [ ] `data.requirements` separates data collection from data sources.
- [ ] `entities` include all entity types the signal correlates on.
- [ ] `detectors` and `examples` populated when vendor/community detections exist.
- [ ] `effort` score populated (1-10).
- [ ] `composition.strategy` is deliberate (not boilerplate `Independent`).
- [ ] No CDM migration artefacts remain.

---

## Collaboration with neighbouring skills

- Upstream **`opentide-threat-vector`** for threat fidelity.
- Downstream **`opentide-detection-rule`** for executable bodies.
- **`mitre-attack`** for ATT&CK technique precision.
- **Platform/query skills** validate technical feasibility (`kusto-query-language`, `splunk-spl-processing`, etc.) according to tooling each signal references.
- **`windows-event-logs`** for Event ID prerequisites and audit policy requirements.
- **`entra-id`** for identity-layer signal design.
