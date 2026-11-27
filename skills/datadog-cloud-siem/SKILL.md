---
name: datadog-cloud-siem
description: >-
  Datadog Cloud SIEM detection engineering for opentide: real-time log detection rules as
  configurations.datadog blocks (queries, detection, cases, signal), the threshold, new value, anomaly
  and impossible travel methods, the case condition grammar and its undocumented precedence, the
  Datadog log search syntax and its silent traps (AND binds tighter than OR, lower-case and, curly
  quotes, wildcards inside quotes, the exclusion dash, @attributes versus bare tags), the engine's rule
  and search profiles, and how opentide deploys through the v2 Security Monitoring API (validation
  before every write, unchanged rules not sent, default rules never touched, PREVIEW without
  notifications), validate query --live through rules/validation and Logs Search, and opentide query.
  Use when authoring or reviewing Datadog-keyed detection rules, system datadog hunts or .datadog
  files, or translating a detection from KQL, SPL or Exabeam to Datadog.
---

# Datadog Cloud SIEM: detection rules

This skill carries the operational context for `configurations.datadog` blocks in opentide detection
rules (`platform::datadog::1.0`), and for hunts with `system: datadog`. One block is one Datadog
Cloud SIEM **real-time log detection rule** (`log_detection`), deployed through the v2 Security
Monitoring API. Its queries are written in the **Datadog log search syntax** (language id `datadog`,
file suffix `.datadog`).

> **Pair with**: `opentide-rule` (the rule object, description, response), `detection-engineering`
> (hunt-to-rule lifecycle), `amazon-web-services`, `okta-identity` and the other telemetry skills
> (what the logs mean), `mitre-attack` (technique mapping).

> **The platform is new.** `datadog` is opentide's fourteenth platform. Its contract is still the
> RFC (`docs/internal/rfc-datadog-cloud-siem.md` in opentide) until the specification
> `specs/platforms/datadog-1.0.md` is drafted from tenant probes. Facts marked **(unverified)** below
> are ones the RFC could not settle from public sources: do not present them as Datadog behaviour.
> opentide 1.1.0 and earlier do not know the platform; confirm with `opentide --json info`.

---

## 1. Surface identification

