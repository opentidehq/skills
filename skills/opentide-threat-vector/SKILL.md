---
name: opentide-threat-vector
description: Structures threat intelligence into evidence-backed behavioural atoms and authors OpenTide Threat Vector (TVM) YAML (tvm schemas), including metadata, terrain, chaining, ATT&CK, UUIDs. Covers Phase A intelligence structuring (source hygiene, atomisation, gap analysis) and Phase B schema-backed YAML authoring (field-level guidance, quality patterns, anti-patterns distilled from production corpora). Use whenever work involves converting CTI into TVMs, creating or refactoring files under Threat Vectors, or when the user provides reports, feeds, or narratives before detection objectives exist.
---

# OpenTide Threat Vector (TVM)

## Why one skill handles both "intel" and "YAML"

Splitting "TI analysis" and "TVM authoring" into sibling skills creates ambiguous triggers. Threat Vector work is fundamentally **intel -> structured hypothesis -> validated TVM YAML** — keep upstream triage inside this skill under **Phase A**, then transition to **Phase B**. One deliverable lineage from signal intake to `tvm::` artefacts.

---

## Phase A — Intelligence structuring

Skip or shorten Phase A only when the user already has a definitive TVM brief or edits to an existing file.

### Workflow

1. **Source hygiene** — Producer, publication date, TLP/risk markings. Treat rumours and unsourced summaries as lowest trust.
2. **Facts versus inference** — Quote or summarise only substantiated statements; label guesses explicitly.
3. **Atomisation** — Split composite reporting into observable procedures (installer ran, DLL loaded, C2 beacon, credential access, persistence). One primary behaviour candidate per bullet for TVM scoping.
4. **ATT&CK mapping** — Map only where behaviour is clear; annotate low-confidence mappings. Use sub-techniques when the specific implementation is documented. See `mitre-attack` skill.
5. **Gap checklist** — What is unknown (privilege achieved, tooling version, infra). Open questions block careless TVMs.
6. **Source credibility assessment** — Vendor reports (high), OSINT (medium), CTI feeds (variable), rumour mill (lowest). Rate explicitly.
7. **IOC hygiene** — Expiration dates, TLP markings, attribution caveats. IOCs without provenance are noise.

### Structured hand-off

```markdown
## Intelligence summary
[Brief factual summary, British English]

## Atomised behaviours
| # | Observable | Evidence cite | ATT&CK | Confidence |
|---|-------------|---------------|---------|-------------|
| 1 | ... | ... | ... | high/med/low |

## Gaps before modelling
- ...
```

Guardrails: no fabrication of sightings, IOCs, or attribution beyond the evidence supplied.

---

## Phase B — TVM YAML authoring

### Preconditions

1. Load live **`Schemas/Templates`** for TVM and the tenant's tvm schema revision (e.g. `tvm::2.1` — always check the live template for the current version).
2. Confirm **`Objects/Threat Vectors/`** conventions in the corpus you edit.

### Complete field reference

#### Top-level (all required)

| Field | Type | Notes |
|---|---|---|
| `name` | string | Sentence-case, action-oriented. Describe what the adversary does. Good: "Mamba 2FA phishing kit". Bad: "T1566". **Filename:** dash-case slug from `name` (e.g. `mamba-2fa-phishing-kit.yaml`); doc paths use the same `slugify()` rules. |
| `criticality` | enum | 7 levels: `Baseline - Negligible` through `Emergency`. Derive from severity + impact + sophistication. |
| `references` | object | `public` (numbered keys `1:`, `2:`), `internal` (alpha keys `a:`, `b:`). Add `# inline comments` for context. |
| `metadata` | object | See below. |
| `threat` | object | All technical threat content. |

#### `metadata` fields

| Field | Required | Notes |
|---|---|---|
| `uuid` | Yes | Fresh UUIDv4 for every new TVM. Never reuse. |
| `schema` | Yes | e.g. `tvm::2.1` — always verify against the live template. |
| `version` | Yes | Start at `1`, increment on each revision. |
| `created` / `modified` | Yes | `YYYY-MM-DD` format. |
| `tlp` | Yes | Lowercase: `clear`, `green`, `amber`, `amber+strict`, `red`. |
| `author` | Recommended | Email address. |
| `contributors` | Optional | Array of email addresses. |
| `organisation` | Required in 2.1 | `uuid` + `name` sub-fields. |

