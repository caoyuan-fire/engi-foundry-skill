#!/bin/sh
set -eu

usage() {
  echo "Usage: create_root_config.sh --mode empty|filled [--project-root PATH] [--artifact-root PATH] [--package-root PATH] [--records-policy VALUE] [--default-package-policy VALUE] [--force]" >&2
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

mode="filled"
project_root="."
artifact_root=".engifoundry"
package_root=".engifoundry-packages"
records_policy="durable"
default_package_policy="package-when-risky"
force=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) mode="${2:-}"; shift 2 ;;
    --project-root) project_root="${2:-}"; shift 2 ;;
    --artifact-root) artifact_root="${2:-}"; shift 2 ;;
    --package-root) package_root="${2:-}"; shift 2 ;;
    --records-policy) records_policy="${2:-}"; shift 2 ;;
    --default-package-policy) default_package_policy="${2:-}"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

case "$mode" in
  empty)
    artifact_root=""
    package_root=""
    records_policy=""
    default_package_policy=""
    ;;
  filled) ;;
  *) usage; exit 2 ;;
esac

config_path="$project_root/.engifoundry.config.json"
if [ -e "$config_path" ] && [ "$force" -ne 1 ]; then
  echo "$config_path already exists; pass --force to overwrite" >&2
  exit 1
fi

mkdir -p "$project_root"
cat > "$config_path" <<EOF
{
  "schemaVersion": 1,
  "artifactRoot": "$(json_escape "$artifact_root")",
  "packageRoot": "$(json_escape "$package_root")",
  "recordsPolicy": "$(json_escape "$records_policy")",
  "defaultPackagePolicy": "$(json_escape "$default_package_policy")"
}
EOF

printf '%s\n' "$config_path"