| Surface | What it is | Managed by opentide? |
|---|---|---|
| **Real-time log detection rule** | Queries over incoming logs (or audit, events, signals), a detection method, cases | **Yes**: a `datadog` block. Methods `threshold`, `new_value`, `anomaly`, `impossible_travel` |
| **Sequence rule** (steps and transitions) | Cross-rule correlation over signals | No: waits for `datadog-1.x`. `method: sequence` is `datadog_method_unsupported` |
| **Signal correlation rule** | The older cross-rule correlation | No. Datadog no longer accepts new ones (a 403, per the Terraform provider's tests) |
| **Default rules** | Rules Datadog ships and maintains (`isDefault: true`) | No. opentide never changes or deletes one (`datadog_rule_default`); tuning one is a later version |
| **Suppression rules, security filters** | Tenant-side exclusions | No: console or Terraform |
| **Rule tests, backtests** | `POST /rules/test`, historical jobs | No |
| **Scheduled rules**, content anomaly, third-party, reference tables | Other rule forms | No: later versions |
| **Workload Protection** (SECL Agent rules), DDSQL queries | Other languages | No: out of scope |
| **Notification rules** | Org-wide routing of signals by severity, tags or rule | No, but they matter: they route signals whatever a rule's own `notify` says (section 7) |
| **Logs Search** | Interactive log search | Read-only: `opentide query --platform datadog`, hunts in `response.procedure.searches`, and the live check of searches |

Decide first whether the intent is a **rule** (a block; its queries are checked under the `rule`
profile) or a **search** (a hunt or a `.datadog` file; the `search` profile). Cross-rule
correlation is not expressible in 1.0 beyond a query `from: signals` (section 4); which signal
attribute names the rule that raised a signal is **(unverified)**.

---

## 2. Resolve the structure from the engine, not from this skill

Do not author the block from memory, and do not treat the tables here as the schema. The keys, the
allowed values and the constraint codes ship with the installed opentide and move with it.

1. **Block keys**: `opentide://schemas/rule` (MCP; the `configurations.datadog` sub-schema), else
   `.opentide/schemas/` for the rule's `metadata.schema`, else `opentide generate schemas`.
   `opentide new rule --name "…" --platform datadog --objective <uuid>` starts a file from the
   template.
2. **Capability**: `opentide --json info --platform datadog` or `opentide://platforms`. Datadog
   deploys, validates live, checks offline and runs `opentide query`.
3. **Attributes**: the engine's catalogue holds Datadog's reserved attributes (searched bare: `host`,
   `device`, `source`, `status`, `service`, `trace_id`, `message`, `env`, `version`) and its standard
   attributes (searched as `@<name>`). Use editor hover and completion (`opentide lsp start`, or
   `opentide tui`). The catalogue never makes a finding, because a team's pipelines remap
   attributes: an unknown `@attribute` passes silently, so confirm it against real logs.
4. **Any finding code**: `opentide explain <code>` (every `datadog_*` code has a page).

What follows is what the schema does not tell you: what each concept means on Datadog, and what
separates a rule that works from one that only validates.

---

## 3. The block: four groups

opentide groups the rule by meaning, not by the API's layout:

| Group | Question it answers | Holds |
|---|---|---|
| `queries` | What to look at | One or more searches, each with a name, a source and a measure |
| `detection` | How the queries become a match | The method, the evaluation window, the method's learning settings |
| `cases` | When a match becomes a signal | Conditions over query names, in order, each with a severity and notification targets |
| `signal` | What happens to the signal | Grouping, how long it stays open, the non-production downgrade, the notification title |

Plus `message` (Markdown with Datadog template variables), `tags`, and the shared block keys
(`schema`, `status`, `enabled`, `name`, `flags`, `tenants`, `contributors`). `type` is always
`log_detection` and is not written.

### The smallest block

```yaml
configurations:
  datadog:
    schema: platform::datadog::1.0
    status: PRODUCTION
    queries:
      - query: source:cloudtrail @evt.name:ConsoleLogin @evt.outcome:Failure
    cases:
      - condition: a > 5
```

Defaults fill the rest: method `threshold`, window `5m`, the query named `a` and counting events,
the case severity from `response.alert_severity` (else `info`), `keep_alive` `1h`, `max_duration`
`1d`, no signal grouping.

### A complete threshold block

From opentide's fixtures (the RFC's complete block):

```yaml
configurations:
  datadog:
    schema: platform::datadog::1.0
    enabled: true
    status: PRODUCTION
    queries:
      - name: failed
        query: source:okta @evt.name:user.session.start @evt.outcome:FAILURE
        from: logs
        group_by: ["@usr.email"]
      - name: success
        query: source:okta @evt.name:user.session.start @evt.outcome:SUCCESS
        group_by: ["@usr.email"]
    detection:
      method: threshold
      window: 5m                     # the cases are tested over the last 5 minutes
    cases:
      - name: brute force then success
        condition: failed > 10 && success > 0
        severity: high               # default: response.alert_severity
        notify: [soc]                # tenant aliases or raw @handles
    signal:
      group_by: ["@usr.email"]       # one signal per user
      keep_alive: 1h                 # open while matches keep arriving within an hour
      max_duration: 1d               # closed a day after the first match regardless
      downgrade_non_production: true # one level lower when env starts with staging, test or dev
      group_in_notification_title: true
    message: |
      {{@usr.email}} failed to log in {{events_matched_per_query.failed}} times, then succeeded.
    tags: ["team:identity"]
```

The condition compares **counts within the window**: nothing in it orders the two queries' events.
"Failures, then a success" here means "both in the same five minutes"; the RFC's ordered form waits
for sequence rules.

### `queries[]`

- `name`: `[a-z][a-z0-9_]*`, unique in the block. Unnamed queries are `a`, `b`, … by position, so a
  query named `a` after an unnamed first query clashes (`datadog_query_name`). A `new_value` query
  takes **no** name.
- `query`: Datadog search syntax under the `rule` profile (section 5), a plain scalar or a `|`
  block. Start it with `source:<integration>`: deploy derives the rule's `source:` tags from it.
- `from`: `logs` (default), `audit`, `events` or `signals`.
- `group_by`: field paths; matches are counted per distinct combination. `keep_missing_groups: true`
  keeps an event that lacks a value (grouped as `N/A`) instead of dropping it.
