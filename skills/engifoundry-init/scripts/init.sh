#!/bin/sh

set -eu

usage() {
  echo "Usage: init.sh init|check [--project-root PATH]" >&2
}

command_name="${1:-}"
if [ "$#" -gt 0 ]; then
  shift
fi
project_root="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      project_root="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

case "$command_name" in
  init|check) ;;
  *) usage; exit 2 ;;
esac

if [ ! -d "$project_root" ]; then
  echo "status: blocked"
  echo "project root is not a directory: $project_root" >&2
  exit 1
fi

project_root="$(cd "$project_root" && pwd -P)"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
skill_root="$(dirname "$script_dir")"
workspace_template="$skill_root/references/workspace.md"
template_root="$skill_root/references/templates"
root_config="$project_root/engifoundry.config.json"
data_root="$project_root/.engifoundry"
gitignore="$project_root/.gitignore"
gitignore_rule=".engifoundry/packages/"
cache_gitignore_rule=".engifoundry/cache/"

check_scaffold() {
  check_root="$1"
  check_data="$check_root/.engifoundry"
  errors=0

  for directory in \
    "$check_data" \
    "$check_data/cache" \
    "$check_data/contracts" \
    "$check_data/artifacts/plans" \
    "$check_data/artifacts/records" \
    "$check_data/artifacts/reviews" \
    "$check_data/artifacts/verification" \
    "$check_data/artifacts/delivery" \
    "$check_data/packages"
  do
    if [ ! -d "$directory" ]; then
      echo "missing directory: $directory" >&2
      errors=1
    fi
  done

  for file in \
    "$check_root/engifoundry.config.json" \
    "$check_data/workspace.md" \
    "$check_data/initialization.json" \
    "$check_data/executors.json" \
    "$check_data/contracts/executors.schema.json" \
    "$check_data/workflows.json"
  do
    if [ ! -s "$file" ]; then
      echo "missing or empty file: $file" >&2
      errors=1
    fi
  done

  check_gitignore="$check_root/.gitignore"
  if [ ! -f "$check_gitignore" ] || ! grep -Fqx "$gitignore_rule" "$check_gitignore"; then
    echo "missing .gitignore rule: $gitignore_rule" >&2
    errors=1
  fi
  if [ ! -f "$check_gitignore" ] || ! grep -Fqx "$cache_gitignore_rule" "$check_gitignore"; then
    echo "missing .gitignore rule: $cache_gitignore_rule" >&2
    errors=1
  fi

  return "$errors"
}

if [ "$command_name" = "check" ]; then
  if check_scaffold "$project_root"; then
    echo "status: ok"
    exit 0
  fi
  echo "status: failed"
  exit 1
fi

collisions=""
[ ! -e "$root_config" ] || collisions="$collisions
$root_config"
[ ! -e "$data_root" ] || collisions="$collisions
$data_root"
if [ -n "$collisions" ]; then
  echo "status: blocked"
  printf '%s\n' "$collisions" | while IFS= read -r path; do
    [ -z "$path" ] || echo "path already exists: $path" >&2
  done
  exit 1
fi

for template in \
  "$workspace_template" \
  "$template_root/engifoundry.config.json" \
  "$template_root/initialization.json" \
  "$template_root/executors.json" \
  "$template_root/executors.schema.json" \
  "$template_root/workflows.json"
do
  if [ ! -s "$template" ]; then
    echo "status: failed"
    echo "missing or empty template: $template" >&2
    exit 1
  fi
done

staging="$(mktemp -d "$project_root/.engifoundry-init.XXXXXX")"
installed_data=0
installed_root=0
gitignore_changed=0
gitignore_existed=0
committed=0
cleanup() {
  if [ "$committed" -ne 1 ]; then
    if [ "$gitignore_changed" -eq 1 ]; then
      if [ "$gitignore_existed" -eq 1 ]; then
        cp "$staging/gitignore.backup" "$gitignore"
      else
        rm -f "$gitignore"
      fi
    fi
    if [ "$installed_root" -eq 1 ]; then
      rm -f "$root_config"
    fi
    if [ "$installed_data" -eq 1 ]; then
      rm -rf "$data_root"
    fi
  fi
  rm -rf "$staging"
}
trap cleanup EXIT HUP INT TERM

staging_data="$staging/.engifoundry"
mkdir -p \
  "$staging_data/cache" \
  "$staging_data/contracts" \
  "$staging_data/artifacts/plans" \
  "$staging_data/artifacts/records" \
  "$staging_data/artifacts/reviews" \
  "$staging_data/artifacts/verification" \
  "$staging_data/artifacts/delivery" \
  "$staging_data/packages"

cp "$workspace_template" "$staging_data/workspace.md"
cp "$template_root/initialization.json" "$staging_data/initialization.json"
cp "$template_root/executors.json" "$staging_data/executors.json"
cp "$template_root/executors.schema.json" "$staging_data/contracts/executors.schema.json"
cp "$template_root/workflows.json" "$staging_data/workflows.json"
cp "$template_root/engifoundry.config.json" "$staging/engifoundry.config.json"
printf '%s\n%s\n' "$gitignore_rule" "$cache_gitignore_rule" > "$staging/.gitignore"

if ! check_scaffold "$staging"; then
  echo "status: failed"
  exit 1
fi

mv "$staging_data" "$data_root"
installed_data=1

if [ ! -f "$gitignore" ] || ! grep -Fqx "$gitignore_rule" "$gitignore" || ! grep -Fqx "$cache_gitignore_rule" "$gitignore"; then
  if [ -e "$gitignore" ]; then
    gitignore_existed=1
    cp "$gitignore" "$staging/gitignore.backup"
  fi
  if ! grep -Fqx "$gitignore_rule" "$gitignore" 2>/dev/null; then
    if [ -s "$gitignore" ]; then printf '\n' >> "$gitignore"; fi
    printf '%s\n' "$gitignore_rule" >> "$gitignore"
  fi
  if ! grep -Fqx "$cache_gitignore_rule" "$gitignore" 2>/dev/null; then
    printf '%s\n' "$cache_gitignore_rule" >> "$gitignore"
  fi
  gitignore_changed=1
fi

root_temporary="$project_root/.engifoundry.config.json.tmp.$$"
cp "$template_root/engifoundry.config.json" "$root_temporary"
mv "$root_temporary" "$root_config"
installed_root=1

if ! check_scaffold "$project_root"; then
  echo "status: failed"
  exit 1
fi

committed=1
echo "status: ok"
