#!/usr/bin/env bash
# Check coverage.json: every opentide platform has a skill, and the capabilities
# recorded there match the engine the skills were reviewed against.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE=false
STRICT=false
OPENTIDE_BIN="${OPENTIDE_BIN:-opentide}"

usage() {
  cat <<'EOF'
Usage: ./scripts/check-opentide-coverage.sh [--engine] [--strict]

  (default)  Offline: coverage.json names only existing skills, and each platform's
             first skill names its configuration key (configurations.<key>).
  --engine   Also run `opentide --json info` (OPENTIDE_BIN, default `opentide`) and
             fail when a platform is missing from coverage.json, no longer exists,
             or its can_deploy / can_validate / can_query flags have changed.
  --strict   With --engine, also fail when the installed opentide is newer than
             coverage.json's reviewed_against (otherwise a warning).
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --engine) ENGINE=true ;;
    --strict) STRICT=true ;;
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

ENGINE_JSON=""
if [[ "${ENGINE}" == true ]]; then
  if ! command -v "${OPENTIDE_BIN}" >/dev/null 2>&1; then
    echo "ERROR: ${OPENTIDE_BIN} not found; install it with: pip install opentide" >&2
    exit 1
  fi
  # An empty directory, and no OPENTIDE_REPO_ROOT: `info` reports the engine's
  # platforms, not a repository's (whose configuration could fail the check).
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "${WORKDIR}"' EXIT
  ENGINE_JSON="${WORKDIR}/info.json"
  (cd "${WORKDIR}" && env -u OPENTIDE_REPO_ROOT "${OPENTIDE_BIN}" --json info >"${ENGINE_JSON}")
fi

python3 - "${ROOT}" "${ENGINE_JSON}" "${STRICT}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
engine_path = sys.argv[2]
strict = sys.argv[3] == "true"
in_actions = os.environ.get("GITHUB_ACTIONS") == "true"
CAPABILITIES = ("can_deploy", "can_validate", "can_query")
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")

errors: list[str] = []
warnings: list[str] = []

coverage_path = root / "coverage.json"
try:
    coverage = json.loads(coverage_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"ERROR: coverage.json cannot be read: {exc}")
    sys.exit(1)

reviewed = coverage.get("reviewed_against")
if not isinstance(reviewed, str) or not VERSION_RE.match(reviewed):
    errors.append("coverage.json reviewed_against must be an opentide version such as 0.28.0")

platforms = coverage.get("platforms")
if not isinstance(platforms, dict) or not platforms:
    errors.append("coverage.json platforms must be a non-empty object")
    platforms = {}

skill_names = {path.parent.name for path in (root / "skills").glob("*/SKILL.md")}
for key, entry in platforms.items():
    if not isinstance(entry, dict):
        errors.append(f"coverage.json {key}: entry must be an object")
        continue
    skills = entry.get("skills")
    if not isinstance(skills, list) or not skills:
        errors.append(f"coverage.json {key}: skills must be a non-empty list")
        continue
    for name in skills:
        if name not in skill_names:
            errors.append(f"coverage.json {key}: skill '{name}' does not exist under skills/")
    for flag in CAPABILITIES:
        if not isinstance(entry.get(flag), bool):
            errors.append(f"coverage.json {key}: {flag} must be true or false")
    primary = skills[0]
    if primary in skill_names:
        text = (root / "skills" / primary / "SKILL.md").read_text(encoding="utf-8")
        if f"configurations.{key}" not in text:
            errors.append(
                f"skills/{primary}/SKILL.md: does not name its configuration key "
                f"`configurations.{key}`"
            )


try:
    from packaging.version import Version as _Version
except ImportError:  # pragma: no cover - depends on the host interpreter
    _Version = None


def compare_versions(left: str, right: str) -> int:
    """-1, 0 or 1. PEP 440 when `packaging` can read both (0.28.0.post1 > 0.28.0),
    else the numbers in each, in order."""
    if _Version is not None:
        try:
            a, b = _Version(left), _Version(right)
            return (a > b) - (a < b)
        except Exception:
            pass
    x = tuple(int(part) for part in re.findall(r"\d+", left))
    y = tuple(int(part) for part in re.findall(r"\d+", right))
    return (x > y) - (x < y)


if engine_path:
    try:
        info = json.loads(Path(engine_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: `opentide --json info` did not return JSON: {exc}")
        sys.exit(1)
    engine_version = str(info.get("version", ""))
    engine_platforms = {
        item["name"]: item for item in info.get("platforms", []) if isinstance(item, dict)
    }
    if not engine_platforms:
        errors.append("`opentide --json info` listed no platforms")
    for key in sorted(set(engine_platforms) - set(platforms)):
        errors.append(
            f"opentide {engine_version} supports platform '{key}', which coverage.json "
            f"does not list: add a platform skill and a coverage.json entry"
        )
    for key in sorted(set(platforms) - set(engine_platforms)):
        errors.append(
            f"coverage.json lists platform '{key}', which opentide {engine_version} "
            f"no longer reports: retire or rename it"
        )
    for key in sorted(set(platforms) & set(engine_platforms)):
        entry, live = platforms[key], engine_platforms[key]
        if not isinstance(entry, dict):
            continue
        for flag in CAPABILITIES:
            if flag in live and entry.get(flag) != live[flag]:
                errors.append(
                    f"{key}: opentide {engine_version} reports {flag}={str(live[flag]).lower()}, "
                    f"coverage.json says {str(entry.get(flag)).lower()}: update "
                    f"{', '.join(entry.get('skills', []))} and coverage.json"
                )
    if isinstance(reviewed, str) and VERSION_RE.match(reviewed) and engine_version:
        if compare_versions(engine_version, reviewed) > 0:
            message = (
                f"opentide {engine_version} is newer than coverage.json reviewed_against "
                f"{reviewed}: review its CHANGELOG for skill impact, then bump reviewed_against"
            )
            (errors if strict else warnings).append(message)
        elif compare_versions(engine_version, reviewed) < 0:
            warnings.append(
                f"opentide {engine_version} is older than reviewed_against {reviewed}; "
                f"install the latest release for an accurate check"
            )

for warning in warnings:
    print(f"::warning::{warning}" if in_actions else f"WARNING: {warning}")
if errors:
    for error in errors:
        print(f"::error::{error}" if in_actions else f"ERROR: {error}")
    print(f"coverage check failed with {len(errors)} error(s)")
    sys.exit(1)

scope = "against the engine" if engine_path else "offline"
print(f"validated coverage.json ({len(platforms)} platforms, {scope})")
PY