- **One measure at most** (`datadog_measure`): none counts events; `count_distinct: "@field"` counts
  distinct values; `sum` and `max` take one numeric field; `new_value` lists one to five fields and
  only goes with `method: new_value` (where every query sets it). An `impossible_travel` query takes
  no measure: opentide sends Datadog's `geo_data` on `@network.client.geoip` itself.
- The maximum number of queries per rule is **(unverified)**; the schema caps it.

### `detection` and the methods

`window` (the evaluation window) takes `0`, `1m`, `5m`, `10m`, `15m`, `30m`, `1h`, `2h`, `3h`, `6h`,
`12h` or `1d`, nothing else (`datadog_duration`). It may not exceed `signal.keep_alive` or
`signal.max_duration` (`datadog_window_order`): a `2h` window needs a longer `keep_alive` than the
`1h` default. A key the method does not take is `datadog_detection_option`.

| Method | Takes | Notes |
|---|---|---|
| `threshold` (default) | `window` | Cases need a condition; `<`, `<=`, `>`, `>=` |
| `new_value` | `learning` (`0d`–`30d`, default `1d`), `forget_after` (`1d`–`30d`, **required**) | Fires on a value of the `new_value` fields unseen while learning. `learning: 0d` alerts on every new value after the first is learned. Cases need no condition |
| `anomaly` | `learning` (`1h`, `6h`, `12h`, `1d`, `2d`, `7d`, `14d`), `bucket` (`5m`, `10m`, `15m`, `30m`, `1h`, `3h`), `tolerance` (1–5) | The condition's number is a **percentile in (0, 1)**: `denied > 0.995` fires when the count beats 99.5% of past periods |
| `impossible_travel` | `learning` (`1d`–`30d`: a per-user location baseline), `detect_ip_transitions` | Cases need no condition. May set neither key, as Datadog's own client example does |

What Datadog does when `bucket`, `learning` or `tolerance` is left out under `anomaly` is
**(unverified)**: opentide sends only what the block writes, so Datadog's own default applies. Set
them explicitly when the behaviour matters. The exact effect of `detect_ip_transitions` is
**(unverified)**. The editor's other new value learning options ("for all new values", "after the
first seen value") are not mapped in 1.0.

```yaml
    # New value: a user logs in from a country not seen for them in the last 30 days.
    queries:
      - query: source:okta @evt.name:user.session.start @evt.outcome:SUCCESS
        group_by: ["@usr.email"]
        new_value: ["@network.client.geoip.country.name"]
    detection:
      method: new_value
      learning: 7d
      forget_after: 30d
    cases:
      - severity: medium

    # Anomaly: more denied API calls than 99.5% of this role's past periods.
    queries:
      - name: denied
        query: source:cloudtrail @error.kind:AccessDenied
        group_by: ["@userIdentity.arn"]
    detection:
      method: anomaly
      window: 15m
      bucket: 15m
      learning: 7d
    cases:
      - condition: denied > 0.995

    # Distinct values: many users fail to log in from one address.
    queries:
      - name: failures
        query: source:okta @evt.outcome:FAILURE
        group_by: ["@network.client.ip"]
        count_distinct: "@usr.email"
    detection:
      window: 10m
    cases:
      - condition: failures > 20
```

### `cases[]`

Cases are tested **in order**; the first that matches creates or updates the signal. Put the most
severe case first.

- `condition`: section 4. Required with `threshold` and `anomaly`.
- `severity`: `info`, `low`, `medium`, `high` or `critical`, lower case (`datadog_severity`).
  Default: `response.alert_severity` mapped (Informational → `info` … Critical → `critical`), else
  `info`.
- `notify`: an entry starting with `@` is a Datadog handle sent as written; any other is an alias
  the tenant's `[tenants.setup.notifications]` maps to a handle. An alias the tenant lacks is
  `datadog_notification_alias` at deploy, `--dry-run` and `--live`. Dropped under `PREVIEW`.

### `signal`

- `group_by`: matches with the same values update one signal. Each field must be in some query's
  `group_by` (`datadog_signal_group_by`); the exact subset rule Datadog applies is **(unverified)**.
  Unset means no signal grouping.
- `keep_alive` (default `1h`): the signal stays open while a case matches again within this time.
- `max_duration` (default `1d`): the signal closes this long after its first match, whatever still
  matches.
- `downgrade_non_production`: one severity lower when the `env` tag starts with `staging`, `test` or
  `dev`.
- `group_in_notification_title`: notifications put the group-by values in their title.

### `message` and `tags`

