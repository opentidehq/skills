# Skills directory

Each skill is a folder containing a required `SKILL.md` file following the [Agent Skills specification](https://agentskills.io/specification).

## Structure

```
<skill-name>/
├── SKILL.md
├── references/     # optional
├── scripts/        # optional
└── assets/         # optional
```

## SKILL.md frontmatter

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description of what this skill does and when to use it
---
```

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter and instructions.
2. Add optional `references/`, `scripts/`, or `assets/` subdirectories as needed.
3. Open a pull request for review.

No skills are published yet — this directory is scaffolded for future contributions.
