#!/bin/sh

set -eu

usage() {
  echo "Usage: configure.sh status|answer|resolve|cancel --project-root PATH --current-cli ID [--locale LOCALE] [--init-modify] [--user-input TEXT] [resolution fields]" >&2
}

action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
project_root=""
current_cli=""
locale="en"
init_modify=false
user_input=""
resolution_status=""
executor_id=""
resolved_label=""
resolved_command=""
resolved_model=""
resolved_usage=""
resolution_reason=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root) [ "$#" -ge 2 ] || { usage; exit 2; }; project_root="$2"; shift 2 ;;
    --current-cli) [ "$#" -ge 2 ] || { usage; exit 2; }; current_cli="$2"; shift 2 ;;
    --locale) [ "$#" -ge 2 ] || { usage; exit 2; }; locale="$2"; shift 2 ;;
    --init-modify) init_modify=true; shift ;;
    --user-input) [ "$#" -ge 2 ] || { usage; exit 2; }; user_input="$2"; shift 2 ;;
    --resolution-status) [ "$#" -ge 2 ] || { usage; exit 2; }; resolution_status="$2"; shift 2 ;;
    --executor-id) [ "$#" -ge 2 ] || { usage; exit 2; }; executor_id="$2"; shift 2 ;;
    --label) [ "$#" -ge 2 ] || { usage; exit 2; }; resolved_label="$2"; shift 2 ;;
    --command) [ "$#" -ge 2 ] || { usage; exit 2; }; resolved_command="$2"; shift 2 ;;
    --model) [ "$#" -ge 2 ] || { usage; exit 2; }; resolved_model="$2"; shift 2 ;;
    --usage) [ "$#" -ge 2 ] || { usage; exit 2; }; resolved_usage="$2"; shift 2 ;;
    --reason) [ "$#" -ge 2 ] || { usage; exit 2; }; resolution_reason="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

case "$action" in status|answer|resolve|cancel) ;; *) usage; exit 2 ;; esac
[ -n "$project_root" ] && [ -d "$project_root" ] || { printf '%s\n' '{"status":"error","reason":"invalid-project-root"}'; exit 2; }
[ -n "$current_cli" ] || { printf '%s\n' '{"status":"error","reason":"missing-current-cli"}'; exit 2; }

project_root="$(cd "$project_root" && pwd -P)"
data_root="$project_root/.engifoundry"
[ -d "$data_root" ] || { printf '%s\n' '{"status":"error","reason":"missing-engifoundry-scaffold"}'; exit 2; }
state_root="$data_root/cache/configurator"
options_root="$state_root/options"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
verifier="$script_dir/verify.sh"

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's//\\r/g'
}

write_value() {
  key="$1"
  value="$2"
  temporary="$state_root/$key.tmp.$$"
  printf '%s' "$value" > "$temporary"
  mv "$temporary" "$state_root/$key"
}

read_value() {
  key="$1"
  if [ -f "$state_root/$key" ]; then cat "$state_root/$key"; fi
}

increment_revision() {
  revision="$(read_value revision)"
  revision="${revision:-0}"
  write_value revision "$((revision + 1))"
}

initialize_state() {
  mode="$1"
  mkdir -p "$state_root"
  write_value mode "$mode"
  write_value phase "executor-choice"
  write_value revision "1"
  write_value current-cli "$current_cli"
  if [ "$mode" = modify ]; then
    cp "$data_root/executors.json" "$state_root/baseline-executors.json"
    cp "$data_root/workflows.json" "$state_root/baseline-workflows.json"
  fi
}

if [ "$init_modify" = true ]; then
  [ "$action" = status ] || { printf '%s\n' '{"status":"error","reason":"init-modify-requires-status"}'; exit 2; }
  if [ -e "$state_root" ]; then
    find "$state_root" -depth -mindepth 1 -delete
  fi
  mkdir -p "$state_root"
  initialize_state modify
elif [ ! -s "$state_root/phase" ]; then
  initialize_state initialize
fi

mode="$(read_value mode)"
phase="$(read_value phase)"

known_id() {
  case "$1" in
    codex|codex-cli) printf '%s' codex-cli ;;
    claude|claude-cli) printf '%s' claude-cli ;;
    gemini|gemini-cli) printf '%s' gemini-cli ;;
    kimi|kimi-cli) printf '%s' kimi-cli ;;
    cursor|cursor-agent|cursor-cli) printf '%s' cursor-cli ;;
    *) printf '%s' "" ;;
  esac
}

