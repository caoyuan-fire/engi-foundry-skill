#!/bin/sh

set -eu

usage() {
  echo "Usage: orch.sh create-phase|create-package|check [options]" >&2
}

action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
project_root="."
kind="mainline"
base_phase_id=""
phase_id=""
package_id=""
job_count=""
title="Task goal"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root) project_root="${2:-}"; shift 2 ;;
    --kind) kind="${2:-}"; shift 2 ;;
    --base-phase-id) base_phase_id="${2:-}"; shift 2 ;;
    --phase-id) phase_id="${2:-}"; shift 2 ;;
    --package-id) package_id="${2:-}"; shift 2 ;;
    --job-count) job_count="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done

case "$action" in
  create-phase|create-package|check) ;;
  *) usage; exit 2 ;;
esac
if [ ! -d "$project_root" ]; then
  printf '%s\n' '{"status":"error","reason":"invalid-project-root"}'
  exit 2
fi

project_root="$(cd "$project_root" && pwd -P)"
root_config="$project_root/engifoundry.config.json"
if [ ! -s "$root_config" ]; then
  printf '%s\n' '{"status":"error","reason":"missing-root-config"}'
  exit 2
fi

config_value() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$root_config" | sed -n '1p'
}

package_relative="$(config_value packageRoot)"
case "$package_relative" in ""|/*|*..*) printf '%s\n' '{"status":"error","reason":"invalid-package-root"}'; exit 2 ;; esac
package_root="$project_root/$package_relative"
mkdir -p "$package_root"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

read_json_string() {
  file="$1"
  key="$2"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | sed -n '1p'
}

next_number() {
  parent="$1"
  prefix="$2"
  width="$3"
  max=0
  for path in "$parent"/"$prefix"*; do
    [ -e "$path" ] || continue
    name="$(basename "$path")"
    number="${name#"$prefix"}"
    case "$number" in *[!0-9]*|"") continue ;; esac
    value="$(printf '%s\n' "$number" | awk '{ print $1 + 0 }')"
    [ "$value" -le "$max" ] || max="$value"
  done
  printf "%0${width}d" $((max + 1))
}

rebuild_phase_index() {
  temporary="$package_root/.phase.index.json.tmp.$$"
  mainline=""
  phase_entries=""
  latest_available=""
  latest_closed=""
  for directory in "$package_root"/PHASE-*; do
    [ -d "$directory" ] || continue
    config="$directory/phase.config.json"
    [ -s "$config" ] || continue
    id="$(read_json_string "$config" phaseId)"
    phase_kind="$(read_json_string "$config" kind)"
    phase_status="$(read_json_string "$config" status)"
    base="$(read_json_string "$config" basePhaseId)"
    [ -n "$id" ] || continue
    if [ "$phase_kind" = "mainline" ]; then
      [ -z "$mainline" ] || mainline="$mainline,"
      mainline="$mainline\"$id\""
    fi
    [ -z "$phase_entries" ] || phase_entries="$phase_entries,"
    if [ -n "$base" ]; then base_json="\"$base\""; else base_json="null"; fi
    phase_entries="$phase_entries\n    \"$id\": {\"kind\": \"$phase_kind\", \"status\": \"$phase_status\", \"basePhaseId\": $base_json}"
    [ "$phase_status" != "available" ] || latest_available="$id"
    [ "$phase_status" != "closed" ] || latest_closed="$id"
  done
  next_id="PHASE-$(next_number "$package_root" PHASE- 3)"
  if [ -n "$latest_available" ]; then available_json="\"$latest_available\""; else available_json="null"; fi
  if [ -n "$latest_closed" ]; then closed_json="\"$latest_closed\""; else closed_json="null"; fi
  {
    printf '{\n  "schemaVersion": 1,\n  "mainlineOrder": [%s],\n  "phases": {' "$mainline"
    printf '%b' "$phase_entries"
    printf '\n  },\n  "latestAvailablePhase": %s,\n  "latestClosedPhase": %s,\n  "nextMainlinePhaseId": "%s"\n}\n' "$available_json" "$closed_json" "$next_id"
  } > "$temporary"
  mv "$temporary" "$package_root/phase.index.json"
}

rebuild_phase_packages() {
  config="$1/phase.config.json"
  packages=""
  for directory in "$1"/PAK-*; do
    [ -d "$directory" ] || continue
    id="$(basename "$directory")"
    [ -z "$packages" ] || packages="$packages,"
    packages="$packages\"$id\""
  done
  temporary="$1/.phase.config.json.tmp.$$"
  sed "s/\"packages\"[[:space:]]*:[[:space:]]*\[[^]]*\]/\"packages\": [$packages]/" "$config" > "$temporary"
  mv "$temporary" "$config"
}

package_path() {
  printf '%s/%s/%s' "$package_root" "$phase_id" "$package_id"
}

check_package() {
  directory="$(package_path)"
  errors=""
  for file in "$directory/summary.md" "$directory/package.config.json"; do
    [ -s "$file" ] || errors="$errors missing-file"
  done
  if [ -s "$directory/summary.md" ] && grep -Fq 'TODO' "$directory/summary.md"; then errors="$errors incomplete-summary"; fi
  [ -d "$directory/jobs" ] || errors="$errors missing-jobs"
  if [ -s "$directory/package.config.json" ]; then
    grep -Eq "\"phaseId\"[[:space:]]*:[[:space:]]*\"$phase_id\"" "$directory/package.config.json" || errors="$errors phase-mismatch"
    grep -Eq "\"packageId\"[[:space:]]*:[[:space:]]*\"$package_id\"" "$directory/package.config.json" || errors="$errors package-mismatch"
    for key in acceptanceCriteria requiredArtifacts closeoutRequirements; do
      if grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]" "$directory/package.config.json"; then errors="$errors empty-$key"; fi
    done
  fi
  jobs=0
  for job in "$directory/jobs"/JOB-*; do
    [ -d "$job" ] || continue
    jobs=$((jobs + 1))
    [ -s "$job/job.md" ] || errors="$errors missing-job-md"
    [ -s "$job/job.config.json" ] || errors="$errors missing-job-config"
    if [ -s "$job/job.md" ] && grep -Fq 'TODO' "$job/job.md"; then errors="$errors incomplete-job-md"; fi
    id="$(basename "$job")"
    if [ -s "$job/job.config.json" ]; then
      grep -Eq "\"jobId\"[[:space:]]*:[[:space:]]*\"$id\"" "$job/job.config.json" || errors="$errors job-mismatch"
      for key in allowedAreas stopConditions acceptanceCriteria reviewRequirements requiredOutputs; do
        if grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*\[[[:space:]]*\]" "$job/job.config.json"; then errors="$errors empty-job-$key"; fi
      done
    fi
  done
  [ "$jobs" -gt 0 ] || errors="$errors no-jobs"
  if [ -n "$errors" ]; then
    printf '{"status":"invalid","reason":"package-check-failed","details":"%s"}\n' "$(printf '%s' "$errors" | sed 's/^ *//')"
    return 1
  fi
  printf '{"status":"ok","phaseId":"%s","packageId":"%s","jobCount":%s}\n' "$phase_id" "$package_id" "$jobs"
}