- **Message**: left out, opentide derives `## Goal` (from `description`), `## Strategy` (the queries
  and cases, in words) and `## Triage and response` (from `response.procedure`), with any `{{` in
  the rule's text escaped. A hand-written `message` takes Datadog template variables
  (`{{@usr.email}}`, `{{events_matched_per_query.<query>}}`); check each against Datadog's
  notification-variables page.
- **Tags**: deploy adds lower-case `source:<x>` for each source the queries name, `tactic:` and
  `technique:` tags from the rule's ATT&CK techniques (a sub-technique as its parent),
  `security:attack`, `opentide_uuid:<uuid>`, and the tenant's `tags`. A block tag must already be
  valid: lower case, starting with a letter, only `a-z0-9_-:./`, at most 200 characters
  (`datadog_tag`), because Datadog would rewrite it and the rule would drift. `opentide_uuid` is
  advisory: only the deployment-state shard proves a rule is opentide's.

---

## 4. The case condition grammar

```text
condition  = or_expr
or_expr    = and_expr ( "||" and_expr )*
and_expr   = comparison ( "&&" comparison )*
comparison = query_name ( ">" | ">=" | "<" | "<=" ) number
```

Traps, each `datadog_condition` unless noted:

- **The query name comes first.** `failed > 3`, never `3 < failed`.
- **Name a query the block has**, by its explicit name or its positional `a`, `b`, ….
- **`<` and `<=` are documented for threshold rules only.**
- **Under `anomaly`, the number is in (0, 1)**: `a > 5` is refused.
- **Parentheses and `==` are not documented**; do not write them.
- **`&&` with `||` in one condition is `datadog_condition_mixed`** (a warning): Datadog documents
  both but not which binds tighter. Split into two cases, which Datadog tests in order, or keep to
  one operator.
- The condition is **not** the search syntax: `&&` and `||` belong here, `AND` and `OR` in queries.

---

## 5. Datadog search syntax: idioms and silent traps

A query is a filter: terms and `field:value` clauses joined by `AND`, `OR`, `NOT`, `-` and
parentheses. Datadog publishes no grammar; opentide's engine is written from Datadog's Log Search
Syntax page and held to the queries Datadog itself publishes and to VRL's grammar (Observability
Pipelines).

| Intent | Write | Not |
|---|---|---|
| Attribute | `@evt.outcome:FAILURE`, `@usr.email:alice@example.com` | `evt.outcome:FAILURE` (a dotted bare key searches a **tag**: `datadog_unknown_attribute`, a hint) |
| Tag or reserved attribute | `source:okta`, `service:web`, `env:prod` | `@source:okta` |
| Phrase | `@evt.name:"Console Login"` (straight quotes) | `“Console Login”` (`datadog_curly_quote`: the words are searched separately) |
| One of several | `@evt.name:(ConsoleLogin OR AssumeRole)` | `@evt.name IN (…)`; `@a:(x OR y or z)` (`datadog_lowercase_operator`) |
| Exclude | `-@usr.email:svc_backup*`, `NOT @level:debug`, `-(…)` | `- @level:debug` (`datadog_detached_operator`); `@level != debug` |
| Contains / wildcard | `@http.url:*wp-admin*`; `*` within a word, `**` across words, `?` one character, `\ ` joins words | `"*wp-admin*"` (`datadog_wildcard_in_phrase`: inside quotes `*` is punctuation) |
| Exists / absent | `@usr.email:*`, `-@usr.email:*` | `_exists_:usr.email` (`datadog_pipelines_only`) |
| Number | `@http.status_code:>=400`, `@duration:>=100ms`, `@http.status_code:[400 TO 499]` | `[400 to 499]` (`datadog_range`: `TO` upper case); `[1 TO 5}` (mixed bounds, a warning) |
| Network | `CIDR(@network.client.ip, 10.0.0.0/8, fc00::/7)` | `CIDR(network.client.ip, …)` or a bad block (`datadog_cidr`) |
| Special characters | Escape with `\`: `@x:\-1`, `foo\!bar`, `@usr.id:system\:serviceaccount\:x` | `@x:-1` (an exclusion: `datadog_unescaped_special`); an unescaped `:` in a value (`datadog_unescaped_colon`) |
| Regular expression | Wildcards | `foo~2`, `foo^2` (`datadog_regex`); `/…/` is ordinary text, not a regex |

The traps that change what a rule matches **without an error** from Datadog:

- **AND binds tighter than OR, and a space is AND.** `service:x status:error OR warning` reads as
  `(service:x status:error) OR warning`: any log with the word `warning` matches. The same inside
  a value group: `@f:(*.exe OR *.rar *.7z)`. Parenthesise every mix (`datadog_mixed_boolean`). This
  precedence is VRL's, **(unverified)** on Cloud SIEM; the warning says so.
- **Operators are upper case only.** A lower-case `and`, `or`, `not` between field clauses is a
  free-text term ANDed in (`datadog_lowercase_operator`). Between free-text words it is just a
  word and is not reported.
- **`&&` and `||` in a query** are characters Datadog's docs say to escape; the engine reads them as
  AND and OR, as VRL does, and warns (`datadog_symbol_operator`). Write `AND` and `OR`.
- **Curly quotes are not quotes**, and **`*` inside quotes is not a wildcard**.
- **`-` exclusion is written against what it excludes**; a value starting with `-` must be escaped.
- **Bare dotted keys are tags.** `@` is what makes a path an attribute.
- **Case.** Operators and attribute values are case-sensitive; free-text search is not. Free text
  searches only `message`, `@title`, `@error.message` and `@error.stack`.

### Profiles: `rule` versus `search`

| Profile | Applies to | Difference |
|---|---|---|
| `rule` | `configurations.datadog.queries[].query`; MCP `analyze_query` with `platform: datadog` | Full-text `*:term` is `datadog_full_text_in_rule` (Datadog documents it for monitors, dashboards and notebooks, not detection rules); a calculated field `#name` is `datadog_calculated_field_in_rule` (real-time rules have none). Both warnings. `*:*` is fine |
| `search` | `.datadog` files, `system: datadog` hunts, `opentide query` | Everything the syntax allows |

