#!/bin/bash

set -Eeuo pipefail
shopt -s nullglob
IFS=$'\n\t'

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

readonly granularity=1000000   # 1ms in nanoseconds
readonly p90_index=4           # index of p90 in Statistics.defaultPercentilesToCalculate
readonly percentile_count=7    # number of entries in Statistics.defaultPercentilesToCalculate
readonly sentinel_p90=917000000 # 917ms, used to verify the package still honors the percentile cache

readonly package_path="${PACKAGE_PATH:?PACKAGE_PATH must point at the benchmark SwiftPM package directory}"
readonly baseline_name="${BASELINE_NAME:?BASELINE_NAME must be the stored benchmark baseline name}"

run_benchmark() {
  local exit_code=0
  swift package -c release \
    --package-path "${package_path}" \
    --allow-writing-to-package-directory \
    benchmark "$@" || exit_code=$?
  return "${exit_code}"
}

readonly baselines_dir="${package_path}/.benchmarkBaselines"
[[ -d "${baselines_dir}" ]] || fatal "No baselines directory at '${baselines_dir}'"

readonly baseline_files=("${baselines_dir}"/*/"${baseline_name}"/*results.json)
[[ "${#baseline_files[@]}" -gt 0 ]] \
  || fatal "No baseline results found for '${baseline_name}' under '${baselines_dir}'"

# Sets the cpuUser percentile cache so that 'statistics.percentiles()' returns a known p90 instead of
# recomputing it from the histogram. When 'from_lookup' is true the raw p90 is read from the lookup
# and floored to 1ms; otherwise the provided 'fixed_value' is used verbatim (for the self-test).
inject_cpu_user_p90() {
  local baseline_file="${1:?inject_cpu_user_p90 requires a baseline results file}"
  local from_lookup="${2:?inject_cpu_user_p90 requires from_lookup (true|false)}"
  local fixed_value="${3:?inject_cpu_user_p90 requires a fixed p90 value (use 0 in lookup mode)}"
  local lookup_json="${4:?inject_cpu_user_p90 requires the raw p90 lookup JSON}"

  # shellcheck disable=SC2016
  jq \
    --argjson granularity "${granularity}" \
    --argjson p90_index "${p90_index}" \
    --argjson percentile_count "${percentile_count}" \
    --argjson from_lookup "${from_lookup}" \
    --argjson fixed_value "${fixed_value}" \
    --argjson lookup "${lookup_json}" '
    def cleanup: gsub("[/ ]"; "_");
    reduce ([range(0; (.results | length); 2)] | .[]) as $identifier_index (.;
      (((.results[$identifier_index].target // error("baseline result is missing a target")) | cleanup)
        + "."
        + ((.results[$identifier_index].name // error("baseline result is missing a name")) | cleanup)
      ) as $key
      | .results[$identifier_index + 1] |= map(
          if (.metric | has("cpuUser")) then
            (.statistics.histogram._totalCount) as $histogram_count
            | (if ($histogram_count | type) != "number"
               then error("baseline is missing statistics.histogram._totalCount for \($key)") else . end)
            | (if $from_lookup
               then (($lookup[$key]) | if type != "number"
                       then error("no raw p90 for cpuUser of \($key); the package export may have changed")
                       else (. / $granularity | floor) * $granularity end)
               else $fixed_value end) as $p90
            | .statistics._cachedPercentiles = ([range(0; $percentile_count)] | map(0) | .[$p90_index] = $p90)
            | .statistics._cachedPercentilesHistogramCount = $histogram_count
          else . end))
  ' "${baseline_file}" > "${baseline_file}.tmp"
  mv "${baseline_file}.tmp" "${baseline_file}"
  return 0
}

# Builds a { "<target>.<name>": <rawP90ns> } lookup from a non-range thresholds update, which writes
# '<target>.<name>.p90.json' files holding '{ "<metric>": <p90> }' absolute values in nanoseconds.
build_raw_p90_lookup() {
  local raw_dir="${1:?build_raw_p90_lookup requires an output directory}"

  run_benchmark thresholds update "${baseline_name}" --path "${raw_dir}" --no-progress >/dev/null \
    || fatal "Failed to export raw p90 via 'thresholds update'; the baseline may be unreadable or the package format changed."

  local raw_files=("${raw_dir}"/*.json)
  [[ "${#raw_files[@]}" -gt 0 ]] \
    || fatal "Raw p90 export produced no files; the benchmark package output format may have changed."

  local raw_file key
  for raw_file in "${raw_files[@]}"; do
    key="$(basename "${raw_file}" .p90.json)"
    # shellcheck disable=SC2016
    jq --arg key "${key}" 'if (.cpuUser | type) == "number" then {($key): .cpuUser} else empty end' "${raw_file}"
  done | jq -s 'add // {}'
  return 0
}

# Confirms the injection landed: every cpuUser result must carry a floored numeric p90 whose cache
# count matches the histogram, otherwise our assumptions about the baseline format no longer hold.
verify_injection() {
  local baseline_file="${1:?verify_injection requires a baseline results file}"

  jq -e --argjson p90_index "${p90_index}" --argjson granularity "${granularity}" '
    [.results[] | arrays | .[] | select(.metric | has("cpuUser"))] as $cpu_user_results
    | ($cpu_user_results | length) > 0
      and ($cpu_user_results | all(
        (.statistics._cachedPercentiles[$p90_index] | type) == "number"
        and (.statistics._cachedPercentiles[$p90_index] % $granularity) == 0
        and .statistics._cachedPercentilesHistogramCount == .statistics.histogram._totalCount))
  ' "${baseline_file}" >/dev/null \
    || fatal "Post-injection check failed for '${baseline_file}'; cpuUser p90 was not floored as expected."
  return 0
}

# Verifies the installed package still honors the percentile cache; otherwise flooring the baseline
# would be silently ineffective and sub-ms comparisons would quietly start failing again.
run_self_test() {
  local lookup_json="${1:?run_self_test requires the raw p90 lookup JSON}"
  local baseline_file="${baseline_files[0]}"
  local backup_file="${baseline_file}.selftest.bak"
  local baseline_read_output=""

  cp "${baseline_file}" "${backup_file}"
  inject_cpu_user_p90 "${baseline_file}" false "${sentinel_p90}" "${lookup_json}"
  baseline_read_output="$(run_benchmark baseline read "${baseline_name}" --no-progress --format markdown 2>/dev/null || true)"
  mv "${backup_file}" "${baseline_file}"

  if ! printf '%s\n' "${baseline_read_output}" | grep -q "917"; then
    fatal "Self-test failed: the injected sentinel p90 (917ms) did not surface in 'baseline read'.
The benchmark package no longer honors the percentile cache, so flooring the baseline would be silently ineffective."
  fi
  log "Self-test passed: the benchmark package honors the percentile cache."
  return 0
}

raw_p90_dir="$(mktemp -d)"
readonly raw_p90_dir
trap 'rm -rf "${raw_p90_dir}"' EXIT

raw_p90_lookup="$(build_raw_p90_lookup "${raw_p90_dir}")"
readonly raw_p90_lookup

run_self_test "${raw_p90_lookup}"

floored_count=0
for baseline_file in "${baseline_files[@]}"; do
  jq -e . "${baseline_file}" >/dev/null || fatal "Invalid JSON in baseline file: '${baseline_file}'"
  inject_cpu_user_p90 "${baseline_file}" true 0 "${raw_p90_lookup}"
  verify_injection "${baseline_file}"
  floored_count=$((floored_count + 1))
done

log "✅ Floored measured cpuUser p90 to 1ms in ${floored_count} baseline file(s)."
