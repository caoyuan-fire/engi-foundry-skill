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

invalid_message() {
  case "$1" in
    empty-input) zh_message="请输入一个选项编号。"; en_message="Enter one option number." ;;
    invalid-format) zh_message="请输入有效的数字选项。"; en_message="Enter a valid numeric option." ;;
    multiple-not-allowed) zh_message="每次只能选择一个选项。"; en_message="Choose only one option at a time." ;;
    duplicate-option) zh_message="不能重复选择同一个选项。"; en_message="Do not repeat an option." ;;
    unknown-option) zh_message="该选项不存在，请重新选择。"; en_message="That option is not available. Choose again." ;;
    empty-custom-description) zh_message="请描述你希望使用的 CLI 或模型。"; en_message="Describe the CLI or model you want to use." ;;
    invalid-custom-description) zh_message="自定义描述格式无效，请使用普通文本重新描述。"; en_message="The custom description is invalid. Describe it again using plain text." ;;
    *) zh_message="当前输入无效，请重新回答。"; en_message="The current input is invalid. Answer again." ;;
  esac
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then printf '%s' "$zh_message"; else printf '%s' "$en_message"; fi
}

emit_invalid() {
  invalid_reason="$1"
  printf '{"status":"invalid","reason":"%s","message":"%s"}\n' \
    "$(json_escape "$invalid_reason")" "$(json_escape "$(invalid_message "$invalid_reason")")"
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
    if [ "$role" = executor ]; then prompt="请选择参与协作执行的 Agent CLI："; else prompt="请选择参与独立审查的 Agent CLI："; fi
    if [ "$mode" = modify ]; then context="这是 EngiFoundry 配置修改流程；提交最后一个答案前，当前配置保持生效。"; else context=""; fi
  else
    if [ "$role" = executor ]; then prompt="Choose the Agent CLI that will collaborate on execution:"; else prompt="Choose the Agent CLI that will perform independent review:"; fi
    if [ "$mode" = modify ]; then context="This is the EngiFoundry configuration update flow. The current configuration remains active until the final answer is submitted."; else context=""; fi
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
      prompt="请选择任务流程的自动化程度："; labels='逐项审批（每个 Job Review 结果及最终 PAK Verify 结果都需要审批）|仅最终审批（自动推进 Job Review，只在 Deliver 前审批最终 PAK Verify 结果，推荐）|全自动（自动推进 Job Review、PAK Verify 和 Deliver）'
    else
      prompt="Choose how automatically the task workflow should advance:"; labels='Approve each step (approve every Job Review result and the final PAK Verify result)|Final approval only (advance through Job Review automatically and approve the final PAK Verify result before Deliver; recommended)|Full auto (advance through Job Review, PAK Verify, and Deliver automatically)'
    fi
  else
    question_id="workflow.action-preference"
    if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
      prompt="请选择你偏好的任务处理方式："; labels='优先创建 Package（除机械、琐碎修改外，所有行动都创建 Package）|平衡模式（多步骤、跨模块、边界不清、委派或有显著风险时创建 Package，推荐）|优先直接执行（明确且可控时直接执行；无法可靠控制范围、风险或交付质量时仍创建 Package）'
    else
      prompt="Choose your preferred way to handle tasks:"; labels='Package first (create a Package for every action except mechanical, trivial changes)|Balanced (create a Package for multi-step, cross-module, unclear, delegated, or meaningfully risky work; recommended)|Direct first (act directly on clear, controlled work, but still create a Package when scope, risk, or delivery quality cannot be controlled reliably)'
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
    if [ "$role" = executor ]; then prompt="请选择参与协作执行的 Agent CLI："; else prompt="请选择参与独立审查的 Agent CLI："; fi
  else
    if [ "$role" = executor ]; then prompt="Choose the Agent CLI that will collaborate on execution:"; else prompt="Choose the Agent CLI that will perform independent review:"; fi
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
    complete)
      printf '{"schemaVersion":1,"status":"complete","mode":"%s","completion":{"lines":["%s","%s","%s","%s"],"message":"%s"}}\n' \
        "$mode" "$(json_escape "$(read_value completion-line1)")" "$(json_escape "$(read_value completion-line2)")" \
        "$(json_escape "$(read_value completion-line3)")" "$(json_escape "$(read_value completion-line4)")" \
        "$(json_escape "$(read_value completion-message)")" ;;
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
  if [ "$result_status" -ne 0 ]; then
    if [ "$result_status" -eq 1 ]; then
      reason="$(printf '%s' "$result" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')"
      emit_invalid "${reason:-invalid-input}"
    else
      printf '%s\n' "$result"
    fi
    exit "$result_status"
  fi
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
  executor_label="$(read_value executor-label)"; reviewer_label="$(read_value reviewer-label)"
  if [ "$locale" = zh-CN ] || [ "$locale" = zh ]; then
    case "$automation_mode" in
      job-approval) automation_label='逐项审批（每个 Job Review 结果及最终 PAK Verify 结果都需要审批）' ;;
      package-approval) automation_label='仅最终审批（自动推进 Job Review，只在 Deliver 前审批最终 PAK Verify 结果，推荐）' ;;
      full-auto) automation_label='全自动（自动推进 Job Review、PAK Verify 和 Deliver）' ;;
    esac
    case "$action_preference" in
      package-first) action_label='优先创建 Package（除机械、琐碎修改外，所有行动都创建 Package）' ;;
      balanced) action_label='平衡模式（多步骤、跨模块、边界不清、委派或有显著风险时创建 Package，推荐）' ;;
      direct-first) action_label='优先直接执行（明确且可控时直接执行；无法可靠控制范围、风险或交付质量时仍创建 Package）' ;;
    esac
    line1="协作执行 Agent CLI：$executor_label"; line2="独立审查 Agent CLI：$reviewer_label"
    line3="任务流程自动化程度：$automation_label"; line4="任务处理方式：$action_label"
    if [ "$mode" = initialize ]; then completion_message='🎉 EngiFoundry 初始化完成。'; else completion_message='EngiFoundry 配置修改完成。'; fi
  else
    case "$automation_mode" in
      job-approval) automation_label='Approve each step (approve every Job Review result and the final PAK Verify result)' ;;
      package-approval) automation_label='Final approval only (advance through Job Review automatically and approve the final PAK Verify result before Deliver; recommended)' ;;
      full-auto) automation_label='Full auto (advance through Job Review, PAK Verify, and Deliver automatically)' ;;
    esac
    case "$action_preference" in
      package-first) action_label='Package first (create a Package for every action except mechanical, trivial changes)' ;;
      balanced) action_label='Balanced (create a Package for multi-step, cross-module, unclear, delegated, or meaningfully risky work; recommended)' ;;
      direct-first) action_label='Direct first (act directly on clear, controlled work, but still create a Package when scope, risk, or delivery quality cannot be controlled reliably)' ;;
    esac
    line1="Execution Agent CLI: $executor_label"; line2="Independent Review Agent CLI: $reviewer_label"
    line3="Workflow automation: $automation_label"; line4="Task handling: $action_label"
    if [ "$mode" = initialize ]; then completion_message='🎉 EngiFoundry initialization is complete.'; else completion_message='EngiFoundry configuration update is complete.'; fi
  fi
  write_value completion-line1 "$line1"; write_value completion-line2 "$line2"
  write_value completion-line3 "$line3"; write_value completion-line4 "$line4"
  write_value completion-message "$completion_message"
  emit_current
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
      if [ -z "$trimmed" ]; then emit_invalid empty-custom-description; exit 1; fi
      if [ "${#user_input}" -gt 500 ] || printf '%s' "$user_input" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        emit_invalid invalid-custom-description; exit 1
      fi
      write_value "$role-original" "$user_input"
      write_value phase "$role-resolve"
      increment_revision
      emit_current
      ;;
    automation)
      set +e
      result="$(sh "$verifier" --source 1,2,3 --selection single --user-input "$user_input")"; status=$?
      set -e
      if [ "$status" -ne 0 ]; then reason="$(printf '%s' "$result" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')"; emit_invalid "${reason:-invalid-input}"; exit "$status"; fi
      selected="$(printf '%s' "$result" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
      case "$selected" in 1) value=job-approval ;; 2) value=package-approval ;; 3) value=full-auto ;; esac
      write_value automation-mode "$value"; write_value phase action-preference; increment_revision; emit_current
      ;;
    action-preference)
      set +e
      result="$(sh "$verifier" --source 1,2,3 --selection single --user-input "$user_input")"; status=$?
      set -e
      if [ "$status" -ne 0 ]; then reason="$(printf '%s' "$result" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')"; emit_invalid "${reason:-invalid-input}"; exit "$status"; fi
      selected="$(printf '%s' "$result" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
      case "$selected" in 1) value=package-first ;; 2) value=balanced ;; 3) value=direct-first ;; esac
      write_value action-preference "$value"; commit_configuration
      ;;
    *) emit_invalid answer-not-expected; exit 1 ;;
  esac
  exit 0
fi

if [ "$action" = resolve ]; then
  case "$phase" in executor-resolve|reviewer-resolve) role="${phase%%-*}" ;; *) emit_invalid resolution-not-expected; exit 1 ;; esac
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
        emit_invalid invalid-resolution; exit 1
      fi
      if [ -n "$resolved_model" ] && ! printf '%s' "$resolved_model" | grep -Eq '^[A-Za-z0-9._:/+@-]+$'; then
        emit_invalid invalid-model-id; exit 1
      fi
      write_value "$role-id" "$executor_id"; write_value "$role-label" "$resolved_label"
      write_value "$role-command" "$resolved_command"; write_value "$role-model" "$resolved_model"
      write_value "$role-usage" "$resolved_usage"; write_value "$role-source" custom
      if [ "$role" = executor ]; then write_value phase reviewer-choice; else write_value phase automation; fi
      increment_revision
      emit_current
      ;;
    *) emit_invalid missing-resolution-status; exit 1 ;;
  esac
fi