Fix `*:mimikatz` in a rule by naming the attribute the term is in (`@<attribute>:*mimikatz*`, the
attribute confirmed against real logs), and `#duration_ms:>500` by using the attribute it is computed from.
What Datadog does with `*:term`, `_exists_:`, open or mixed range bounds, an unescaped `:` or a space
after `:` inside a rule query is **(unverified)**: treat each warning as a defect.

### Where the findings appear

`opentide validate` and `opentide validate query --platform datadog` (offline) report the block's
constraint errors and the query errors. The engine's warnings and hints (`datadog_mixed_boolean`,
`datadog_lowercase_operator`, …) and `datadog_condition_mixed` appear in `opentide lint` (its
`queries` check) and in the editor. A query that does not parse gets its first syntax error only.

---

## 6. Tenant setup

`opentide setup platforms --datadog` writes `.opentide/configurations/platforms/datadog.toml`:

```toml
[[tenants]]
name = "datadog-eu"
strategies = ["RELEASE", "PREVIEW"]
[tenants.setup]
site = "datadoghq.eu"
api_key = "$DD_API_KEY"
app_key = "$DD_APP_KEY"
tags = ["managed-by:opentide"]
[tenants.setup.notifications]
soc = "@slack-soc-alerts"
```

- `site` is one of `datadoghq.com`, `us3.datadoghq.com`, `us5.datadoghq.com`, `datadoghq.eu`,
  `ap1.datadoghq.com`, `ap2.datadoghq.com`, `uk1.datadoghq.com`, `ddog-gov.com`, `us2.ddog-gov.com`;
  calls go to `https://api.<site>`. `api_url` replaces that base (a new site, a proxy). Anything
  else, such as `app.datadoghq.eu`, is `datadog_site`.
- `api_key` and `app_key` are `$NAME` placeholders, never literal keys. They are sent as `DD-API-KEY`
  and `DD-APPLICATION-KEY`.
- Use a service account's application key scoped to `security_monitoring_rules_read` and
  `security_monitoring_rules_write` (validation needs write), plus `logs_read_data` for
  `opentide query` and for checking searches live. A key that can validate can also delete.
- `notifications` maps the aliases a case's `notify` names; `tags` are added to every rule.
- `opentide doctor --live` makes one read-only request (`GET` one detection rule).

---

## 7. How opentide deploys

The block's `status` maps to a strategy through `deployment.toml`, as on every platform:

