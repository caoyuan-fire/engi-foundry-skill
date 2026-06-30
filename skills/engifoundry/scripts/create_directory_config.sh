#!/bin/sh
set -eu

usage() {
  echo "Usage: create_directory_config.sh --mode empty|filled [--project-root PATH] [--artifact-root PATH] [--package-root PATH] [--force]" >&2
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

read_json_string() {
  key="$1"
  file="$2"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | sed -n '1p'
}

mode="filled"
project_root="."
artifact_root=""
package_root=""
force=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) mode="${2:-}"; shift 2 ;;
    --project-root) project_root="${2:-}"; shift 2 ;;
    --artifact-root) artifact_root="${2:-}"; shift 2 ;;
    --package-root) package_root="${2:-}"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

case "$mode" in
  empty|filled) ;;
  *) usage; exit 2 ;;
esac

root_config_path="$project_root/.engifoundry.config.json"
if [ -f "$root_config_path" ]; then
  if [ -z "$artifact_root" ]; then
    artifact_root="$(read_json_string artifactRoot "$root_config_path")"
  fi
  if [ -z "$package_root" ]; then
    package_root="$(read_json_string packageRoot "$root_config_path")"
  fi
fi

artifact_root="${artifact_root:-.engifoundry}"
package_root="${package_root:-.engifoundry-packages}"

config_path="$project_root/$artifact_root/directory.config.json"
if [ -e "$config_path" ] && [ "$force" -ne 1 ]; then
  echo "$config_path already exists; pass --force to overwrite" >&2
  exit 1
fi

mkdir -p "$project_root/$artifact_root"

if [ "$mode" = "empty" ]; then
  cat > "$config_path" <<'EOF'
{
  "schemaVersion": 1,
  "createdBy": "engifoundry",
  "directories": [
    {
      "path": "",
      "category": "",
      "purpose": "",
      "mustNotContain": []
    }
  ]
}
EOF
else
  cat > "$config_path" <<EOF
{
  "schemaVersion": 1,
  "createdBy": "engifoundry",
  "artifactRoot": "$(json_escape "$artifact_root")",
  "packageRoot": "$(json_escape "$package_root")",
  "directories": [
    {
      "path": "<project-root>/.engifoundry.config.json",
      "category": "Project discovery config",
      "purpose": "Locates EngiFoundry roots and durable workflow defaults for session alignment.",
      "mustNotContain": ["secrets", "tokens", "runtime state", "Git ignore state", "roadmap state"]
    },
    {
      "path": "<artifact-root>/execution.config.json",
      "category": "Artifact-root execution config",
      "purpose": "Records executor registry and selection policy.",
      "mustNotContain": ["secrets", "tokens", "package authority grants", "transient executor state"]
    },
    {
      "path": "<artifact-root>/roadmaps/ROADMAP.md",
      "category": "Durable output",
      "purpose": "Current roadmap for requirement alignment, sequencing, and next-step decisions.",
      "mustNotContain": ["raw chat dumps", "private runtime state", "package control JSON"]
    },
    {
      "path": "<artifact-root>/roadmaps/roadmap.index.json",
      "category": "Artifact-root index",
      "purpose": "Points to the current roadmap and records roadmap metadata.",
      "mustNotContain": ["project root discovery settings", "Git ignore state", "secrets"]
    },
    {
      "path": "<artifact-root>/roadmaps/archive/",
      "category": "Durable output archive",
      "purpose": "Historical roadmap snapshots that still have alignment or audit value.",
      "mustNotContain": ["temporary drafts", "cache files", "raw model logs"]
    },
    {
      "path": "<artifact-root>/records/ad-hoc/",
      "category": "Durable output",
      "purpose": "Records from bounded low-risk work that did not enter package flow.",
      "mustNotContain": ["task package control inputs", "caches", "session dumps"]
    },
    {
      "path": "<artifact-root>/records/packages/<package-id>/",
      "category": "Durable output",
      "purpose": "Package-flow execution records, reviews, verification evidence, checkpoints, handoffs, and closeout notes.",
      "mustNotContain": ["package root control inputs unless copied as explicit evidence", "raw long logs", "private state"]
    },
    {
      "path": "<artifact-root>/records/reviews/",
      "category": "Durable output",
      "purpose": "Review-only records that are not owned by a specific package record tree.",
      "mustNotContain": ["implementation scratch files", "task package control inputs", "secrets"]
    },
    {
      "path": "<artifact-root>/records/audits/",
      "category": "Durable output",
      "purpose": "Process, cost, quality, migration, policy, and workflow retrospective records.",
      "mustNotContain": ["runtime cache", "downloaded modules", "unreviewable session dumps"]
    },
    {
      "path": "<artifact-root>/docs/generated/",
      "category": "Durable output",
      "purpose": "Generated documents with review, delivery, or handoff value.",
      "mustNotContain": ["cache output", "throwaway drafts", "raw model logs"]
    },
    {
      "path": "<artifact-root>/docs/integration/",
      "category": "Durable output",
      "purpose": "Host integration, API integration, installation, and adapter-facing user documentation.",
      "mustNotContain": ["executor runtime state", "package control JSON"]
    },
    {
      "path": "<artifact-root>/docs/design/",
      "category": "Durable output",
      "purpose": "Architecture, UX, data-flow, test-strategy, and domain design documents.",
      "mustNotContain": ["temporary scratch notes", "raw chat transcripts"]
    },
    {
      "path": "<artifact-root>/docs/reference/",
      "category": "Durable input reference",
      "purpose": "External or upstream reference material used as context for decisions.",
      "mustNotContain": ["secrets", "credentials", "downloaded dependency caches"]
    },
    {
      "path": "<artifact-root>/docs/archive/",
      "category": "Durable output archive",
      "purpose": "Historical documents that remain useful as readable background but are not current records.",
      "mustNotContain": ["current ROADMAP", "active package contracts", "cache files"]
    },
    {
      "path": "<package-root>/<package-id>/",
      "category": "Execution input",
      "purpose": "Task package summary, package control JSON, Job contracts, and package-flow control data.",
      "mustNotContain": ["execution records", "reviews", "verification evidence", "closeout notes", "raw logs"]
    }
  ]
}
EOF
fi

printf '%s\n' "$config_path"
