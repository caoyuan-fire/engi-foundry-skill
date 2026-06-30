#!/bin/sh
set -eu

usage() {
  echo "Usage: check_version.sh [--local-version-file PATH] [--remote-version-url URL]" >&2
}

local_version_file=""
remote_version_url="https://raw.githubusercontent.com/caoyuan-fire/engi-foundry-skill/main/skills/engifoundry/VERSION"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --local-version-file) local_version_file="${2:-}"; shift 2 ;;
    --remote-version-url) remote_version_url="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
local_version_file="${local_version_file:-$script_dir/../VERSION}"

if [ ! -f "$local_version_file" ]; then
  exit 0
fi

local_version=$(sed -n '1{s/[[:space:]]//g;p;}' "$local_version_file")
if [ -z "$local_version" ]; then
  exit 0
fi

fetch_remote_version() {
  case "$remote_version_url" in
    file://*)
      path=${remote_version_url#file://}
      [ -f "$path" ] || return 1
      sed -n '1{s/[[:space:]]//g;p;}' "$path"
      ;;
    *)
      command -v curl >/dev/null 2>&1 || return 1
      curl -fsSL --max-time 3 "$remote_version_url" 2>/dev/null | sed -n '1{s/[[:space:]]//g;p;}'
      ;;
  esac
}

remote_version=$(fetch_remote_version || true)
if [ -z "$remote_version" ]; then
  exit 0
fi

version_gt() {
  a=$1
  b=$2
  a_major=${a%%.*}; a_rest=${a#*.}; a_minor=${a_rest%%.*}; a_patch=${a_rest#*.}
  b_major=${b%%.*}; b_rest=${b#*.}; b_minor=${b_rest%%.*}; b_patch=${b_rest#*.}
  a_major=${a_major:-0}; a_minor=${a_minor:-0}; a_patch=${a_patch:-0}
  b_major=${b_major:-0}; b_minor=${b_minor:-0}; b_patch=${b_patch:-0}

  [ "$a_major" -gt "$b_major" ] && return 0
  [ "$a_major" -lt "$b_major" ] && return 1
  [ "$a_minor" -gt "$b_minor" ] && return 0
  [ "$a_minor" -lt "$b_minor" ] && return 1
  [ "$a_patch" -gt "$b_patch" ]
}

if version_gt "$remote_version" "$local_version"; then
  printf 'EngiFoundry update available: local %s, latest %s\n' "$local_version" "$remote_version"
fi

exit 0