| Strategy | What deploy does on Datadog |
|---|---|
| `INERT` | Nothing |
| `PREVIEW` | Creates or updates the rule **enabled, with no notifications on its cases**, tagged `opentide_strategy:preview` |
| `RELEASE`, `UNIVERSAL` | Creates or updates the rule enabled, with its notifications |
| `DISABLEMENT` | Sets `isEnabled: false`; the rule and its history stay |
| `DELETION` | Deletes the rule. Never a default rule, never a rule whose id it does not hold |

The lifecycle:

1. **Validation first.** Every create and update is first sent to
   `POST /security_monitoring/rules/validation`; a `400` is `datadog_rule_invalid` with Datadog's
   `errors[]`, and nothing changes.
2. **Create** (no id in `.opentide/states/deployment/`): `POST /security_monitoring/rules`, and the
   returned id is recorded in the rule's shard. Deploy **never lists rules or finds one by name**:
   commit the shard, or the next run creates a duplicate. A create that gets no answer or a `5xx`
   is never resent (`datadog_create_unconfirmed`): look for the rule by name or by the tag
   `opentide_uuid:<uuid>` before deploying again.
3. **Update** (id recorded): `GET` the rule, then `PUT` only if a property opentide writes differs
   from the compiled body (`name`, `isEnabled`, `queries`, `cases`, `options`, `message`, `tags` as a
   set, `groupSignalsBy`, `hasExtendedTitle`; defaults Datadog fills in are not differences). **An
   unchanged rule is sent nothing** (`unchanged`). The `PUT` carries the `version` the `GET` returned;
   Datadog's `401` to a stale version is `datadog_concurrent_modification`, not a refused key.
   A console edit to one of those properties is a difference, so the next deploy overwrites it.
4. **Default rules are never touched.** A recorded id whose rule is `isDefault: true` is refused
   before any write (`datadog_rule_default`): remove the id from the shard.
5. **A recorded rule that is gone** (`404` or `isDeleted`) is created again
   (`datadog_rule_recreated`), or forgotten under `DISABLEMENT` or `DELETION` (`datadog_rule_missing`).
6. **Rate limits.** A `429` is waited out for the seconds `X-RateLimit-Reset` gives, three resends at
   most, never for more than 120 seconds (`datadog_rate_limited`). A `403`, or a `401` that is not a
   stale version, is `datadog_tenant_unauthorized`; DNS, TLS or a timeout `datadog_tenant_unreachable`.

What `PREVIEW` means on Datadog, and what it does not:

- **Signals still appear.** Datadog has no mode that runs a rule without creating signals.
- **Notification rules still route signals.** They apply whatever a rule's own notifications say.
  Exclude `opentide_strategy:preview` from the organisation's notification rules, or a preview rule
  can page someone.
- **A CI preview run cannot create rules.** Datadog keeps ids in deployment state, so a CI run other
  than the production job refuses every create, recreations included
  (`deployment_state_unpersisted`), unless the pipeline commits the state itself
  (`--persist-state-externally`). Preview updates rules that already exist; new rules come from the
  production job or a deploy run outside CI.
- **Learning restarts on modification.** Datadog's docs say a modified rule's learning period
  restarts at day 0. Promotion from `PREVIEW` changes notifications and tags; whether a change to
  only those restarts a `new_value` or `impossible_travel` rule's learning is **(unverified)**.
  Plan the promotion of those methods knowing the baseline may start again as the rule goes live.

Taking over existing rules:

- **Terraform.** A rule managed by Terraform as well is changed back and forth on every run: remove
  it from Terraform's state before opentide takes it over.
- **Adopting a rule made in Datadog.** Write its block, then record its id under
  `platforms.datadog.<tenant>` in `.opentide/states/deployment/<uuid>.json` and commit it before the
  first deploy. Deploy never adopts by name. A default rule cannot be adopted.
- **Rule ids** are stored as Datadog returns them; their format is **(unverified)**, so none is
  enforced.

`opentide deploy --dry-run` shows the exact body per tenant, an alias as
`<tenant:notifications.ALIAS>` when no tenant is reached.

---

## 8. What each check catches