known_command() {
  case "$1" in
    codex-cli) printf '%s' codex ;;
    claude-cli) printf '%s' claude ;;
    gemini-cli) printf '%s' gemini ;;
    kimi-cli) printf '%s' kimi ;;
    cursor-cli) printf '%s' cursor-agent ;;
  esac
}

known_label() {
  case "$1" in
    codex-cli) printf '%s' Codex ;;
    claude-cli) printf '%s' "Claude Code" ;;
    gemini-cli) printf '%s' "Gemini CLI" ;;
    kimi-cli) printf '%s' Kimi ;;
    cursor-cli) printf '%s' Cursor ;;
  esac
}

known_usage() {
  case "$1" in
    codex-cli) printf '%s' 'codex exec --ephemeral --json --color never -C {workspace} {prompt}' ;;
    claude-cli) printf '%s' 'claude --print --output-format json {prompt}' ;;
    gemini-cli) printf '%s' 'gemini --prompt {prompt} --output-format json' ;;
    kimi-cli) printf '%s' 'kimi --prompt {prompt} --output-format stream-json' ;;
    cursor-cli) printf '%s' 'cursor-agent --print {prompt}' ;;
  esac
}

run_version() {
  command_name="$1"
  output_file="$state_root/version-output.$$"
  : > "$output_file"
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$command_name" --version </dev/null >"$output_file" 2>&1
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 5 "$command_name" --version </dev/null >"$output_file" 2>&1
  elif command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' 5 "$command_name" --version </dev/null >"$output_file" 2>&1
  else
    "$command_name" --version </dev/null >"$output_file" 2>&1
  fi
  command_status=$?
  set -e
  if [ "$command_status" -ne 0 ]; then
    unlink "$output_file" 2>/dev/null || true
    return 1
  fi
  version_line="$(sed -n '1p' "$output_file" | tr '\t\r' '  ' | cut -c1-120)"
  unlink "$output_file" 2>/dev/null || true
  [ -n "$version_line" ] || version_line="available"
  printf '%s' "$version_line"
}

clear_options() {
  if [ -e "$options_root" ]; then find "$options_root" -depth -mindepth 1 -delete; fi
  mkdir -p "$options_root"
  write_value option-count "0"
}

add_option() {
  option_id="$1"; option_label="$2"; option_command="$3"; option_version="$4"
  option_source="$5"; option_original="$6"; option_model="$7"; option_usage="$8"
  count="$(read_value option-count)"; count="${count:-0}"; count=$((count + 1))
  write_value option-count "$count"
  for pair in \
    "id:$option_id" "label:$option_label" "command:$option_command" "version:$option_version" \
    "source:$option_source" "original:$option_original" "model:$option_model" "usage:$option_usage"
  do
    field="${pair%%:*}"; value="${pair#*:}"
    temporary="$options_root/$field.$count.tmp.$$"
    printf '%s' "$value" > "$temporary"
    mv "$temporary" "$options_root/$field.$count"
  done
}

discover_options() {
  role="$1"
  clear_options
  current_id="$(known_id "$current_cli")"
  ordered_ids=""
  [ -z "$current_id" ] || ordered_ids="$current_id"
  for id in codex-cli claude-cli gemini-cli kimi-cli cursor-cli; do
    case " $ordered_ids " in *" $id "*) ;; *) ordered_ids="$ordered_ids $id" ;; esac
  done
  for id in $ordered_ids; do
    command_name="$(known_command "$id")"
    if command -v "$command_name" >/dev/null 2>&1; then
      if version="$(run_version "$command_name")"; then
        add_option "$id" "$(known_label "$id")" "$command_name" "$version" known "" "" "$(known_usage "$id")"
      fi
    fi
  done
  if [ "$role" = reviewer ] && [ "$(read_value executor-source)" = custom ]; then
    add_option inherited-custom "$(read_value executor-original)" "$(read_value executor-command)" verified \
      custom "$(read_value executor-original)" "$(read_value executor-model)" "$(read_value executor-usage)"
  fi
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then custom_label="自定义"; else custom_label="Custom"; fi
  add_option custom "$custom_label" "" "" branch "" "" ""
}

options_json() {
  count="$(read_value option-count)"
  separator=""
  printf '['
  number=1
  while [ "$number" -le "$count" ]; do
    id="$(cat "$options_root/id.$number")"; label="$(cat "$options_root/label.$number")"
    command_name="$(cat "$options_root/command.$number")"; version="$(cat "$options_root/version.$number")"
    source="$(cat "$options_root/source.$number")"
    printf '%s{"id":"%s","displayNumber":%s,"label":"%s","behavior":"%s"' \
      "$separator" "$(json_escape "$id")" "$number" "$(json_escape "$label")" \
      "$(if [ "$source" = branch ]; then printf branch; else printf select-known-executor; fi)"
    [ -z "$command_name" ] || printf ',"command":"%s"' "$(json_escape "$command_name")"
    [ -z "$version" ] || printf ',"version":"%s"' "$(json_escape "$version")"
    printf '}'
    separator=,
    number=$((number + 1))
  done
  printf ']'
}