#### `threat` fields

| Field | Required | Guidance |
|---|---|---|
| `actors` | Recommended | Use `att&ck::G####` or `misp::UUID` format. Add `# alias list` comment. Include `sighting` narrative + `references` array when evidence exists. |
| `killchain` | Optional | Align with ATT&CK tactic names or Unified Kill Chain phases. |
| `att&ck` | Yes (practice) | Sub-techniques when specific. Always add `# Technique Name` comment. 1-5 techniques typical. Don't mix Enterprise and ICS matrices. |
| `chaining` | Recommended | See chaining section below. |
| `cve` | When applicable | Array of CVE identifiers. |
| `misp` | When applicable | Array of MISP event UUIDs with `# comments`. |
| `surface` | Yes (practice) | Hierarchical `Category::Subcategory::Detail` from controlled vocabulary. Be specific: `OS::Windows::Desktop` not just `OS::Windows`. |
| `terrain` | Yes (practice) | **Preconditions only.** See terrain section below. |
| `severity` | Yes (practice) | Exact enum: `Localised incident` through `National cyber emergency`. |
| `leverage` | Yes (practice) | 2-4 values from the 20-value vocabulary. Don't shotgun. |
| `impact` | Yes (practice) | 2-4 values from the 19-value vocabulary. Don't shotgun. |
| `viability` | Yes (practice) | Exact enum: `Almost no chance` through `Almost certain`, plus `Environment dependent`. |
| `description` | Yes (practice) | YAML `\|` block scalar. Use `##` markdown headings for structure. Reference sources with `ref [1]` notation. |

**Deprecated fields** (do not use): `threat.domains`, `threat.targets`, `threat.platforms` — replaced by `surface`.

---

### Terrain — the most misunderstood field

Terrain answers: **"What environmental conditions, access levels, or configurations must exist for this threat to be realised?"**

It is NOT a description of the attack. It is NOT a summary of the intelligence.

#### Quality spectrum

| Quality | Example | Why |
|---|---|---|
| **Excellent** | "Attackers need to have gained administrative privileges in the organization's network, and with access to the AD FS server itself. The target services need to trust the federation." | Specifies: required privilege, access target, trust relationship |
| **Good** | "Application with SSO login requiring MFA, with legacy authentication (local login) not disabled." | Specifies: configuration state, specific misconfiguration |
| **Good** | "Affected version: Apache Log4j2 2.0-beta9 through 2.15.0. Excluding security releases: 2.12.2, 2.12.3, and 2.3.1" | Specifies: exact version range with exclusions |
| **Mediocre** | "A threat actor needs initial access to move laterally through the network." | Too generic — what kind of access? What network? |
| **Bad** | "attacker needs to entice users to download payload and to open it." | Restates the attack, not preconditions |

#### Terrain authoring rules

1. State **privilege level** required (admin, user, unauthenticated, specific role)
2. State **access scope** (network segment, specific server, cloud tenant, internet-facing)
3. State **configuration prerequisites** (feature enabled, policy misconfigured, version range)
4. State **trust relationships** that must exist (federation, SSO, delegation, certificate chain)
5. 1-4 sentences. Concise. Do NOT restate the description.

---

### Chaining — linking TVMs

Chaining models relationships between TVMs using a controlled vocabulary:

| Category | Relation | Meaning |
|---|---|---|
| **sequence** | `sequence::preceeds` | Target TVM occurs AFTER this TVM |
| **sequence** | `sequence::succeeds` | Target TVM occurs BEFORE this TVM |
| **atomicity** | `atomicity::implements` | This TVM is a specific implementation of the target |
| **atomicity** | `atomicity::implemented` | Target TVM is a specific implementation of this TVM |
| **support** | `support::enabling` | Target TVM enables this TVM |
| **support** | `support::enabled` | This TVM enables the target |
| **support** | `support::synergize` | Bidirectional support |

#### Chaining rules

1. The `vector` field contains the **UUID** of the target TVM, always annotated with `# TVM Name`.
2. Include a `description` narrative explaining the relationship.
3. Verify the target TVM exists in the corpus before adding a chain.
4. Multiple chains per TVM are normal (2-3 typical for complex threats).

