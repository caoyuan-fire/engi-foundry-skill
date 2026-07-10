#!/bin/sh

set -eu

source_ids=""
selection=""
user_input=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      [ "$#" -ge 2 ] || break
      source_ids="$2"
      shift 2
      ;;
    --selection)
      [ "$#" -ge 2 ] || break
      selection="$2"
      shift 2
      ;;
    --user-input)
      [ "$#" -ge 2 ] || break
      user_input="$2"
      shift 2
      ;;
    *)
      printf '%s\n' '{"status":"error","reason":"invalid-arguments"}'
      exit 2
      ;;
  esac
done

case "$selection" in
  single|multiple) ;;
  *)
    printf '%s\n' '{"status":"error","reason":"invalid-selection-mode"}'
    exit 2
    ;;
esac

normalize() {
  printf '%s' "$1" | sed \
    -e 's/，/,/g' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//' \
    -e 's/[[:space:]]*,[[:space:]]*/,/g'
}

is_numeric_list() {
  printf '%s\n' "$1" | grep -Eq '^[0-9]+(,[0-9]+)*$'
}

json_array() {
  if [ -z "$1" ]; then
    printf '[]'
  else
    printf '[%s]' "$1"
  fi
}

source_ids="$(normalize "$source_ids")"
if [ -z "$source_ids" ] || ! is_numeric_list "$source_ids"; then
  printf '%s\n' '{"status":"error","reason":"invalid-source"}'
  exit 2
fi

seen=","
expected=1
old_ifs=$IFS
IFS=','
for id in $source_ids; do
  case "$seen" in
    *",$id,"*)
      printf '%s\n' '{"status":"error","reason":"duplicate-source-option"}'
      exit 2
      ;;
  esac
  if [ "$id" -ne "$expected" ]; then
    printf '%s\n' '{"status":"error","reason":"invalid-source-sequence"}'
    exit 2
  fi
  seen="$seen$id,"
  expected=$((expected + 1))
done
IFS=$old_ifs

normalized="$(normalize "$user_input")"
allowed_json="$(json_array "$source_ids")"
if [ -z "$normalized" ]; then
  printf '{"status":"invalid","reason":"empty-input","allowedIds":%s}\n' "$allowed_json"
  exit 1
fi
if ! is_numeric_list "$normalized"; then
  printf '{"status":"invalid","reason":"invalid-format","allowedIds":%s}\n' "$allowed_json"
  exit 1
fi

if [ "$selection" = "single" ]; then
  case "$normalized" in
    *,*)
      printf '{"status":"invalid","reason":"multiple-not-allowed","allowedIds":%s}\n' "$allowed_json"
      exit 1
      ;;
  esac
fi

selected_seen=","
invalid=""
IFS=','
for id in $normalized; do
  case "$selected_seen" in
    *",$id,"*)
      IFS=$old_ifs
      printf '{"status":"invalid","reason":"duplicate-option","allowedIds":%s}\n' "$allowed_json"
      exit 1
      ;;
  esac
  selected_seen="$selected_seen$id,"
  case ",$source_ids," in
    *",$id,"*) ;;
    *)
      if [ -z "$invalid" ]; then invalid="$id"; else invalid="$invalid,$id"; fi
      ;;
  esac
done
IFS=$old_ifs

if [ -n "$invalid" ]; then
  printf '{"status":"invalid","reason":"unknown-option","invalidIds":%s,"allowedIds":%s}\n' \
    "$(json_array "$invalid")" "$allowed_json"
  exit 1
fi

printf '{"status":"valid","selection":"%s","normalizedInput":"%s","selectedIds":%s}\n' \
  "$selection" "$normalized" "$(json_array "$normalized")"