emit_choice() {
  role="$1"
  discover_options "$role"
  revision="$(read_value revision)"
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
    if [ "$role" = executor ]; then prompt="请选择 Executor："; else prompt="请选择 Reviewer："; fi
    if [ "$mode" = modify ]; then context="正在重新配置 EngiFoundry；完成全部问题前，当前配置保持生效。"; else context=""; fi
  else
    if [ "$role" = executor ]; then prompt="Choose the Executor:"; else prompt="Choose the Reviewer:"; fi
    if [ "$mode" = modify ]; then context="The current configuration remains active until every question is complete."; else context=""; fi
  fi
  printf '{"schemaVersion":1,"status":"question","mode":"%s","revision":%s,"question":{"id":"%s.choice","kind":"single-choice","prompt":"%s","context":"%s","options":' \
    "$mode" "$revision" "$role" "$(json_escape "$prompt")" "$(json_escape "$context")"
  options_json
  printf '}}\n'
}

emit_custom() {
  role="$1"
  revision="$(read_value revision)"
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
    prompt="请描述你希望使用的 CLI，以及需要固定的模型或调用偏好。"
    hint1="例如：Codex 的 5.3 Spark 模型"
    hint2="例如：使用默认模型的 Kimi CLI"
    hint3="例如：Claude Code 的 Sonnet 模型"
  else
    prompt="Describe the CLI, pinned model, or invocation preference you want to use."
    hint1="For example: Codex with the 5.3 Spark model"
    hint2="For example: Kimi CLI with its default model"
    hint3="For example: Claude Code with a Sonnet model"
  fi
  printf '{"schemaVersion":1,"status":"question","mode":"%s","revision":%s,"question":{"id":"%s.custom-description","kind":"free-text","prompt":"%s","hints":["%s","%s","%s"],"agentHandling":"relay-user-input-unchanged"}}\n' \
    "$mode" "$revision" "$role" "$(json_escape "$prompt")" "$(json_escape "$hint1")" "$(json_escape "$hint2")" "$(json_escape "$hint3")"
}

emit_agent_action() {
  role="$1"
  original="$(read_value "$role-original")"
  printf '{"schemaVersion":1,"status":"agent-action-required","mode":"%s","action":{"type":"resolve-and-probe-cli","subject":"%s","userDescription":"%s","returnQuestionId":"%s.choice"}}\n' \
    "$mode" "$role" "$(json_escape "$original")" "$role"
}

emit_workflow() {
  workflow_phase="$1"
  revision="$(read_value revision)"
  if [ "$workflow_phase" = automation ]; then
    question_id="workflow.automation"
    if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
      prompt="请选择自动化模式："; labels='每个 Job 和最终验证均需审批|仅最终验证需审批|全自动'
    else
      prompt="Choose the automation mode:"; labels='Approve every Job and final verification|Approve final verification only|Full auto'
    fi
  else
    question_id="workflow.action-preference"
    if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
      prompt="请选择行动偏好："; labels='优先创建 Package|平衡模式|优先直接执行'
    else
      prompt="Choose the action preference:"; labels='Package first|Balanced|Direct first'
    fi
  fi
  old_ifs=$IFS; IFS='|'; set -- $labels; IFS=$old_ifs
  printf '{"schemaVersion":1,"status":"question","mode":"%s","revision":%s,"question":{"id":"%s","kind":"single-choice","prompt":"%s","options":[' \
    "$mode" "$revision" "$question_id" "$(json_escape "$prompt")"
  number=1
  for label in "$@"; do
    [ "$number" -eq 1 ] || printf ','
    printf '{"id":"%s","displayNumber":%s,"label":"%s","behavior":"select-value"}' "$number" "$number" "$(json_escape "$label")"
    number=$((number + 1))
  done
  printf ']}}\n'
}

emit_notice_choice() {
  role="$1"
  message="$2"
  discover_options "$role"
  revision="$(read_value revision)"
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
    if [ "$role" = executor ]; then prompt="请选择 Executor："; else prompt="请选择 Reviewer："; fi
  else
    if [ "$role" = executor ]; then prompt="Choose the Executor:"; else prompt="Choose the Reviewer:"; fi
  fi
  printf '{"schemaVersion":1,"status":"question","mode":"%s","revision":%s,"notice":{"level":"warning","message":"%s"},"question":{"id":"%s.choice","kind":"single-choice","prompt":"%s","context":"","options":' \
    "$mode" "$revision" "$(json_escape "$message")" "$role" "$(json_escape "$prompt")"
  options_json
  printf '}}\n'
}

