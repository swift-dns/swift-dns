#!/bin/bash

set -Eeuo pipefail
shopt -s nullglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly granularity=1000000 # 1ms in nanoseconds
readonly thresholds_path="${THRESHOLDS_PATH:?THRESHOLDS_PATH must point at the benchmark Thresholds directory}"
[[ -d "${thresholds_path}" ]] || fatal "Thresholds directory not found: '${thresholds_path}'"

readonly threshold_files=("${thresholds_path}"/*.json)
[[ "${#threshold_files[@]}" -gt 0 ]] || fatal "No threshold files found in '${thresholds_path}'"

# Classifies the '.cpuUser' threshold so we floor only what we understand and fail on anything else.
cpu_user_threshold_shape() {
  local threshold_file="${1:?cpu_user_threshold_shape requires a threshold file path}"

  jq -r '
    if (.cpuUser | type) == "null" then "none"
    elif (.cpuUser | type) == "number" then "scalar"
    elif (.cpuUser | type) == "object" then
      if ((.cpuUser.min | type) == "number" and (.cpuUser.max | type) == "number") then "range"
      elif ((.cpuUser.base | type) == "number" and (.cpuUser.tolerancePercentage | type) == "number") then "relative"
      else "unknown" end
    else "unknown" end
  ' "${threshold_file}"
  return 0
}

# Floors '.cpuUser' min and max (or a scalar absolute value) down to the 1ms granularity.
floor_cpu_user_threshold() {
  local threshold_file="${1:?floor_cpu_user_threshold requires a threshold file path}"

  jq --argjson granularity "${granularity}" '
    def floor_to_granularity: (. / $granularity | floor) * $granularity;
    if (.cpuUser | type) == "number" then
      .cpuUser |= floor_to_granularity
    elif (.cpuUser | type) == "object" then
      (if (.cpuUser.min | type) == "number" then .cpuUser.min |= floor_to_granularity else . end)
      | (if (.cpuUser.max | type) == "number" then .cpuUser.max |= floor_to_granularity else . end)
      | (if (.cpuUser.min | type) == "number" and (.cpuUser.max | type) == "number" and .cpuUser.min == .cpuUser.max
         then .cpuUser = .cpuUser.max else . end)
    else . end
  ' "${threshold_file}" > "${threshold_file}.tmp"
  mv "${threshold_file}.tmp" "${threshold_file}"
  return 0
}

floored_count=0
for threshold_file in "${threshold_files[@]}"; do
  jq -e . "${threshold_file}" >/dev/null || fatal "Invalid JSON in threshold file: '${threshold_file}'"

  shape="$(cpu_user_threshold_shape "${threshold_file}")"
  if [[ "${shape}" == "unknown" ]]; then
    fatal "Unrecognized cpuUser threshold shape in '${threshold_file}'; the benchmark package output format may have changed."
  fi

  floor_cpu_user_threshold "${threshold_file}"

  if [[ "${shape}" == "scalar" || "${shape}" == "range" ]]; then
    floored_count=$((floored_count + 1))
  fi
done

log "✅ Floored cpuUser thresholds (min and max) to 1ms in ${floored_count} file(s)."
