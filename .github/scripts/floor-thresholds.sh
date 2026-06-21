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
  # Skip benchmarks with no proper cpuUser.min
  jq -e '.cpuUser.min? | numbers' "${file}" >/dev/null || continue

  jq --argjson granularity "${granularity}" '
    .cpuUser.min = (.cpuUser.min / $granularity | floor) * $granularity
  ' "${file}" > "${file}.tmp"
  mv "${file}.tmp" "${file}"
  floored=$((floored + 1))
done

log "✅ Floored threshold mins to 1ms in ${floored} file(s)."