if [ "$action" = "create-phase" ]; then
  case "$kind" in mainline|extension) ;; *) usage; exit 2 ;; esac
  if [ "$kind" = "mainline" ]; then
    phase_id="PHASE-$(next_number "$package_root" PHASE- 3)"
    base_phase_id=""
  else
    case "$base_phase_id" in PHASE-[0-9][0-9][0-9]) ;; *) usage; exit 2 ;; esac
    [ -d "$package_root/$base_phase_id" ] || { printf '%s\n' '{"status":"invalid","reason":"missing-base-phase"}'; exit 1; }
    suffix="$(next_number "$package_root" "$base_phase_id-EX" 2)"
    phase_id="$base_phase_id-EX$suffix"
  fi
  directory="$package_root/$phase_id"
  mkdir "$directory"
  if [ -n "$base_phase_id" ]; then base_json="\"$base_phase_id\""; else base_json="null"; fi
  cat > "$directory/phase.config.json" <<EOF
{
  "schemaVersion": 1,
  "phaseId": "$phase_id",
  "kind": "$kind",
  "basePhaseId": $base_json,
  "status": "available",
  "statusReason": null,
  "roadmap": null,
  "packages": []
}
EOF
  rebuild_phase_index
  printf '{"status":"created","phaseId":"%s"}\n' "$phase_id"
  exit 0
