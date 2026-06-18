#!/bin/bash

set -euo pipefail

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

# Floor the 'min' (cpuUser) of each benchmark threshold down to a 1ms boundary
# so committed baselines don't carry sub-millisecond noise. The 'max' is left
# untouched.
readonly granularity=1000000 # 1ms in nanoseconds

readonly thresholds_path="${1:-Benchmarks/Thresholds}"
[[ -d "${thresholds_path}" ]] || fatal "Thresholds directory not found: ${thresholds_path}"

shopt -s nullglob
readonly files=("${thresholds_path}"/*.json)
[[ "${#files[@]}" -gt 0 ]] || fatal "No threshold files found in ${thresholds_path}"

for file in "${files[@]}"; do
  jq --argjson granularity "${granularity}" '
    if .cpuUser.min then
      .cpuUser.min = (.cpuUser.min / $granularity | floor) * $granularity
    else . end
  ' "${file}" > "${file}.tmp"
  mv "${file}.tmp" "${file}"
done

log "✅ Floored threshold mins to 1ms in ${#files[@]} file(s)."