```yaml
chaining:
  - relation: sequence::succeeds
    vector: 1a68b5eb-0112-424d-a21f-88dda0b6b8df #Spearphishing Link
    description: |
      Phishing emails were sent to victims using an invite to a dinner
      reception bearing a logo from the CDU...
  - relation: atomicity::implements
    vector: 4a807ac4-xxxx-xxxx-xxxx-xxxxxxxxxxxx #MFA Bypass Techniques
    description: |
      This phishing kit is a specific implementation of MFA bypass
      using adversary-in-the-middle session proxying.
```

---

### Description — structured prose

Use YAML `|` block scalar with markdown headings for longer descriptions:

```yaml
description: |
  ## Attack Flow
  The adversary sends spearphishing emails containing...

  ## Impact
  Successful exploitation grants...

  ## Evasion Techniques
  The kit employs...

  ## References
  See ref [1] for the original analysis and ref [2, 3] for
  related campaign reporting.
```

Cross-reference sources using `ref [1]`, `ref [a]`, `ref [2, 3]` notation matching the `references` block.

---

### Actor attribution

```yaml
actors:
  - name: att&ck::G0016 #[Enterprise] APT29, Blue Kitsune, Cozy Bear, The Dukes
  - name: misp::2ee5ed7a-c4d0-40be-a837-20817474a15b #UNC2452, DarkHalo
    sighting: |
      APT29 added credentials to OAuth Applications and Service Principals
      to maintain persistent access to compromised tenants.
    references:
      - https://www.crowdstrike.com/blog/observations-from-the-stellarparticle-campaign/
```

- Use both `att&ck::G####` and `misp::UUID` when available.
- Always add `# alias list` comment.
- Include `sighting` + `references` when specific evidence exists.

---

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| **Terrain restates description** | Terrain = preconditions; Description = what the attack does |
| **Unbounded ATT&CK mapping** (7+ techniques) | Map only techniques with clear behavioural evidence; 1-5 typical |
| **Mixed ATT&CK matrices** (Enterprise + ICS) | Separate Enterprise and ICS technique lists |
| **Dangling chaining UUIDs** | Verify target TVM exists before adding chain |
| **Commented-out template boilerplate** | Remove unused scaffolding; only comment fields you intend to populate |
| **Shotgunning leverage/impact values** | Pick 2-4 directly applicable values, not every tangential one |
| **Missing actors when known** | Always populate actors when threat groups are documented |
| **Missing chaining for obvious sequences** | Discovery TVMs should chain to privilege escalation; initial access to execution |
| **Vague one-line terrain** | Specify privilege, access scope, configuration, trust relationships |
| **Spelling/grammar errors** | Proofread — errors erode trust in the analytical product |
| **Stale schema version** | Always check the live template for the current schema version |

---

## Quality checklist

- [ ] `name` is sentence-case, action-oriented, describes the adversary behaviour.
- [ ] `criticality` is calibrated against severity + impact + sophistication.
- [ ] `metadata.schema` matches the current live template version, with `organisation` block populated.
- [ ] `metadata.uuid` is a fresh UUIDv4 (not reused from another TVM).
- [ ] `terrain` states preconditions (privilege, access, config, trust) — not a description restatement.
- [ ] `description` uses `|` block scalar with `##` headings for structure.
- [ ] `description` cross-references sources with `ref [N]` notation.
- [ ] `att&ck` uses sub-techniques when specific, with `# Technique Name` comments. 1-5 entries.
- [ ] `actors` populated with `att&ck::G####` or `misp::UUID` format when known.
- [ ] `surface` uses `Category::Subcategory::Detail` hierarchical notation.
- [ ] `leverage` and `impact` have 2-4 directly applicable values (not shotgunned).
- [ ] `chaining` references verified UUIDs with `# TVM Name` comments and `description` narratives.
- [ ] No commented-out template boilerplate remains.
- [ ] No spelling/grammar errors.
- [ ] References include at least 1 public source.

---

## Interaction with sibling skills

| Next step after TVM | Skill |
|---------------------|-------|
| Map ATT&CK techniques precisely | `mitre-attack` |
| Define detection intent / signals | `opentide-detection-objective` |
| Implement deployable artefacts | `opentide-detection-rule` + platform skills |

Never edit schemas, Templates, or engine configuration files unless explicitly directed.