| Check | Command | Catches |
|---|---|---|
| Block constraints | `opentide validate` | `datadog_method_unsupported`, `datadog_duration`, `datadog_window_order`, `datadog_query_name`, `datadog_measure`, `datadog_detection_option`, `datadog_signal_group_by`, `datadog_condition`, `datadog_severity`, `datadog_tag` (each at its field path), and the warning `datadog_condition_mixed` |
| Offline engine | `opentide validate`, `validate query --platform datadog` for errors; `lint --check queries` and the editor for warnings and hints | Parse errors, unescaped specials, regex operators, `CIDR()` arguments, ranges; the silent traps of section 5 |
| Live, a block | `opentide validate query --platform datadog --live` | Each rule compiled per tenant (aliases resolved) and sent whole to `POST /security_monitoring/rules/validation`, which creates nothing. `2xx` passes; `400` is `datadog_rule_invalid` with each of Datadog's `errors[]`; a missing alias fails with `datadog_notification_alias` |
| Live, a search | the same, on a `.datadog` file or a `system: datadog` hunt | `POST /api/v2/logs/events/search` over the last minute with `page.limit: 1`; a `400` places Datadog's message on the query. Checked as a search, not wrapped in a rule. That Logs Search names the error in its `400` is **(unverified)** |

The offline engine is an approximation of a syntax Datadog publishes no grammar for: never report an
offline pass as Datadog's verdict. Run `--live` before `RELEASE` where credentials exist. MCP
`validate_query` takes `datadog`.

---

## 9. Hunting with `opentide query`

`opentide query --platform datadog` runs a **search** through Logs Search
(`POST /api/v2/logs/events/search`): read-only, paged by `meta.page.after` (at most 5,000 events a
page), `--limit` rows per tenant; `--index` names log indexes. `--rule <uuid>` or
`--file <path>` runs **each** of a block's `queries[].query` as its own result, labelled by its
query name, without the method, window or cases: a result is the events a query matches, not the
signals the rule would raise. Logs Search searches logs, so a query `from: audit`, `events` or
`signals` does not return the data the rule reads.

```yaml
response:
  procedure:
    searches:
      - system: datadog
        purpose: Failed Okta logins for one user, to pivot from the signal
        query: source:okta @evt.name:user.session.start @evt.outcome:FAILURE @usr.email:alice@example.com
```

A hunt is checked under the `search` profile, so `*:term` is allowed there.

---

## 10. Translating from other platforms

Map the **logic**, then the fields. Datadog attribute names depend on the team's pipelines; confirm
each with a search before relying on it.

| Source idiom | Datadog |
|---|---|
| KQL `where A and (B or C)`; SPL `A (B OR C)` | `A (B OR C)`: always parenthesise an OR |
| KQL `Field in ("a", "b")`; SPL `Field IN (a, b)`; Exabeam `field:("a", "b")` | `@field:(a OR b)` |
| KQL `Field != "x"`, `not(...)`; SPL `NOT Field=x`; Exabeam `AND NOT field:"x"` | `-@field:x` (no space after `-`) |
| KQL `contains`, `has`; SPL `*x*`; Exabeam `WLDi("*x*")` | `@field:*x*`. Attribute values are case-sensitive: there is no case-insensitive wildcard function |
| KQL `matches regex`; SPL `rex`, `regex`; Exabeam `RGX(…)` | No regex in the search syntax: approximate with wildcards and say so in the description, or keep the detection on a platform that has one |
| KQL `isnotempty(F)`; SPL `F=*` | `@f:*`; absent: `-@f:*` |
| KQL `ipv4_is_in_range`; SPL `cidrmatch` | `CIDR(@network.client.ip, 10.0.0.0/8)` |
| `summarize count() by user \| where count_ > 10`; `stats count by user \| where count > 10`; Exabeam `threshold: count more_than 10` with `group_by` | `group_by` on the query, `condition: a > 10`, `detection.window` |
| `dcount(x)`; `stats dc(x)`; Exabeam `unique_count` | `count_distinct: "@x"` |
| `sum`, `max` | `sum`, `max` on a numeric attribute; no average |
| Two filters joined on an entity in one window (KQL `join`, SPL `stats … by user` over two conditions) | Two queries with the same `group_by`, condition `a > 0 && b > 0`. **No order** between them in 1.0 |
| Exabeam ordered sequences, `correlation.within` | No ordered correlation in 1.0; sequence rules wait for 1.x |
| Exabeam `suppression`, Sentinel alert grouping | `signal.group_by`, `keep_alive`, `max_duration` merge matches into one signal; Datadog suppression rules are outside opentide |
| Lookback longer than a day | Not a threshold window (`1d` maximum). For "new for this entity", use `new_value` with `forget_after` |
| Exabeam context tables, Splunk lookups | Reference tables wait for 1.x; name the exclusion in the query or the description |
| `index=`, `sourcetype=`, a Sentinel table | `source:<integration>` first, then attributes |

