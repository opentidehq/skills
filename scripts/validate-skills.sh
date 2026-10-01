#!/usr/bin/env bash
# Validate Agent Skills frontmatter against agentskills.io conventions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT}/skills"
errors=0

name_pattern='^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'

while IFS= read -r skill_md; do
  skill_dir="$(dirname "${skill_md}")"
  dir_name="$(basename "${skill_dir}")"

  if ! head -n 1 "${skill_md}" | grep -q '^---$'; then
    echo "ERROR: missing frontmatter in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  name="$(awk '/^---$/{if(++n==2) exit} n==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "${skill_md}")"
  description="$(awk '/^---$/{if(++n==2) exit} n==1 && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "${skill_md}")"

  if [[ -z "${name}" ]]; then
    echo "ERROR: missing name in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  if [[ -z "${description}" ]]; then
    echo "ERROR: missing description in ${skill_md}"
    errors=$((errors + 1))
    continue
  fi

  if [[ "${name}" != "${dir_name}" ]]; then
    echo "ERROR: name '${name}' does not match directory '${dir_name}' (${skill_md})"
    errors=$((errors + 1))
  fi

  if [[ ! "${name}" =~ ${name_pattern} ]]; then
    echo "ERROR: invalid name '${name}' in ${skill_md}"
    errors=$((errors + 1))
  fi

  if [[ ${#name} -gt 64 ]]; then
    echo "ERROR: name too long in ${skill_md}"
    errors=$((errors + 1))
  fi

  if [[ ${#description} -gt 1024 ]]; then
    echo "ERROR: description too long in ${skill_md}"
    errors=$((errors + 1))
  fi
done < <(find "${SKILLS_DIR}" -name SKILL.md | sort)

if [[ "${errors}" -gt 0 ]]; then
  echo "validation failed with ${errors} error(s)"
  exit 1
fi

skill_count="$(find "${SKILLS_DIR}" -name SKILL.md | wc -l | tr -d ' ')"
echo "validated ${skill_count} skills"

python3 - "${ROOT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
config_path = root / "skills.sh.json"
try:
    config = json.loads(config_path.read_text())
except json.JSONDecodeError as exc:
    print(f"ERROR: skills.sh.json is not valid JSON ({exc})")
    sys.exit(1)

skills = {path.parent.name for path in (root / "skills").glob("*/SKILL.md")}
groupings = config.get("groupings")
if not isinstance(groupings, list) or not groupings:
    print("ERROR: skills.sh.json groupings must be a non-empty array")
    sys.exit(1)

errors = 0
seen = []
for group in groupings:
    title = group.get("title") if isinstance(group, dict) else None
    names = group.get("skills") if isinstance(group, dict) else None
    if not isinstance(title, str) or not title.strip():
        print("ERROR: skills.sh.json group is missing a title")
        errors += 1
        continue
    if not isinstance(names, list) or not names:
        print(f"ERROR: skills.sh.json group '{title}' has no skills")
        errors += 1
        continue
    for name in names:
        if name not in skills:
            print(f"ERROR: skills.sh.json lists unknown skill '{name}' in '{title}'")
            errors += 1
        elif name in seen:
            print(f"ERROR: skills.sh.json lists '{name}' more than once")
            errors += 1
        else:
            seen.append(name)

missing = sorted(skills - set(seen))
if missing:
    print("ERROR: skills missing from skills.sh.json: " + ", ".join(missing))
    errors += 1

if errors:
    sys.exit(1)

print(f"validated skills.sh.json ({len(seen)} skills in {len(groupings)} groups)")
PY

"${ROOT}/scripts/build-manifest.sh" --check
