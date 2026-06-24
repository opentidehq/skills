# OpenTide Skills

Canonical home for reusable [Agent Skills](https://agentskills.io/specification) used across the OpenTide ecosystem.

## Purpose

This repository holds domain and toolchain skills as `skills/<skill-name>/SKILL.md` files. It complements:

- **[AgentTide](https://github.com/OpenTideHQ/AgentTide)** — cross-harness agent entrypoints (`AGENTS.md`, editor stubs)
- **[opentide](https://github.com/OpenTideHQ/opentide)** — DetectionOps engine and `opentide setup skills` CLI

## Layout

```
skills/
└── <skill-name>/
    ├── SKILL.md          # Required — YAML frontmatter (name, description) + instructions
    ├── references/         # Optional — detailed docs
    ├── scripts/            # Optional — utility scripts
    └── assets/             # Optional — templates, examples
```

See [`skills/README.md`](skills/README.md) for authoring conventions.

## License

Licensed under the [European Union Public Licence v. 1.2](LICENSE) (EUPL-1.2).
