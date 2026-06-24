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

echo "validated $(find "${SKILLS_DIR}" -name SKILL.md | wc -l | tr -d ' ') skills"
