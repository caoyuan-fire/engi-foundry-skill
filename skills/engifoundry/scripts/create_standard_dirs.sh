#!/bin/sh
set -eu

usage() {
  echo "Usage: create_standard_dirs.sh [--project-root PATH] [--artifact-root PATH] [--package-root PATH]" >&2
}

read_json_string() {
  key="$1"
  file="$2"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | sed -n '1p'
}

project_root="."
artifact_root=""
package_root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root) project_root="${2:-}"; shift 2 ;;
    --artifact-root) artifact_root="${2:-}"; shift 2 ;;
    --package-root) package_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

config_path="$project_root/.engifoundry.config.json"
if [ -f "$config_path" ]; then
  if [ -z "$artifact_root" ]; then
    artifact_root="$(read_json_string artifactRoot "$config_path")"
  fi
  if [ -z "$package_root" ]; then
    package_root="$(read_json_string packageRoot "$config_path")"
  fi
fi

artifact_root="${artifact_root:-.engifoundry}"
package_root="${package_root:-.engifoundry-packages}"

mkdir -p \
  "$project_root/$artifact_root/records/ad-hoc" \
  "$project_root/$artifact_root/records/packages" \
  "$project_root/$artifact_root/records/reviews" \
  "$project_root/$artifact_root/records/audits" \
  "$project_root/$artifact_root/docs/generated" \
  "$project_root/$artifact_root/docs/integration" \
  "$project_root/$artifact_root/docs/design" \
  "$project_root/$artifact_root/docs/reference" \
  "$project_root/$artifact_root/docs/archive" \
  "$project_root/$package_root"

printf '%s\n' "$project_root/$artifact_root"
printf '%s\n' "$project_root/$package_root"