Keep group-by entities equivalent across platforms (`@usr.email` with Sentinel's
`UserPrincipalName` or Exabeam's `user_upn`; `@network.client.ip` with `IPAddress` or `src_ip`) so
the hunt in `response.procedure.searches` lands on the signal's entity.

---

## 11. Anti-patterns

| Anti-pattern | Fix |
|---|---|
| `a OR b c`, or `service:x status:error OR warning` | Parenthesise: `a OR (b c)`, `status:(error OR warning)` |
| `and`, `or`, `&&` in a query | `AND`, `OR` |
| `"*mimikatz*"`, curly quotes from a document | `@<attribute>:*mimikatz*`; straight quotes |
| `evt.name:ConsoleLogin` | `@evt.name:ConsoleLogin` |
| `*:term` or `#calculated` in a rule query | Name the attribute |
| `3 < failed`; `failed > 1 \|\| ok > 1 && x > 1` | Name first; two cases or one operator |
| `condition: a > 5` under `anomaly` | A percentile: `a > 0.995` |
| Reading `failed > 10 && success > 0` as "failures, then success" | It is co-occurrence in the window; say so in the description |
| A `2h` window with the default `keep_alive` | Raise `keep_alive` and `max_duration` to at least the window |
| `new_value` without `forget_after` | Set it: there is no default |
| Upper-case or spaced tags (`Team:Identity`) | `team:identity` |
| Relying on `PREVIEW` to keep quiet | Exclude `opentide_strategy:preview` from notification rules |
| Expecting a CI preview run to create a new rule | The production job creates; preview updates |
| Recording a default rule's id to "manage" it | Not possible; write a rule of your own |
| The same rule in Terraform and opentide | One owner: remove it from Terraform's state |
| Resending after `datadog_create_unconfirmed` | Find the rule by name or `opentide_uuid` tag first |
| `.opentide/states/deployment/` not committed | Commit it; deploy never adopts by name |

---

## 12. Authoring checklist

- [ ] The behaviour fits a real-time log detection rule with one of the four methods (not a sequence, a suppression or a default-rule tune).
- [ ] Block keys checked against the resolved schema, not memory.
- [ ] Every query names `source:` and real `@attributes` (confirmed in Logs Search or the editor); no dotted bare keys.
- [ ] Every OR beside an AND parenthesised; operators upper case; no `&&`/`||` in queries; straight quotes; no wildcards inside quotes.
- [ ] No `*:term` or `#calculated` in rule queries.
- [ ] Query names valid and unique, or positional names used consistently; no name on a `new_value` query.
- [ ] One measure per query; `new_value` only with `method: new_value`, with `forget_after`.
- [ ] Window from the allowed values and no longer than `keep_alive` and `max_duration`.
- [ ] Conditions name first, one operator kind, a percentile under `anomaly`.
- [ ] Cases ordered most severe first; severities deliberate; `notify` aliases exist on every target tenant.
- [ ] `signal.group_by` fields appear in the queries' `group_by`.
- [ ] Block tags lower case and valid.
- [ ] Anomaly `bucket`, `learning`, `tolerance` written when the behaviour depends on them.
- [ ] `opentide validate` clean, and `opentide lint --check queries` warnings resolved or understood.
- [ ] `validate query --platform datadog --live` run before `RELEASE` where credentials exist.
- [ ] A `system: datadog` hunt in `response.procedure.searches` for analyst pivots.
- [ ] Notification rules exclude `opentide_strategy:preview` before the first `PREVIEW` deploy.
- [ ] `deploy --dry-run` reviewed; `.opentide/states/deployment/` committed after deploy.

---

## 13. When unsure

Datadog publishes no grammar for its search syntax and documents neither the condition precedence
nor several limits. Go to Datadog's pages under `docs.datadoghq.com`: `logs/explorer/search_syntax`,
`security/cloud_siem/detection_rules`, `standard-attributes`, `security/notifications/variables`, and
the v2 Security Monitoring API reference. `--live` (Datadog's own rule validation) outranks the
offline engine, and both outrank this skill. Never invent syntax to get past a diagnostic.