emit_current() {
  phase="$(read_value phase)"
  case "$phase" in
    executor-choice) emit_choice executor ;;
    executor-custom) emit_custom executor ;;
    executor-resolve) emit_agent_action executor ;;
    reviewer-choice) emit_choice reviewer ;;
    reviewer-custom) emit_custom reviewer ;;
    reviewer-resolve) emit_agent_action reviewer ;;
    automation) emit_workflow automation ;;
    action-preference) emit_workflow action-preference ;;
    complete) printf '{"schemaVersion":1,"status":"complete","mode":"%s"}\n' "$mode" ;;
    cancelled) printf '{"schemaVersion":1,"status":"cancelled","mode":"%s"}\n' "$mode" ;;
    *) printf '%s\n' '{"status":"error","reason":"invalid-configurator-state"}'; exit 2 ;;
  esac
}

save_role_from_option() {
  role="$1"; number="$2"
  id="$(cat "$options_root/id.$number")"
  source="$(cat "$options_root/source.$number")"
  if [ "$id" = inherited-custom ]; then id="$(read_value executor-id)"; fi
  write_value "$role-id" "$id"
  write_value "$role-label" "$(cat "$options_root/label.$number")"
  write_value "$role-command" "$(cat "$options_root/command.$number")"
  write_value "$role-source" "$source"
  write_value "$role-original" "$(cat "$options_root/original.$number")"
  write_value "$role-model" "$(cat "$options_root/model.$number")"
  write_value "$role-usage" "$(cat "$options_root/usage.$number")"
}

validate_choice() {
  count="$(read_value option-count)"
  source_ids=""
  number=1
  while [ "$number" -le "$count" ]; do
    [ -z "$source_ids" ] || source_ids="$source_ids,"
    source_ids="$source_ids$number"
    number=$((number + 1))
  done
  set +e
  result="$(sh "$verifier" --source "$source_ids" --selection single --user-input "$user_input")"
  result_status=$?
  set -e
  if [ "$result_status" -ne 0 ]; then printf '%s\n' "$result"; exit "$result_status"; fi
  printf '%s' "$result" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p'
}

commit_configuration() {
  executor_tmp="$state_root/executors.json.new"
  workflows_tmp="$state_root/workflows.json.new"
  initialization_tmp="$state_root/initialization.json.new"
  {
    printf '{\n  "schemaVersion": 2,\n  "schemaRef": ".engifoundry/contracts/executors.schema.json",\n  "configured": true,\n'
    for role in executor reviewer; do
      printf '  "%s": {\n    "executorId": "%s",\n    "kind": "cli",\n    "label": "%s",\n    "command": "%s",\n    "modelMode": "%s"' \
        "$role" "$(json_escape "$(read_value "$role-id")")" "$(json_escape "$(read_value "$role-label")")" \
        "$(json_escape "$(read_value "$role-command")")" "$(if [ -n "$(read_value "$role-model")" ]; then printf pinned; else printf cli-default; fi)"
      if [ -n "$(read_value "$role-model")" ]; then printf ',\n    "model": "%s"' "$(json_escape "$(read_value "$role-model")")"; fi
      if [ -n "$(read_value "$role-original")" ]; then printf ',\n    "originalDescription": "%s"' "$(json_escape "$(read_value "$role-original")")"; fi
      printf ',\n    "usage": "%s"\n  },\n' "$(json_escape "$(read_value "$role-usage")")"
    done
    printf '  "gate": {\n    "executorUnavailable": {\n      "action": "ask-user",\n      "fallbackTarget": "current-session",\n      "decisionScope": "task"\n    }\n  }\n}\n'
  } > "$executor_tmp"
  automation_mode="$(read_value automation-mode)"; action_preference="$(read_value action-preference)"
  printf '{\n  "schemaVersion": 1,\n  "configured": true,\n  "actionPreference": "%s",\n  "automationMode": "%s"\n}\n' \
    "$action_preference" "$automation_mode" > "$workflows_tmp"
  if [ "$mode" = initialize ]; then
    printf '{\n  "schemaVersion": 1,\n  "status": "complete",\n  "currentStep": null,\n  "completedSteps": ["executor", "reviewer", "automation", "action-preference"]\n}\n' > "$initialization_tmp"
  fi
  mv "$executor_tmp" "$data_root/executors.json"
  mv "$workflows_tmp" "$data_root/workflows.json"
  if [ "$mode" = initialize ]; then mv "$initialization_tmp" "$data_root/initialization.json"; fi
  write_value phase complete
  increment_revision
  printf '{"schemaVersion":1,"status":"complete","mode":"%s"}\n' "$mode"
}

