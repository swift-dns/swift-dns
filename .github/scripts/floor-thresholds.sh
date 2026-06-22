#!/bin/bash

set -Eeuo pipefail
shopt -s nullglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly granularity=1000000 # 1ms

readonly thresholds_path="${1:-Benchmarks/Thresholds}"
[[ -d "${thresholds_path}" ]] || fatal "Thresholds directory not found: ${thresholds_path}"

readonly files=("${thresholds_path}"/*.json)
[[ "${#files[@]}" -gt 0 ]] || fatal "No threshold files found in ${thresholds_path}"

floored=0
for file in "${files[@]}"; do
  jq --argjson granularity "${granularity}" '
    def floorToGranularity: (. / $granularity | floor) * $granularity;
    if (.cpuUser | type) == "number" then
      .cpuUser |= floorToGranularity
    elif (.cpuUser | type) == "object" then
      (if (.cpuUser.min | type) == "number" then .cpuUser.min |= floorToGranularity else . end)
      | (if (.cpuUser.max | type) == "number" then .cpuUser.max |= floorToGranularity else . end)
    else . end
  ' "${file}" > "${file}.tmp"
  mv "${file}.tmp" "${file}"

  if jq -e '
    (.cpuUser | type) as $type
    | $type == "number"
      or ($type == "object" and ([.cpuUser.min, .cpuUser.max] | map(type == "number") | any))
  ' "${file}" >/dev/null; then
    floored=$((floored + 1))
  fi
done

log "✅ Floored cpuUser thresholds to 1ms in ${floored} file(s)."
