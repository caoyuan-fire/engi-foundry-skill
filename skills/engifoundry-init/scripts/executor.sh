#!/bin/sh

set -eu

usage() {
  echo "Usage: executor.sh begin|status|select|prefer|commit|cancel [--project-root PATH] [--native-subagent true|false] [--user-input TEXT]" >&2
}

action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
project_root="."
native_subagent="false"
user_input=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      project_root="$2"
      shift 2
      ;;
    --native-subagent)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      native_subagent="$2"
      shift 2
      ;;
    --user-input)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      user_input="$2"
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

case "$action" in
  begin|status|select|prefer|commit|cancel) ;;
  *) usage; exit 2 ;;
esac
case "$native_subagent" in
  true|false) ;;
  *) usage; exit 2 ;;
esac

if [ ! -d "$project_root" ]; then
  printf '%s\n' '{"status":"error","reason":"invalid-project-root"}'
  exit 2
fi

project_root="$(cd "$project_root" && pwd -P)"
data_root="$project_root/.engifoundry"
config_file="$data_root/executors.json"
setup_root="$data_root/.executor-setup"
phase_file="$setup_root/phase"
candidates_file="$setup_root/candidates.tsv"
selected_file="$setup_root/selected.tsv"
order_file="$setup_root/order.tsv"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
verifier="$script_dir/verify.sh"

if [ ! -d "$data_root" ] || [ ! -s "$config_file" ]; then
  printf '%s\n' '{"status":"error","reason":"missing-executor-config"}'
  exit 2
fi

json_array_from_file() {
  file="$1"
  result=""
  if [ -f "$file" ]; then
    while IFS="$(printf '\t')" read -r id kind command_name; do
      [ -n "$id" ] || continue
      if [ -n "$result" ]; then result="$result,"; fi
      result="$result\"$id\""
    done < "$file"
  fi
  printf '[%s]' "$result"
}

json_options_from_file() {
  file="$1"
  result=""
  number=1
  if [ -f "$file" ]; then
    while IFS="$(printf '\t')" read -r id kind command_name; do
      [ -n "$id" ] || continue
      if [ -n "$result" ]; then result="$result,"; fi
      result="$result{\"optionId\":$number,\"executorId\":\"$id\",\"kind\":\"$kind\""
      if [ -n "$command_name" ]; then
        result="$result,\"command\":\"$command_name\""
      fi
      result="$result}"
      number=$((number + 1))
    done < "$file"
  fi
  printf '[%s]' "$result"
}

emit_state() {
  if [ ! -s "$phase_file" ]; then
    printf '%s\n' '{"status":"idle"}'
    return
  fi
  phase="$(sed -n '1p' "$phase_file")"
  case "$phase" in
    select)
      printf '{"status":"in_progress","phase":"select","selection":"multiple","options":%s}\n' \
        "$(json_options_from_file "$candidates_file")"
      ;;
    prefer)
      printf '{"status":"in_progress","phase":"prefer","selection":"single","selectedExecutors":%s,"options":%s}\n' \
        "$(json_array_from_file "$selected_file")" "$(json_options_from_file "$selected_file")"
      ;;
    ready)
      printf '{"status":"ready","executorOrder":%s}\n' "$(json_array_from_file "$order_file")"
      ;;
    *)
      printf '%s\n' '{"status":"error","reason":"invalid-executor-setup"}'
      exit 2
      ;;
  esac
}

count_lines() {
  awk 'NF { count++ } END { print count + 0 }' "$1"
}

if [ "$action" = "begin" ]; then
  if [ -s "$phase_file" ]; then
    emit_state
    exit 0
  fi
  temporary="$data_root/.executor-setup.tmp.$$"
  rm -rf "$temporary"
  mkdir -p "$temporary"
  : > "$temporary/candidates.tsv"
  if [ "$native_subagent" = "true" ]; then
    printf '%s\t%s\t%s\n' native-subagent host-subagent "" >> "$temporary/candidates.tsv"
  fi
  for spec in 'codex-cli:codex' 'claude-cli:claude' 'gemini-cli:gemini' 'kimi-cli:kimi'; do
    id="${spec%%:*}"
    command_name="${spec#*:}"
    if command -v "$command_name" >/dev/null 2>&1; then
      printf '%s\t%s\t%s\n' "$id" cli "$command_name" >> "$temporary/candidates.tsv"
    fi
  done
  printf '%s\t%s\t%s\n' direct current-session "" >> "$temporary/candidates.tsv"
  printf '%s\n' select > "$temporary/phase"
  rm -rf "$setup_root"
  mv "$temporary" "$setup_root"
  emit_state
  exit 0
