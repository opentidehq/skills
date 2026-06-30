#!/usr/bin/env bash
# Build manifest.json from skills/*/SKILL.md frontmatter.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/manifest.json"
SKILLS_DIR="${ROOT}/skills"
SOURCE="${MANIFEST_SOURCE:-OpenTideHQ/skills}"
REF="${MANIFEST_REF:-main}"
VERSION=1
CHECK=false

usage() {
  cat <<'EOF'
Usage: ./scripts/build-manifest.sh [--check]

  (default)  Write manifest.json at the repo root from skills/*/SKILL.md frontmatter.
  --check    Fail if committed manifest.json is stale (ignores generated_at).
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --check) CHECK=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: ${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${SKILLS_DIR}" ]]; then
  echo "ERROR: skills directory not found: ${SKILLS_DIR}" >&2
  exit 1
fi

GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TMP_MANIFEST="$(mktemp)"
trap 'rm -f "${TMP_MANIFEST}"' EXIT

python3 - "${SKILLS_DIR}" "${TMP_MANIFEST}" "${VERSION}" "${SOURCE}" "${REF}" "${GENERATED_AT}" <<'PY'
import json
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1])
out_path = Path(sys.argv[2])
version = int(sys.argv[3])
source = sys.argv[4]
ref = sys.argv[5]
generated_at = sys.argv[6]


def parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("missing frontmatter opener")
    end = text.find("\n---", 4)
    if end == -1:
        raise ValueError("missing frontmatter closer")
    body = text[4:end]
    fields: dict[str, str] = {}
    lines = body.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line or line.lstrip().startswith("#"):
            i += 1
            continue
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not match:
            i += 1
            continue
        key, value = match.group(1), match.group(2)
        if value in {">-", ">", "|", "|-", "|+"}:
            folded = value.startswith(">")
            block_lines: list[str] = []
            i += 1
            while i < len(lines):
                block_line = lines[i]
                if block_line and not block_line[0].isspace():
                    break
                block_lines.append(block_line.strip())
                i += 1
            text_value = (
                " ".join(part for part in block_lines if part)
                if folded
                else "\n".join(block_lines).rstrip()
            )
            fields[key] = text_value
            continue
        if (value.startswith('"') and value.endswith('"')) or (
            value.startswith("'") and value.endswith("'")
        ):
            value = value[1:-1]
        fields[key] = value
        i += 1
    return fields


skills: list[dict[str, str]] = []
for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
    slug = skill_md.parent.name
    raw = skill_md.read_text(encoding="utf-8")
    frontmatter = parse_frontmatter(raw)
    name = frontmatter.get("name", "").strip()
    description = frontmatter.get("description", "").strip()
    if not name:
        raise SystemExit(f"ERROR: missing name in {skill_md}")
    if not description:
        raise SystemExit(f"ERROR: missing description in {skill_md}")
    if name != slug:
        raise SystemExit(
            f"ERROR: name '{name}' does not match directory '{slug}' ({skill_md})"
        )
    skills.append({"slug": slug, "name": name, "description": description})

payload = {
    "version": version,
    "source": source,
    "ref": ref,
    "generated_at": generated_at,
    "skills": skills,
}
out_path.write_text(
    json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
print(f"generated manifest with {len(skills)} skills")
PY

if [[ "${CHECK}" == true ]]; then
  if [[ ! -f "${MANIFEST}" ]]; then
    echo "ERROR: manifest.json not found; run ./scripts/build-manifest.sh" >&2
    exit 1
  fi
  if python3 - "${MANIFEST}" "${TMP_MANIFEST}" <<'PY'
import json
import sys

committed_path, generated_path = sys.argv[1], sys.argv[2]
committed = json.loads(open(committed_path, encoding="utf-8").read())
generated = json.loads(open(generated_path, encoding="utf-8").read())

for key in ("generated_at",):
    committed.pop(key, None)
    generated.pop(key, None)

if committed != generated:
    print("manifest.json is stale; run ./scripts/build-manifest.sh")
    sys.exit(1)

print("manifest.json matches generated output")
PY
  then
    exit 0
  else
    exit 1
  fi
fi

mv "${TMP_MANIFEST}" "${MANIFEST}"
trap - EXIT
echo "wrote ${MANIFEST}"