if [ "$action" = status ]; then emit_current; exit 0; fi

if [ "$action" = cancel ]; then
  write_value phase cancelled
  increment_revision
  emit_current
  exit 0
fi

if [ "$action" = answer ]; then
  case "$phase" in
    executor-choice|reviewer-choice)
      role="${phase%%-*}"
      discover_options "$role"
      set +e
      selected="$(validate_choice)"
      selection_status=$?
      set -e
      if [ "$selection_status" -ne 0 ]; then printf '%s\n' "$selected"; exit "$selection_status"; fi
      selected_id="$(cat "$options_root/id.$selected")"
      if [ "$selected_id" = custom ]; then
        write_value phase "$role-custom"
      else
        save_role_from_option "$role" "$selected"
        if [ "$role" = executor ]; then write_value phase reviewer-choice; else write_value phase automation; fi
      fi
      increment_revision
      emit_current
      ;;
    executor-custom|reviewer-custom)
      role="${phase%%-*}"
      trimmed="$(printf '%s' "$user_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [ -z "$trimmed" ]; then printf '%s\n' '{"status":"invalid","reason":"empty-custom-description"}'; exit 1; fi
      if [ "${#user_input}" -gt 500 ] || printf '%s' "$user_input" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        printf '%s\n' '{"status":"invalid","reason":"invalid-custom-description"}'; exit 1
      fi
      write_value "$role-original" "$user_input"
      write_value phase "$role-resolve"
      increment_revision
      emit_current
      ;;
    automation)
      result="$(sh "$verifier" --source 1,2,3 --selection single --user-input "$user_input")" || { status=$?; printf '%s\n' "$result"; exit "$status"; }
      selected="$(printf '%s' "$result" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
      case "$selected" in 1) value=job-approval ;; 2) value=package-approval ;; 3) value=full-auto ;; esac
      write_value automation-mode "$value"; write_value phase action-preference; increment_revision; emit_current
      ;;
    action-preference)
      result="$(sh "$verifier" --source 1,2,3 --selection single --user-input "$user_input")" || { status=$?; printf '%s\n' "$result"; exit "$status"; }
      selected="$(printf '%s' "$result" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
      case "$selected" in 1) value=package-first ;; 2) value=balanced ;; 3) value=direct-first ;; esac
      write_value action-preference "$value"; commit_configuration
      ;;
    *) printf '%s\n' '{"status":"invalid","reason":"answer-not-expected"}'; exit 1 ;;
  esac
  exit 0
fi

if [ "$action" = resolve ]; then
  case "$phase" in executor-resolve|reviewer-resolve) role="${phase%%-*}" ;; *) printf '%s\n' '{"status":"invalid","reason":"resolution-not-expected"}'; exit 1 ;; esac
  case "$resolution_status" in
    unconfirmed)
      write_value phase "$role-choice"
      increment_revision
      if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then message="刚刚输入的自定义 CLI 或模型无法确认可用，请重新选择。"; else message="The custom CLI or model could not be confirmed as available. Choose again."; fi
      emit_notice_choice "$role" "$message"
      ;;
    confirmed)
      if ! printf '%s' "$executor_id" | grep -Eq '^[A-Za-z0-9._:/+@-]+$' || \
         ! printf '%s' "$resolved_command" | grep -Eq '^[A-Za-z0-9._:/+@-]+$' || \
         [ -z "$resolved_label" ] || [ -z "$resolved_usage" ]; then
        printf '%s\n' '{"status":"invalid","reason":"invalid-resolution"}'; exit 1
      fi
      if [ -n "$resolved_model" ] && ! printf '%s' "$resolved_model" | grep -Eq '^[A-Za-z0-9._:/+@-]+$'; then
        printf '%s\n' '{"status":"invalid","reason":"invalid-model-id"}'; exit 1
      fi
      write_value "$role-id" "$executor_id"; write_value "$role-label" "$resolved_label"
      write_value "$role-command" "$resolved_command"; write_value "$role-model" "$resolved_model"
      write_value "$role-usage" "$resolved_usage"; write_value "$role-source" custom
      if [ "$role" = executor ]; then write_value phase reviewer-choice; else write_value phase automation; fi
      increment_revision
      emit_current
      ;;
    *) printf '%s\n' '{"status":"invalid","reason":"missing-resolution-status"}'; exit 1 ;;
  esac
fi