fi

case "$phase_id" in PHASE-[0-9][0-9][0-9]|PHASE-[0-9][0-9][0-9]-EX[0-9][0-9]) ;; *) usage; exit 2 ;; esac
phase_directory="$package_root/$phase_id"
[ -d "$phase_directory" ] || { printf '%s\n' '{"status":"invalid","reason":"missing-phase"}'; exit 1; }

if [ "$action" = "create-package" ]; then
  case "$job_count" in ""|*[!0-9]*|0) usage; exit 2 ;; esac
  [ "$job_count" -le 999 ] || { usage; exit 2; }
  phase_status="$(read_json_string "$phase_directory/phase.config.json" status)"
  [ "$phase_status" = "available" ] || { printf '%s\n' '{"status":"invalid","reason":"phase-not-available"}'; exit 1; }
  package_id="PAK-$(next_number "$phase_directory" PAK- 3)"
  directory="$phase_directory/$package_id"
  mkdir -p "$directory/jobs"
  escaped_title="$(json_escape "$title")"
  jobs_json=""
  index=1
  while [ "$index" -le "$job_count" ]; do
    job_id="JOB-$(printf '%03d' "$index")"
    job_directory="$directory/jobs/$job_id"
    mkdir "$job_directory"
    cat > "$job_directory/job.md" <<EOF
# $job_id

## Step Outcome

TODO
EOF
    cat > "$job_directory/job.config.json" <<EOF
{
  "schemaVersion": 1,
  "phaseId": "$phase_id",
  "packageId": "$package_id",
  "jobId": "$job_id",
  "status": "planned",
  "reviewRef": null,
  "reworkFacts": [],
  "type": "delegable",
  "dependsOn": [],
  "allowedAreas": [],
  "forbiddenAreas": [],
  "stopConditions": [],
  "acceptanceCriteria": [],
  "reviewRequirements": [],
  "requiredOutputs": []
}
EOF
    [ -z "$jobs_json" ] || jobs_json="$jobs_json,"
    jobs_json="$jobs_json\n    {\"jobId\": \"$job_id\", \"dependsOn\": []}"
    index=$((index + 1))
  done
  cat > "$directory/summary.md" <<EOF
# $package_id: $title

## Goal

TODO
EOF
  {
    printf '{\n  "schemaVersion": 1,\n  "phaseId": "%s",\n  "packageId": "%s",\n  "title": "%s",\n' "$phase_id" "$package_id" "$escaped_title"
    printf '  "planning": {"status": "draft", "reviewRef": null},\n  "execution": {"status": "not-started", "verificationRef": null, "deliveryRef": null},\n  "jobs": ['
    printf '%b' "$jobs_json"
    printf '\n  ],\n  "acceptanceCriteria": [],\n  "requiredArtifacts": [],\n  "closeoutRequirements": []\n}\n'
  } > "$directory/package.config.json"
  rebuild_phase_packages "$phase_directory"
  printf '{"status":"created","phaseId":"%s","packageId":"%s","jobCount":%s}\n' "$phase_id" "$package_id" "$job_count"
  exit 0
fi

case "$package_id" in PAK-[0-9][0-9][0-9]) ;; *) usage; exit 2 ;; esac
directory="$(package_path)"
[ -d "$directory" ] || { printf '%s\n' '{"status":"invalid","reason":"missing-package"}'; exit 1; }

if [ "$action" = "check" ]; then
  check_package
  exit $?
fi

usage
exit 2