fi

if [ "$action" = "status" ]; then
  emit_state
  exit 0
fi

if [ "$action" = "cancel" ]; then
  rm -rf "$setup_root"
  printf '%s\n' '{"status":"cancelled"}'
  exit 0
fi

if [ ! -s "$phase_file" ]; then
  printf '%s\n' '{"status":"invalid","reason":"executor-setup-not-started"}'
  exit 1
fi
phase="$(sed -n '1p' "$phase_file")"

if [ "$action" = "select" ]; then
  if [ "$phase" != "select" ]; then
    printf '%s\n' '{"status":"invalid","reason":"wrong-executor-phase"}'
    exit 1
  fi
  source_ids="$(awk 'NF { count++; if (out != "") out = out ","; out = out count } END { print out }' "$candidates_file")"
  set +e
  verified="$(sh "$verifier" --source "$source_ids" --selection multiple --user-input "$user_input")"
  verified_status=$?
  set -e
  if [ "$verified_status" -ne 0 ]; then
    printf '%s\n' "$verified"
    exit "$verified_status"
  fi
  normalized="$(printf '%s\n' "$verified" | sed -n 's/.*"normalizedInput":"\([0-9,]*\)".*/\1/p')"
  : > "$selected_file"
  old_ifs=$IFS
  IFS=','
  for number in $normalized; do
    sed -n "${number}p" "$candidates_file" >> "$selected_file"
  done
  IFS=$old_ifs
  if [ "$(count_lines "$selected_file")" -eq 1 ]; then
    cp "$selected_file" "$order_file"
    printf '%s\n' ready > "$phase_file"
  else
    printf '%s\n' prefer > "$phase_file"
  fi
  emit_state
  exit 0
fi

if [ "$action" = "prefer" ]; then
  if [ "$phase" != "prefer" ]; then
    printf '%s\n' '{"status":"invalid","reason":"wrong-executor-phase"}'
    exit 1
  fi
  source_ids="$(awk 'NF { count++; if (out != "") out = out ","; out = out count } END { print out }' "$selected_file")"
  set +e
  verified="$(sh "$verifier" --source "$source_ids" --selection single --user-input "$user_input")"
  verified_status=$?
  set -e
  if [ "$verified_status" -ne 0 ]; then
    printf '%s\n' "$verified"
    exit "$verified_status"
  fi
  preferred="$(printf '%s\n' "$verified" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
  sed -n "${preferred}p" "$selected_file" > "$order_file"
  awk -v preferred="$preferred" 'NR != preferred' "$selected_file" >> "$order_file"
  printf '%s\n' ready > "$phase_file"
  emit_state
  exit 0
fi

if [ "$action" = "commit" ]; then
  if [ "$phase" != "ready" ]; then
    printf '%s\n' '{"status":"invalid","reason":"wrong-executor-phase"}'
    exit 1
  fi
  temporary="$data_root/.executors.json.tmp.$$"
  {
    printf '{\n  "schemaVersion": 1,\n  "configured": true,\n  "executorOrder": '
    json_array_from_file "$order_file"
    printf ',\n  "executors": {'
    separator=""
    while IFS="$(printf '\t')" read -r id kind command_name; do
      printf '%s\n    "%s": {\n      "kind": "%s"' "$separator" "$id" "$kind"
      if [ -n "$command_name" ]; then
        printf ',\n      "command": "%s"' "$command_name"
      fi
      printf '\n    }'
      separator=","
    done < "$selected_file"
    printf '\n  }\n}\n'
  } > "$temporary"
  mv "$temporary" "$config_file"
  rm -rf "$setup_root"
  cat "$config_file"
  exit 0
fi

usage
exit 2
