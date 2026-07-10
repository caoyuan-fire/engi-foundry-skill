#!/bin/sh

set -eu

usage() {
  echo "Usage: executor-probe.sh --executor ID --command COMMAND [--model MODEL]" >&2
}

executor_id=""
command_name=""
model=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --executor)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      executor_id="$2"
      shift 2
      ;;
    --command)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      command_name="$2"
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      model="$2"
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

case "$executor_id" in
  codex-cli|claude-cli|gemini-cli|kimi-cli) ;;
  *) usage; exit 2 ;;
esac
case "$command_name" in
  codex|claude|gemini|kimi) ;;
  *) usage; exit 2 ;;
esac
if ! command -v "$command_name" >/dev/null 2>&1; then
  printf '%s\n' '{"status":"invalid","reason":"executor-command-unavailable"}'
  exit 1
fi
if [ -n "$model" ] && ! printf '%s\n' "$model" | grep -Eq '^[A-Za-z0-9._:/+@-]+$'; then
  printf '%s\n' '{"status":"invalid","reason":"invalid-model-id"}'
  exit 1
fi

probe_root="$(mktemp -d "${TMPDIR:-/tmp}/engifoundry-executor-probe.XXXXXX")"
output_file="$probe_root/output"
cleanup() { rm -rf "$probe_root"; }
trap cleanup EXIT HUP INT TERM
prompt='Reply with exactly: hello'

set +e
case "$executor_id" in
  codex-cli)
    if [ -n "$model" ]; then
      "$command_name" exec --ephemeral --skip-git-repo-check --json --color never -C "$probe_root" --model "$model" "$prompt" </dev/null >"$output_file" 2>&1
    else
      "$command_name" exec --ephemeral --skip-git-repo-check --json --color never -C "$probe_root" "$prompt" </dev/null >"$output_file" 2>&1
    fi
    ;;
  kimi-cli)
    if [ -n "$model" ]; then
      (cd "$probe_root" && "$command_name" --model "$model" --prompt "$prompt" --output-format stream-json </dev/null) >"$output_file" 2>&1
    else
      (cd "$probe_root" && "$command_name" --prompt "$prompt" --output-format stream-json </dev/null) >"$output_file" 2>&1
    fi
    ;;
  claude-cli)
    if [ -n "$model" ]; then
      (cd "$probe_root" && "$command_name" --print --output-format json --model "$model" "$prompt" </dev/null) >"$output_file" 2>&1
    else
      (cd "$probe_root" && "$command_name" --print --output-format json "$prompt" </dev/null) >"$output_file" 2>&1
    fi
    ;;
  gemini-cli)
    if [ -n "$model" ]; then
      (cd "$probe_root" && "$command_name" --prompt "$prompt" --output-format json --model "$model" </dev/null) >"$output_file" 2>&1
    else
      (cd "$probe_root" && "$command_name" --prompt "$prompt" --output-format json </dev/null) >"$output_file" 2>&1
    fi
    ;;
esac
probe_status=$?
set -e

if [ "$probe_status" -ne 0 ]; then
  printf '%s\n' '{"status":"invalid","reason":"executor-probe-failed"}'
  exit 1
fi
if ! grep -Eqi 'hello' "$output_file"; then
  printf '%s\n' '{"status":"invalid","reason":"executor-probe-invalid-response"}'
  exit 1
fi

if [ -n "$model" ]; then mode="pinned"; else mode="cli-default"; fi
printf '{"status":"passed","executorId":"%s","modelMode":"%s"}\n' "$executor_id" "$mode"
